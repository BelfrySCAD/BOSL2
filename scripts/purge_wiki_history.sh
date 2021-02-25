#!/bin/bash

if [[ ! -d BOSL2.wiki/.git ]] ; then
	echo "Must be run from the BOSL2 directory, with the BOSL2.wiki repo inside."
	exit -1
fi

cd BOSL2.wiki
rm -rf .git
git init
git add .
git commit -m "Purged wiki history."
git remote add origin git@github.com:revarbat/BOSL2.wiki.git
git push -u --force origin master
cd ..

