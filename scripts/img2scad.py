#!env python3

import re
import os
import sys
import os.path
import argparse

from PIL import Image, ImageFilter, ImageOps


def img2tex(filename, opts, outf):
    indent = " " * 4
    im = Image.open(filename).convert('L')
    if opts.resize:
        print("Resizing to {}x{}".format(opts.resize[0], opts.resize[1]))
        im = im.resize(opts.resize)
    if opts.invert:
        print("Inverting luminance.")
        im = ImageOps.invert(im)
    if opts.blur:
        print("Blurring, radius={}.".format(opts.blur))
        im = im.filter(ImageFilter.BoxBlur(opts.blur))
    if opts.rotate:
        if opts.rotate in (-90, 270):
            print("Rotating 90 degrees clockwise.".format(opts.rotate))
        elif opts.rotate in (90, -270):
            print("Rotating 90 degrees counter-clockwise.".format(opts.rotate))
        elif opts.rotate in (180, -180):
            print("Rotating 180 degrees.".format(opts.rotate))
        im = im.rotate(opts.rotate, expand=True)
    if opts.mirror_x:
        print("Mirroring left-to-right.")
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if opts.mirror_y:
        print("Mirroring top-to-bottom.")
        im = im.transpose(Image.FLIP_TOP_BOTTOM)
    pix = im.load()
    width, height = im.size
    print("// Image {} ({}x{})".format(filename, width, height), file=outf)

    if opts.range == "dynamic":
        pixmin = 255;
        pixmax = 0;
        for y in range(height):
            for x in range(width):
                pixmin = min(pixmin, pix[x,y])
                pixmax = max(pixmax, pix[x,y])
    else:
        pixmin = 0;
        pixmax = 255;
    print("// Original luminances: min={}, max={}".format(pixmin, pixmax), file=outf)
    print("// Texture heights: min={}, max={}".format(opts.minout, opts.maxout), file=outf)

    print("{} = [".format(opts.varname), file=outf)
    line = indent
    for y in range(height):
        line += "[ "
        for x in range(width):
            u = (pix[x,y] - pixmin) / (pixmax - pixmin)
            val = u * (opts.maxout - opts.minout) + opts.minout
            line += "{:.3f}".format(val).rstrip('0').rstrip('.') + ", "
            if len(line) > 60:
                print(line, file=outf)
                line = indent * 2
        line += " ],"
        if line != indent:
            print(line, file=outf)
            line = indent
    print("];", file=outf)
    print("", file=outf)


def check_nonneg_float(value):
    val = float(value)
    if val < 0:
        raise argparse.ArgumentTypeError("{} is an invalid non-negative float value".format(val))
    return val


def main():
    parser = argparse.ArgumentParser(prog='img2scad')
    parser.add_argument('-o', '--outfile',
            help='Output .scad file.')
    parser.add_argument('-v', '--varname',
            help='Variable to use in .scad file.')
    parser.add_argument('-i', '--invert', action='store_true',
            help='Invert luminance values.')
    parser.add_argument('-r', '--resize',
            help='Resample image to WIDTHxHEIGHT.')
    parser.add_argument('-R', '--rotate', choices=(-270, -180, -90, 0, 90, 180, 270), default=0, type=int,
            help='Rotate output by the given number of degrees.')
    parser.add_argument('--mirror-x', action="store_true",
            help='Mirror output in the X direction.')
    parser.add_argument('--mirror-y', action="store_true",
            help='Mirror output in the Y direction.')
    parser.add_argument('--blur', type=check_nonneg_float, default=0,
            help='Perform a box blur on the output with the given radius.')
    parser.add_argument('--minout', type=float, default=0.0,
            help='The value to output for the minimum luminance.')
    parser.add_argument('--maxout', type=float, default=1.0,
            help='The value to output for the maximum luminance.')
    parser.add_argument('--range', choices=["dynamic", "full"], default="dynamic",
            help='If "dynamic", the lowest to brightest luminances are scaled to the minout/maxout range.\n'
                 'If "full", 0 to 255 luminances will be scaled to the minout/maxout range.')
    parser.add_argument('infile', help='Input image file.')
    opts = parser.parse_args()

    non_alnum = re.compile(r'[^a-zA-Z0-9_]')
    if not opts.varname:
        if opts.outfile:
            opts.varname = os.path.splitext(os.path.basename(opts.outfile))[0]
            opts.varname = non_alnum.sub("", opts.varname)
        else:
            opts.varname = "image_data"
    size_pat = re.compile(r'^([0-9][0-9]*)x([0-9][0-9]*)$')

    opts.invert = bool(opts.invert)
    
    if opts.resize:
        m = size_pat.match(opts.resize)
        if not m:
            print("Expected WIDTHxHEIGHT resize format.", file=sys.stderr)
            sys.exit(-1)
        opts.resize = (int(m.group(1)), int(m.group(2)))

    if not opts.varname or non_alnum.search(opts.varname):
        print("Bad variable name: {}".format(opts.varname), file=sys.stderr)
        sys.exit(-1)

    if opts.outfile:
        with open(opts.outfile, "w") as outf:
            img2tex(opts.infile, opts, outf)
    else:
        img2tex(opts.infile, opts, sys.stdout)

    sys.exit(0)


if __name__ == "__main__":
    main()

