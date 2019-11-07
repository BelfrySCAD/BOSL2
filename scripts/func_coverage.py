#!/usr/bin/env python3

import os

funcs = {}

for filename in os.listdir("."):
    if filename.endswith(".scad"):
        filepath = os.path.join(".",filename)
        with open(filepath, "r") as f:
            for i,line in enumerate(f.readlines()):
                if line.startswith("function "):
                    funcname = line[9:].strip().split("(")[0].strip()
                    if funcname.startswith("_"):
                        continue
                    if funcname in funcs:
                        print("WARNING!!! Function {} re-defined at {}:{}".format(funcname, filename, i));
                        print("           Previously defined at {}".format(funcs[funcname]));
                    else:
                        funcs[funcname] = filename + ":" + str(i)

covered = []
for filename in os.listdir("tests"):
    if filename.startswith("test_") and filename.endswith(".scad"):
        filepath = os.path.join("tests",filename)
        with open(filepath, "r") as f:
            for i,line in enumerate(f.readlines()):
                if line.startswith("module "):
                    funcname = line[7:].strip().split("(")[0].strip().split("_",1)[1]
                    if funcname in funcs:
                        covered.append(funcname)
                        del funcs[funcname]

for funcname in sorted(covered):
    print("COVERED: function {}".format(funcname))

for funcname in sorted(list(funcs.keys())):
    print("NOT COVERED: function {}  ({})".format(funcname, funcs[funcname]))


# vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
