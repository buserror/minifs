
CFLAGS	+= --std=gnu99
CFLAGS	+= -ffunction-sections -fdata-sections
LDF	= $(LDFLAGS) -Wl,--relax,--gc-sections


all:	$(STAGING)/bin/waitfor_uevent \
		$(STAGING)/bin/fat_find

$(STAGING)/bin/waitfor_uevent : waitfor_uevent.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDF)

LIBFAT = $(BUILD)/syslinux/libfat/
LIBFAT_SRC = ${wildcard ${LIBFAT}/*.c}

$(STAGING)/bin/fat_find : fat_find.c $(LIBFAT_SRC)
	$(CC) $(CFLAGS) -I$(LIBFAT) -o $@ $^ $(LDF)
	
deploy:
	cp \
		$(STAGING)/bin/waitfor_uevent \
		$(STAGING)/bin/fat_find \
		$(ROOT)/bin/
