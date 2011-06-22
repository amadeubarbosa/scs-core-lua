PROJNAME= scsall
LIBNAME= ${PROJNAME}

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUAPATH = './?.lua;../thirdparty/?.lua;'

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CPPFLAGS= +p -KPIC -mt -D_REENTRANT
endif

PRECMP_DIR= ../obj/${TEC_UNAME}
PRECMP_LUA= ${LOOP_HOME}/precompiler.lua
PRECMP_FLAGS= -n -o scsprecompiled -l ${LUAPATH} -d ${PRECMP_DIR}

PRELOAD_LUA= ${LOOP_HOME}/preloader.lua
PRELOAD_FLAGS= -o scsall -d ${PRECMP_DIR}

SCS_MODULES=$(addprefix scs.,\
	core.utils \
	util.Log \
	util.OilUtilities \
	util.TableDB \
	core.Component \
	core.Receptacles \
	core.MetaInterface \
	core.ComponentContext \
	core.builder.XMLComponentBuilder \
  auxiliar.componentproperties \
  auxiliar.componenthelp \
	adaptation.AdaptiveReceptacle \
	adaptation.PersistentReceptacle)

SCS_LUA= \
  $(addsuffix .lua, \
    $(subst .,/, $(SCS_MODULES)))

${PRECMP_DIR}/scsprecompiled.c: ${SCS_LUA}
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(SCS_MODULES)

${PRECMP_DIR}/scsall.c: ${PRECMP_DIR}/scsprecompiled.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} scsall.h

SRC= ${PRECMP_DIR}/scsprecompiled.c ${PRECMP_DIR}/scsall.c

INCLUDES= . ${PRECMP_DIR}

LIBS= dl

USE_LUA51=YES
NO_LUALINK=YES
USE_NODEPEND=YES
