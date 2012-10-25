
EXTRA_CFLAGS	+= --std=gnu99 -Wall
EXTRA_CFLAGS	+= -ffunction-sections -fdata-sections
LDF	= $(LDFLAGS) -Wl,--relax,--gc-sections

STAGING = /tmp/minifs

TOOLS_SRC = ${wildcard *.c}
TOOLS = ${patsubst %.c, %, ${TOOLS_SRC}}

TOOLS_BIN = ${patsubst %, $(STAGING)/bin/%, ${TOOLS}}

all:	$(STAGING)/bin $(TOOLS_BIN)

waitfor_uevent: $(STAGING)/bin/waitfor_uevent
	

$(STAGING)/bin:
	mkdir -p $@

$(STAGING)/bin/% : %.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $^ $(LDF)

LIBFAT = $(BUILD)/syslinux/libfat/
LIBFAT_SRC = ${wildcard ${LIBFAT}/*.c}

$(STAGING)/bin/fat_find : EXTRA_CFLAGS += -I$(LIBFAT)
$(STAGING)/bin/fat_find : $(LIBFAT_SRC)

$(STAGING)/bin/i2ctalk : LDF += -lm

clean:
	rm -f $(TOOLS_BIN)

deploy:
	cp $(TOOLS_BIN) $(ROOT)/bin/
