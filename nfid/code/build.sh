#!/usr/bin/env bash

BASEDIR=$(dirname $0)

echo 'Print here'
echo ${PWD}
echo ${BASEDIR}

python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'
type -P python3.8 >/dev/null 2>&1 && echo Python 3.8 is installed

# pip3 install --target ${PWD}/${BASEDIR}/dependencies/python -r ${PWD}/${BASEDIR}/requirements.txt
echo pip3 --version

search_dir=${PWD}/${BASEDIR}/dependencies/python/lib/python3.8/site-packages
for entry in "$search_dir"/*
do
  echo "$entry"
done

echo 'End build script'
