OS=$(shell uname -s)
PLAT =
SHARED := -fPIC --shared
ifeq ($(OS), Darwin)
PLAT = macosx
SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
endif

ROOT?=$(shell pwd)
LUAINC?=

LUACLIB ?= $(ROOT)/luaclib
LUALIB ?= $(ROOT)/lualib
LIB_SRC_DIR= 3rd
LUA_INCS = -I$(LUAINC)

$(warning 可以传递 ROOT 变量，这样会将 core 的 clib lib 都安装在 ROOT 目录下)
ifeq ($(LUAINC),)
$(error 没有设置 LUAINC，变量，需要传输一个绝对路径来指名 LUA 代码位置。如 make LUAINC='/path/to/lua')
endif

libs: lfs lyaml ansi

lfs:
	MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)
	export MACOSX_DEPLOYMENT_TARGET
	$(CC) $(SHARED) $(LUA_INCS) -o $(LUACLIB)/lfs.so $(LIB_SRC_DIR)/luafilesystem/src/lfs.c
lyaml:
	cd $(LIB_SRC_DIR)/lyaml/ && build-aux/luke LYAML_DIR=$(LIB_SRC_DIR)/libyaml LUA_INCDIR=$(LUAINC)
	install $(LIB_SRC_DIR)/lyaml/$(PLAT)/yaml.so $(LUACLIB)
	install -d $(LUALIB)/lyaml
	install $(LIB_SRC_DIR)/lyaml/lib/lyaml/* $(LUALIB)/lyaml
ansi:
	install $(LIB_SRC_DIR)/eansi-lua/eansi.lua $(LUALIB)
	gsed -i 's/sub(3,-2)/sub(2,-2)/' $(LUALIB)/eansi.lua
libs:
	install -d $(LUALIB)/pl
	install $(LIB_SRC_DIR)/Penlight/lua/pl/* $(LUALIB)/pl
clean:
	rm -rf $(LUACLIB)/lfs.so
	rm -rf $(LUACLIB)/yaml.so
	rm -rf $(LUALIB)/lyaml
	rm -rf $(LUALIB)/eansi.lua
