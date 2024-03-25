#!env python3

import re
import os
import sys
import os.path
import argparse

from PIL import Image


def img2tex(filename, varname, invert, resize, outf):
    indent = " " * 4
    im = Image.open(filename).convert('L')
    if resize:
        print("Resizing to {}x{}".format(resize[0],resize[1]))
        im = im.resize(resize)
    pix = im.load()
    width, height = im.size
    print("// Image {} ({}x{})".format(filename, width, height), file=outf)

    
    pixmin = 255;
    pixmax = 0;
    for y in range(height):
        for x in range(width):
            pixmin = min(pixmin, pix[x,y])
            pixmax = max(pixmax, pix[x,y])
    print("// min = {}  max = {}".format(pixmin, pixmax), file=outf)


    print("{} = [".format(varname), file=outf)
    line = indent
    for y in range(height):
        line += "[ "
        for x in range(width):
            if not invert:
                line += "{:.2f}, ".format((pix[x,y]-pixmin)/(pixmax-pixmin))
            else:
                line += "{:.2f}, ".format((pixmax-pix[x,y])/(pixmax-pixmin))
            if len(line) > 60:
                print(line, file=outf)
                line = indent * 2
        line += " ],"
        if line != indent:
            print(line, file=outf)
            line = indent
    print("];", file=outf)
    print("", file=outf)


def main():
    parser = argparse.ArgumentParser(prog='img2tex')
    parser.add_argument('-o', '--outfile',
            help='Output .scad file.')
    parser.add_argument('-v', '--varname',
            help='Variable to use in .scad file.')
    parser.add_argument('-i', '--invert', action='store_true',
            help='Invert greyscale values.')
    parser.add_argument('-r', '--resize',
            help='Resample image to WIDTHxHEIGHT.')
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

    if not opts.invert:
        opts.invert = False
    else:
        opts.invert = True
    
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
            img2tex(opts.infile, opts.varname, opts.invert, opts.resize, outf)
    else:
        img2tex(opts.infile, opts.varname, opts.invert, opts.resize, sys.stdout)

    sys.exit(0)


if __name__ == "__main__":
    main()

