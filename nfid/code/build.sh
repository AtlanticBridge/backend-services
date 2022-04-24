#!/usr/bin/env bash

BASEDIR=$(dirname $0)

pip3 install --target ${PWD}/${BASEDIR}/dependencies/python -r ${PWD}/${BASEDIR}/requirements.txt
