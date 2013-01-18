#!/bin/ksh

PARAMS=$*

LATT_HOME=../thirdparty/latt

lua ${LATT_HOME}/extras/OiLTestRunner.lua ${PARAMS}
