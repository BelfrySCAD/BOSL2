#!/usr/bin/env python3

from __future__ import print_function

import os
import sys
import os.path
import argparse

from openscad_docsgen.imagemanager import ImageManager


imgmgr = ImageManager()


def img_started(req):
    print("  {}... ".format(os.path.basename(req.image_file)), end='')
    sys.stdout.flush()


def img_completed(req):
    if req.success:
        if req.status == "SKIP":
            print()
        else:
            print(req.status)
        sys.stdout.flush()
        return
    out = "\n\n"
    for line in req.echos:
        out += line + "\n"
    for line in req.warnings:
        out += line + "\n"
    for line in req.errors:
        out += line + "\n"
    out += "//////////////////////////////////////////////////////////////////////\n"
    out += "// LibFile: {}  Line: {}  Image: {}\n".format(
        req.src_file, req.src_line, os.path.basename(req.image_file)
    )
    out += "//////////////////////////////////////////////////////////////////////\n"
    for line in req.script_lines:
        out += line + "\n"
    out += "//////////////////////////////////////////////////////////////////////\n"
    print(out, file=sys.stderr)
    sys.exit(-1)


def processFile(infile, outfile=None, imgroot=""):
    if imgroot and not imgroot.endswith('/'):
        imgroot += "/"
    fileroot = os.path.splitext(os.path.basename(infile))[0]

    outdata = []
    with open(infile, "r") as f:
        script = ["include <BOSL2/std.scad>"]
        extyp = ""
        in_script = False
        imgnum = 0
        show_script = True
        linenum = -1
        for line in f.readlines():
            linenum += 1
            line = line.rstrip("\n")
            if line.startswith("```openscad"):
                in_script = True;
                if "-" in line:
                    extyp = line.split("-")[1]
                else:
                    extyp = ""
                show_script = "ImgOnly" not in extyp
                script = ["include <BOSL2/std.scad>"]
                imgnum = imgnum + 1
            elif in_script:
                if line == "```":
                    in_script = False
                    fext = "png"
                    if any(x in extyp for x in ("Anim", "Spin")):
                        fext = "gif"
                    imgfile = os.path.join(imgroot, "{}_{}.{}".format(fileroot, imgnum, fext))
                    imgmgr.new_request(
                        fileroot+".md", linenum,
                        imgfile, script, extyp,
                        starting_cb=img_started,
                        completion_cb=img_completed
                    )
                    if show_script:
                        outdata.append("```openscad")
                        outdata.extend(script)
                        outdata.append("```")
                    outdata.append("![Figure {}]({})".format(imgnum, imgfile))
                    show_script = True
                    extyp = ""
                else:
                    script.append(line)
            else:
                outdata.append(line)

    if outfile == None:
        f = sys.stdout
    else:
        f = open(outfile, "w")

    for line in outdata:
        print(line, file=f)

    if outfile:
        f.close()


def main():
    parser = argparse.ArgumentParser(prog='docs_gen')
    parser.add_argument('-I', '--imgroot', default="",
                        help='The directory to put generated images in.')
    parser.add_argument('-o', '--outfile',
                        help='Output file, if different from infile.')
    parser.add_argument('infile', help='Input filename.')
    args = parser.parse_args()

    processFile(
        args.infile,
        outfile=args.outfile,
        imgroot=args.imgroot
    )
    imgmgr.process_requests()

    sys.exit(0)


if __name__ == "__main__":
    main()


# vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
