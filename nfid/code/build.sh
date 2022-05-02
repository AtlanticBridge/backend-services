#!/usr/bin/env bash

BASEDIR=$(dirname $0)

echo ${PWD}
echo ${BASEDIR}

pip3 install --target ${PWD}/${BASEDIR}/dependencies/python -r ${PWD}/${BASEDIR}/requirements.txt

search_dir=${PWD}/${BASEDIR}/dependencies/python
for entry in "$search_dir"/*
do
  echo "$entry"
done
