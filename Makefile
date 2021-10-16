OS=$(shell uname -s)
PLAT =
SHARED := -fPIC --shared
ifeq ($(OS), Darwin)
PLAT = macosx
SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
endif

LUACLIB = luaclib
LIB_SRC_DIR= 3rd
LUA_DIR = /Users/gowa/Repo/skynetgo/skynet/3rd/lua
LUA_INCS = -I$(LUA_DIR)



libs: lfs lyaml ansi

SRCS=$(LIB_SRC_DIR)/luafilesystem/src/lfs.c
lfs:
	MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)
	export MACOSX_DEPLOYMENT_TARGET
	$(CC) $(SHARED) $(LUA_INCS) -o $(LUACLIB)/lfs.so $(SRCS)
	lua -e 'package.cpath = package.cpath .. ";luaclib/?.so"; require "lfs"; print(lfs.currentdir ())'
lyaml:
	cd $(LIB_SRC_DIR)/lyaml/ && build-aux/luke LYAML_DIR=$(LIB_SRC_DIR)/libyaml LUA_INCDIR=$(LUA_DIR)
	install $(LIB_SRC_DIR)/lyaml/$(PLAT)/yaml.so $(LUACLIB)
	install -d lib/lyaml
	install $(LIB_SRC_DIR)/lyaml/lib/lyaml/* lib/lyaml
ansi:
	install $(LIB_SRC_DIR)/eansi-lua/eansi.lua  lib
clean:
	rm -rf $(LUACLIB)/*
	rm -rf lib/lyaml