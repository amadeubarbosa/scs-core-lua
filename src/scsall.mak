PROJNAME= scsall
LIBNAME= ${PROJNAME}

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CPPFLAGS= +p -KPIC -mt -D_REENTRANT
endif

PRECMP_DIR= ../obj/${TEC_UNAME}
PRECMP_LUA= ${LOOP_HOME}/precompiler.lua
PRECMP_FLAGS= -d ${PRECMP_DIR} -l ./\?.lua

PRELOAD_LUA= ${LOOP_HOME}/preloader.lua
PRELOAD_FLAGS= -d ${PRECMP_DIR} 

${PRECMP_DIR}/scs_core_base.c ${PRECMP_DIR}/scs_core_base.h: scs/core/base.lua 
	${LUABIN} ${PRECMP_LUA} -o scs_core_base ${PRECMP_FLAGS} -n scs.core.base

${PRECMP_DIR}/scs_core_utils.c ${PRECMP_DIR}/scs_core_utils.h: scs/core/utils.lua
	${LUABIN} ${PRECMP_LUA} -o scs_core_utils ${PRECMP_FLAGS} -n scs.core.utils

${PRECMP_DIR}/scs_adaptation_AdaptiveReceptacle.c ${PRECMP_DIR}/scs_adaptation_AdaptiveReceptacle.h: scs/adaptation/AdaptiveReceptacle.lua
	${LUABIN} ${PRECMP_LUA} -o scs_adaptation_AdaptiveReceptacle ${PRECMP_FLAGS} -n scs.adaptation.AdaptiveReceptacle

${PRECMP_DIR}/scs_adaptation_OilUtilities.c ${PRECMP_DIR}/scs_adaptation_OilUtilities.h: scs/adaptation/OilUtilities.lua
	${LUABIN} ${PRECMP_LUA} -o scs_adaptation_OilUtilities ${PRECMP_FLAGS} -n scs.adaptation.OilUtilities

${PRECMP_DIR}/scs_adaptation_PersistentReceptacle.c ${PRECMP_DIR}/scs_adaptation_PersistentReceptacle.h: scs/adaptation/PersistentReceptacle.lua
	${LUABIN} ${PRECMP_LUA} -o scs_adaptation_PersistentReceptacle ${PRECMP_FLAGS} -n scs.adaptation.PersistentReceptacle

${PRECMP_DIR}/scs_util_TableDB.c ${PRECMP_DIR}/scs_util_TableDB.h: scs/util/TableDB.lua
	${LUABIN} ${PRECMP_LUA} -o scs_util_TableDB ${PRECMP_FLAGS} -n scs.util.TableDB

${PRECMP_DIR}/scsall.c ${PRECMP_DIR}/scsall.h: ${PRECMP_DIR}/scs_core_base.h ${PRECMP_DIR}/scs_core_utils.h  ${PRECMP_DIR}/scs_adaptation_AdaptiveReceptacle.h ${PRECMP_DIR}/scs_adaptation_OilUtilities.h ${PRECMP_DIR}/scs_adaptation_PersistentReceptacle.h ${PRECMP_DIR}/scs_util_TableDB.h
	${LUABIN} ${PRELOAD_LUA} -o scsall ${PRELOAD_FLAGS} ${PRECMP_DIR}/scs_core_base.h ${PRECMP_DIR}/scs_core_utils.h ${PRECMP_DIR}/scs_adaptation_AdaptiveReceptacle.h  ${PRECMP_DIR}/scs_adaptation_OilUtilities.h ${PRECMP_DIR}/scs_adaptation_PersistentReceptacle.h ${PRECMP_DIR}/scs_util_TableDB.h

INCLUDES= . ${PRECMP_DIR}
#LDIR= ${OPENBUSLIB}

LIBS= dl

SRC= ${PRECMP_DIR}/scs_core_base.c ${PRECMP_DIR}/scs_core_utils.c ${PRECMP_DIR}/scs_adaptation_AdaptiveReceptacle.c ${PRECMP_DIR}/scs_adaptation_OilUtilities.c ${PRECMP_DIR}/scs_adaptation_PersistentReceptacle.c ${PRECMP_DIR}/scs_util_TableDB.c ${PRECMP_DIR}/scsall.c

USE_LUA51=YES
NO_LUALINK=YES
USE_NODEPEND=YES
