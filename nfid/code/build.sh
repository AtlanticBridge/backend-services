#!/usr/bin/env bash

BASEDIR=$(dirname $0)

echo ${PWD}
echo ${BASEDIR}

pip3 install --target ${BASEDIR}/dependencies/python -r ${BASEDIR}/requirements.txt
