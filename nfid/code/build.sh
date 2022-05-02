#!/usr/bin/env bash

BASEDIR=$(dirname $0)

echo ${PWD}
echo ${BASEDIR}

pip3 install --target ${PWD}/${BASEDIR}/dependencies/python -r ${PWD}/${BASEDIR}/requirements.txt
