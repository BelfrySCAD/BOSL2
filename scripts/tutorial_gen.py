#!/usr/bin/env python3.7

from __future__ import print_function

import os
import re
import sys
import math
import random
import hashlib
import filecmp
import dbm.gnu
import os.path
import platform
import argparse
import subprocess

from PIL import Image, ImageChops


if platform.system() == "Darwin":
    OPENSCAD = "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
    GIT = "git"
else:
    OPENSCAD = "openscad"
    GIT = "git"



def image_compare(file1, file2):
    img1 = Image.open(file1)
    img2 = Image.open(file2)
    if img1.size != img2.size or img1.getbands() != img2.getbands():
        return False
    diff = ImageChops.difference(img1, img2).histogram()
    sq = (value * (i % 256) ** 2 for i, value in enumerate(diff))
    sum_squares = sum(sq)
    rms = math.sqrt(sum_squares / float(img1.size[0] * img1.size[1]))
    return rms<10

def image_resize(infile, outfile, newsize=(320,240)):
    im = Image.open(infile)
    im.thumbnail(newsize, Image.ANTIALIAS)
    im.save(outfile)

def make_animated_gif(imgfiles, outfile, size):
    imgs = []
    for file in imgfiles:
        img = Image.open(file)
        img.thumbnail(size, Image.ANTIALIAS)
        imgs.append(img)
    imgs[0].save(
        outfile,
        save_all=True,
        append_images=imgs[1:],
        duration=250,
        loop=0
    )

def git_checkout(filename):
    # Pull previous committed image from git, if it exists.
    gitcmd = [GIT, "checkout", filename]
    p = subprocess.Popen(gitcmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, close_fds=True)
    err = p.stdout.read()

def run_openscad_script(libfile, infile, imgfile, imgsize=(320,240), eye=None, show_edges=False, render=False):
    scadcmd = [
        OPENSCAD,
        "-o", imgfile,
        "--imgsize={},{}".format(imgsize[0]*2, imgsize[1]*2),
        "--hardwarnings",
        "--projection=o",
        "--autocenter",
        "--viewall"
    ]
    if eye is not None:
        scadcmd.extend(["--camera", eye+",0,0,0"])
    if show_edges:
        scadcmd.extend(["--view=axes,scales,edges"])
    else:
        scadcmd.extend(["--view=axes,scales"])
    if render:  # Force render
        scadcmd.extend(["--render", ""])
    scadcmd.append(infile)
    with open(infile, "r") as f:
        script = "".join(f.readlines());
    p = subprocess.Popen(scadcmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    (stdoutdata, stderrdata) = p.communicate(None)
    res = p.returncode
    if res != 0 or b"ERROR:" in stderrdata or b"TRACE:" in stderrdata:
        print("\n\n{}".format(stderrdata.decode('utf-8')))
        print("////////////////////////////////////////////////////")
        print("// {}: {} for {}".format(libfile, infile, imgfile))
        print("////////////////////////////////////////////////////")
        print(script)
        print("////////////////////////////////////////////////////")
        print("")
        with open("FAILED.scad", "w") as f:
            print("////////////////////////////////////////////////////", file=f)
            print("// {}: {} for {}".format(libfile, infile, imgfile), file=f)
            print("////////////////////////////////////////////////////", file=f)
            print(script, file=f)
            print("////////////////////////////////////////////////////", file=f)
            print("", file=f)
        sys.exit(-1)
    return imgfile


class ImageProcessing(object):
    def __init__(self):
        self.examples = []
        self.commoncode = []
        self.imgroot = ""
        self.keep_scripts = False
        self.force = False

    def set_keep_scripts(self, x):
        self.keep_scripts = x

    def add_image(self, libfile, imgfile, code, extype):
        self.examples.append((libfile, imgfile, code, extype))

    def set_commoncode(self, code):
        self.commoncode = code

    def process_examples(self, imgroot, force=False):
        self.imgroot = imgroot
        self.force = force
        self.hashes = {}
        with dbm.gnu.open("examples_hashes.gdbm", "c") as db:
            for libfile, imgfile, code, extype in self.examples:
                self.gen_example_image(db, libfile, imgfile, code, extype)
            for key, hash in self.hashes.items():
                db[key] = hash

    def gen_example_image(self, db, libfile, imgfile, code, extype):
        if extype == "NORENDER":
            return

        print("  {}".format(imgfile), end='')
        sys.stdout.flush()

        scriptfile = "tmp_{0}.scad".format(imgfile.replace(".", "_").replace("/","_"))
        targimgfile = self.imgroot + imgfile
        newimgfile = self.imgroot + "_new_" + imgfile

        # Pull previous committed image from git, if it exists.
        git_checkout(targimgfile)

        m = hashlib.sha256()
        m.update(extype.encode("utf8"))
        for line in code:
            m.update(line.encode("utf8"))
        hash = m.digest()
        key = "{0} - {1}".format(libfile, imgfile)
        if key in db and db[key] == hash and not self.force:
            print("")
            return

        stdlibs = ["std.scad", "debug.scad"]
        script = ""
        for lib in stdlibs:
            script += "include <BOSL2/%s>\n" % lib
        for line in self.commoncode:
            script += line+"\n"
        for line in code:
            script += line+"\n"

        with open(scriptfile, "w") as f:
            f.write(script)

        if "Big" in extype:
            imgsize = (640, 480)
        elif "Med" in extype or "distribute" in script or "show_anchors" in script:
            imgsize = (480, 360)
        else:  # Small
            imgsize = (320, 240)

        show_edges = "Edges" in extype
        render = "FR" in extype

        tmpimgs = []
        if "Spin" in extype:
            for ang in range(0,359,10):
                tmpimgfile = "{0}tmp_{2}_{1}.png".format(self.imgroot, ang, imgfile.replace(".", "_"))
                arad = ang * math.pi / 180;
                eye = "{0},{1},{2}".format(
                    500*math.cos(arad),
                    500*math.sin(arad),
                    500 if "Flat" in extype else 500*math.sin(arad)
                )
                run_openscad_script(
                    libfile, scriptfile, tmpimgfile,
                    imgsize=(imgsize[0]*2,imgsize[1]*2),
                    eye=eye,
                    show_edges=show_edges,
                    render=render
                )
                tmpimgs.append(tmpimgfile)
                print(".", end='')
                sys.stdout.flush()
        else:
            tmpimgfile = self.imgroot + "tmp_" + imgfile
            eye = "0,0,500" if "2D" in extype else None
            run_openscad_script(
                libfile, scriptfile, tmpimgfile,
                imgsize=(imgsize[0]*2,imgsize[1]*2),
                eye=eye,
                show_edges=show_edges,
                render=render
            )
            tmpimgs.append(tmpimgfile)

        if not self.keep_scripts:
            os.unlink(scriptfile)

        if len(tmpimgs) == 1:
            image_resize(tmpimgfile, newimgfile, imgsize)
            os.unlink(tmpimgs.pop(0))
        else:
            make_animated_gif(tmpimgs, newimgfile, size=imgsize)
            for tmpimg in tmpimgs:
                os.unlink(tmpimg)

        print("")

        # Time to compare image.
        if not os.path.isfile(targimgfile):
            print("    NEW IMAGE\n")
            os.rename(newimgfile, targimgfile)
        else:
            if targimgfile.endswith(".gif"):
                issame = filecmp.cmp(targimgfile, newimgfile, shallow=False)
            else:
                issame  = image_compare(targimgfile, newimgfile);
            if issame:
                os.unlink(newimgfile)
            else:
                print("    UPDATED IMAGE\n")
                os.unlink(targimgfile)
                os.rename(newimgfile, targimgfile)
        self.hashes[key] = hash


imgprc = ImageProcessing()


def processFile(infile, outfile=None, imgroot=""):
    if imgroot and not imgroot.endswith('/'):
        imgroot += "/"
    fileroot = os.path.splitext(os.path.basename(infile))[0]

    outdata = []
    with open(infile, "r") as f:
        script = []
        extyp = ""
        in_script = False
        imgnum = 0
        for line in f.readlines():
            line = line.rstrip("\n")
            if line.startswith("```openscad"):
                outdata.append("```openscad")
            else:
                outdata.append(line)
            if in_script:
                if line == "```":
                    in_script = False
                    imgfile = "{}_{}.png".format(fileroot, imgnum)
                    imgprc.add_image(fileroot+".md", imgfile, script, extyp)
                    outdata.append("![Figure {}]({})".format(imgnum, imgroot + imgfile))
                    script = []
                else:
                    script.append(line)
            if line.startswith("```openscad"):
                in_script = True
                if "-" in line:
                    extyp = line.split("-")[1]
                else:
                    extyp = ""
                script = []
                imgnum = imgnum + 1

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
    parser.add_argument('-k', '--keep-scripts', action="store_true",
                        help="If given, don't delete the temporary image OpenSCAD scripts.")
    parser.add_argument('-f', '--force', action="store_true",
                        help='If given, force generation of images when the code is unchanged.')
    parser.add_argument('-I', '--imgroot', default="",
                        help='The directory to put generated images in.')
    parser.add_argument('-o', '--outfile',
                        help='Output file, if different from infile.')
    parser.add_argument('infile', help='Input filename.')
    args = parser.parse_args()

    imgprc.set_keep_scripts(args.keep_scripts)
    processFile(
        args.infile,
        outfile=args.outfile,
        imgroot=args.imgroot
    )
    imgprc.process_examples(args.imgroot, force=args.force)

    sys.exit(0)


if __name__ == "__main__":
    main()


# vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
