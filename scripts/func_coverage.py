#!/usr/bin/env python3

import os
import operator

funcs = {}
for filename in os.listdir("."):
    if filename.endswith(".scad"):
        filepath = os.path.join(".",filename)
        with open(filepath, "r") as f:
            for linenum,line in enumerate(f.readlines()):
                if line.startswith("function "):
                    funcname = line[9:].strip().split("(")[0].strip()
                    if funcname.startswith("_"):
                        continue
                    if funcname in funcs:
                        print("WARNING!!! Function {} re-defined at {}:{}".format(funcname, filename, linenum+1));
                        print("           Previously defined at {}:{}".format(*funcs[funcname]));
                    else:
                        funcs[funcname] = (filename, linenum+1)

covered = {}
uncovered = funcs.copy()
for filename in os.listdir("tests"):
    if filename.startswith("test_") and filename.endswith(".scad"):
        filepath = os.path.join("tests",filename)
        with open(filepath, "r") as f:
            for linenum,line in enumerate(f.readlines()):
                if line.startswith("module "):
                    testmodule = line[7:].strip().split("(")[0].strip()
                    if testmodule.startswith("test_"):
                        funcname = testmodule.split("_",1)[1]
                        if funcname in uncovered:
                            if filename != "test_" + uncovered[funcname][0]:
                                print("WARNING!!! Function {} defined at {}:{}".format(funcname, *uncovered[funcname]));
                                print("           but tested at {}:{}".format(filename, linenum+1));
                            covered[funcname] = (filename,linenum+1)
                            del uncovered[funcname]

uncovered_by_file = {}
for funcname in sorted(list(uncovered.keys())):
    filename = uncovered[funcname][0]
    if filename not in uncovered_by_file:
        uncovered_by_file[filename] = []
    uncovered_by_file[filename].append(funcname)

mostest = []
for filename in uncovered_by_file.keys():
    mostest.append( (len(uncovered_by_file[filename]), filename) )

# for funcname in sorted(covered):
#     print("COVERED: function {}".format(funcname))

print("NOT COVERED:")
for cnt, filename in sorted(mostest, key=operator.itemgetter(0)):
    filefuncs = uncovered_by_file[filename]
    print("  {}: {:d} uncovered functions".format(filename, cnt))
    for funcname in filefuncs:
        print("    {}".format(funcname))

totfuncs = len(funcs.keys())
covfuncs = len(covered)

print(
    "Total coverage: {} of {} functions ({:.2f}%)".format(
        covfuncs, totfuncs, 100.0*covfuncs/totfuncs
    )
)

# vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
