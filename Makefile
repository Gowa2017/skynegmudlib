OS=$(shell uname -s)
PLAT =
SHARED := -fPIC --shared
ifeq ($(OS), Darwin)
PLAT = macosx
SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
endif

ROOT=$(shell pwd)
LUACLIB = $(ROOT)/luaclib
LUALIB = $(ROOT)/lib
LIB_SRC_DIR= 3rd
LUAINC ?= 
LUA_INCS = -I$(LUAINC)



libs: lfs lyaml ansi

SRCS=
lfs:
	MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)
	export MACOSX_DEPLOYMENT_TARGET
	$(CC) $(SHARED) $(LUA_INCS) -o $(LUACLIB)/lfs.so $(LIB_SRC_DIR)/luafilesystem/src/lfs.c
	lua -e 'package.cpath = package.cpath .. ";luaclib/?.so"; require "lfs"; print(lfs.currentdir ())'
lyaml:
	cd $(LIB_SRC_DIR)/lyaml/ && build-aux/luke LYAML_DIR=$(LIB_SRC_DIR)/libyaml LUA_INCDIR=$(LUAINC)
	install $(LIB_SRC_DIR)/lyaml/$(PLAT)/yaml.so $(LUACLIB)
	install -d lib/lyaml
	install $(LIB_SRC_DIR)/lyaml/lib/lyaml/* lib/lyaml
ansi:
	install $(LIB_SRC_DIR)/eansi-lua/eansi.lua $(LUALIB) 
clean:
	rm -rf $(LUACLIB)/*
	rm -rf $(LUALIB)/lyaml
