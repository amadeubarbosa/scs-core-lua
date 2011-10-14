PROJNAME= SCS
LIBNAME= luascs

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  NO_LOCAL_LD=Yes
  AR=CC
  CFLAGS+= -KPIC
  STDLFLAGS= -xar
  CPPFLAGS= +p -KPIC -mt -D_REENTRANT
  ifeq ($(TEC_WORDSIZE), TEC_64)
    FLAGS+= -m64
    LFLAGS+= -m64
    STDLFLAGS+= -m64
  endif
  STDLFLAGS+= -o
endif

USE_LUA51= YES
NO_LUALINK=YES
USE_NODEPEND=YES

PRELOAD_DIR= ../obj/${TEC_UNAME}
INCLUDES= $(PRELOAD_DIR)

SRC= $(PRELOAD_DIR)/scs.c

LUASRC= \
	scs/core/utils.lua \
	scs/util/Log.lua \
	scs/util/OilUtilities.lua \
	scs/util/TableDB.lua \
	scs/core/Component.lua \
	scs/core/Receptacles.lua \
	scs/core/MetaInterface.lua \
	scs/core/ComponentContext.lua \
	scs/core/builder/XMLComponentBuilder.lua \
	scs/auxiliar/componentproperties.lua \
	scs/auxiliar/componenthelp.lua \
	scs/adaptation/AdaptiveReceptacle.lua \
	scs/adaptation/PersistentReceptacle.lua

$(PRELOAD_DIR)/scs.c: ${LOOP_HOME}/lua/preloader.lua $(LUASRC)
	$(LUABIN) $< -l "?.lua" -d $(PRELOAD_DIR) -h scs.h -o scs.c $(LUASRC)

