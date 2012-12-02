#!/bin/ksh

PARAMS=$*

LATT_HOME=../thirdparty/latt

lua5.1 ${LATT_HOME}/extras/OiLTestRunner.lua ${PARAMS}
