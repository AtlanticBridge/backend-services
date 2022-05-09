#!/usr/bin/env bash

BASEDIR=$(dirname $0)

# pip3 install --target ${PWD}/${BASEDIR}/dependencies/python -r ${PWD}/${BASEDIR}/requirements.txt
echo pip3 --version

search_dir=${PWD}/${BASEDIR}/dependencies/python
for entry in "$search_dir"/*
do
  echo "$entry"
done

echo 'End build script'
