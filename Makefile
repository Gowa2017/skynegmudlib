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
LUA_DIR = /Users/gowa/Repo/skynetgo/skynet/3rd/lua
LUA_INCS = -I$(LUA_DIR)



libs: lfs lyaml ansi socket

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
socket:
	make -C  $(LIB_SRC_DIR)/luasocket  ${PLAT} LUAINC=$(LUA_DIR) LUAV=5.4
	cd $(LIB_SRC_DIR)/luasocket/src
	cd $(LIB_SRC_DIR)/luasocket/src && install -d $(LUALIB)
	cd $(LIB_SRC_DIR)/luasocket/src && install -m644 ltn12.lua socket.lua mime.lua $(LUALIB)
	cd $(LIB_SRC_DIR)/luasocket/src && install -d $(LUALIB)/socket
	cd $(LIB_SRC_DIR)/luasocket/src && install -m644 http.lua url.lua tp.lua ftp.lua headers.lua smtp.lua $(LUALIB)/socket
	cd $(LIB_SRC_DIR)/luasocket/src && install -d $(LUACLIB)/socket
	cd $(LIB_SRC_DIR)/luasocket/src && install socket-3.0-rc1.so $(LUACLIB)/socket/core.so
	cd $(LIB_SRC_DIR)/luasocket/src && install -d $(LUACLIB)/mime
	cd $(LIB_SRC_DIR)/luasocket/src && install mime-1.0.3.so $(LUACLIB)/mime/core.so
clean:
	rm -rf $(LUACLIB)/*
	rm -rf lib/lyaml
	make -C  $(LIB_SRC_DIR)/luasocket clean