#!/bin/bash
set -o errexit
set -o nounset

repo_url="https://github.com/BelfrySCAD/BOSL2.git"
lib_target_dirname="BOSL2"

# determine lib dir
if command -v openscad &> /dev/null 2>&1; then
    libdir="$(openscad --info 2>/dev/null | grep "OpenSCAD library path:" -A1 | tail -n1 | xargs)"
    if [ -z "$libdir" ]; then
        echo "ABORT: Could not determine OpenSCAD library path from 'openscad --info'"
        exit 1
    fi
    echo "OpenSCAD library path determined from 'openscad --info': $libdir"
    if [ ! -d "$libdir" ]; then
        echo "ABORT: Library folder does not exist."
        exit 1
    fi
    if [ ! -x "$libdir" ] || [ ! -w "$libdir" ]; then
        echo "ABORT: Library folder is not accessible (write+execute)."
        exit 1
    fi

else
    echo "Could not find 'openscad' command. Guessing library path based on OS."

    uname_out="$(uname -s)"
    case "${uname_out}" in
        Linux*)     machine="Linux";;
        Darwin*)    machine="Mac";;
        *)          machine="UNKNOWN:${uname_out}"
    esac

    if [ "$machine" == "Mac" ]; then
        libdir="$HOME/Documents/OpenSCAD/libraries"
    elif [ "$machine" == "Linux" ]; then
        libdir="$HOME/.local/share/OpenSCAD/libraries"
    else
        echo "WARNING: running on an unknown system: ${machine}."
        libdir="$HOME/.local/share/OpenSCAD/libraries"
    fi

    if [ ! -d "$libdir" ]; then
        echo "ABORT: Assumed OpenSCAD library folder '$libdir' does not exist"
        exit 1
    fi
fi

if ! command -v git &> /dev/null 2>&1; then
    echo "ABORT: Git is missing. Please install git."
    exit 1
fi

# clone or update
if [ -d "$libdir/$lib_target_dirname" ]; then
    echo "Updating BOSL2 library in $libdir/$lib_target_dirname"
    git -C "$libdir/$lib_target_dirname" pull
else
    echo "New installation into $libdir/$lib_target_dirname"
    git clone "$repo_url" "$libdir/$lib_target_dirname"
fi
