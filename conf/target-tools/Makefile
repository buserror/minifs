
EXTRA_CFLAGS	+= --std=gnu99 -Wall
EXTRA_CFLAGS	+= -ffunction-sections -fdata-sections
LDF	= $(LDFLAGS) -Wl,--relax,--gc-sections

STAGING ?= /tmp/minifs

TOOLS ?= all
TOOLS_SRC = ${wildcard *.c}
ifeq ($(TOOLS),all)
TOOLS_DST := ${patsubst %.c, %, ${TOOLS_SRC}}
else
TOOLS_DST := $(TOOLS)
endif
TOOLS_BIN := ${patsubst %, $(STAGING)/bin/%, ${TOOLS_DST}}

all:	$(STAGING)/bin $(TOOLS_BIN)

waitfor_uevent: $(STAGING)/bin/waitfor_uevent
i2ctalk: $(STAGING)/bin/i2ctalk
kmem: $(STAGING)/bin/kmem
fbtest: $(STAGING)/bin/fbtest
spitalk: $(STAGING)/bin/spitalk
fat_find: $(STAGING)/bin/fat_find
uboot_env: $(STAGING)/bin/uboot_env

$(STAGING)/bin:
	mkdir -p $@

$(STAGING)/bin/% : %.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) $(MY_CFLAGS) -o $@ $^ $(LDF)

LIBFAT = $(BUILD)/syslinux/libfat/
LIBFAT_SRC = ${wildcard ${LIBFAT}/*.c}

$(STAGING)/bin/fat_find : EXTRA_CFLAGS += -I$(LIBFAT)
$(STAGING)/bin/fat_find : $(LIBFAT_SRC)

$(STAGING)/bin/i2ctalk : LDF += -lm

# if a uboot exists, we can compile the environment tool for it
ifneq ($(TARGET_BOARD),)
UBOOT	= $(wildcard ../../build-$(TARGET_BOARD)/uboot/)
ifneq ($(UBOOT),)
include $(UBOOT)/include/autoconf.mk
MY_CFLAGS += -DCONFIG_ENV_SIZE=$(CONFIG_ENV_SIZE)
MY_CFLAGS += -DCONFIG_TARGET_BOARD=$(TARGET_BOARD)
MY_CFLAGS += -DCONFIG_H="\"uboot_env_$(TARGET_BOARD).h\""

uboot_env_$(TARGET_BOARD).h: ${UBOOT}/u-boot
	./uboot_env_extract.sh $^ >$@

$(STAGING)/bin/uboot_env : lib/crc32.c
$(STAGING)/bin/uboot_env : uboot_env_$(TARGET_BOARD).h

endif
endif

$(STAGING)/bin/uboot_env : MY_CFLAGS += -std=gnu99

clean:
	rm -f $(TOOLS_BIN)

deploy:
	cp $(TOOLS_BIN) $(ROOT)/bin/
