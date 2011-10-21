PROJNAME= luascs
LIBNAME= $(PROJNAME)

include ${LOOP_HOME}/openbus/base.mak

SRC= $(PRELOAD_DIR)/$(LIBNAME).c

LUADIR= .
LUASRC= \
	$(LUADIR)/scs/core/utils.lua \
	$(LUADIR)/scs/util/Log.lua \
	$(LUADIR)/scs/util/OilUtilities.lua \
	$(LUADIR)/scs/util/TableDB.lua \
	$(LUADIR)/scs/core/Component.lua \
	$(LUADIR)/scs/core/Receptacles.lua \
	$(LUADIR)/scs/core/MetaInterface.lua \
	$(LUADIR)/scs/core/ComponentContext.lua \
	$(LUADIR)/scs/core/builder/XMLComponentBuilder.lua \
	$(LUADIR)/scs/auxiliar/componentproperties.lua \
	$(LUADIR)/scs/auxiliar/componenthelp.lua \
	$(LUADIR)/scs/adaptation/AdaptiveReceptacle.lua \
	$(LUADIR)/scs/adaptation/PersistentReceptacle.lua
