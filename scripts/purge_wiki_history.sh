#!/bin/bash

if [[ ! -d BOSL2.wiki/.git ]] ; then
	echo "Must be run from above the BOSL2.wiki repo." >&2
	exit 1
fi

set -e # short-circuit if any command fails
cd BOSL2.wiki
rm -rf .git
git init
git add .
git commit -m "Purged wiki history."
git config pull.rebase false
git remote add origin git@github.com:BelfrySCAD/BOSL2.wiki.git
git push -u --force origin master
