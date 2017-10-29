# Replaces the pile of shit that is autotools with this. It works

SRC = ${wildcard *.c}

SRC := ${filter-out audio_sndio.c, ${SRC}}
SRC := ${filter-out audio_pulse.c, ${SRC}}
SRC := ${filter-out audio_ao.c, ${SRC}}
SRC := ${filter-out mdns_dns_sd.c, ${SRC}}

DEPS = libdaemon alsa openssl avahi-client dbus-1 libconfig popt
ECPPFLAGS += ${shell pkg-config --cflags $(DEPS)}
ECPPFLAGS += -Wno-multichar
ELDFLAGS += ${shell pkg-config --libs $(DEPS)} \
	-lrt -lm -lpthread -lintl -liconv

all: shairport

config.h:
	(echo '#define CONFIG_ALSA 1' ;\
	echo '#define CONFIG_AVAHI 1' ;\
	echo '#define CONFIG_METADATA 1' ;\
	echo '#define HAVE_LIBSSL 1' ;\
	echo '#define SYSCONFDIR "/etc"' ;\
	echo '#define PACKAGE_VERSION "minifs"' ;\
	)>$@

shairport: config.h ${SRC} *.h
	$(CC) $(CPPFLAGS) $(ECPPFLAGS) $(CFLAGS) $(ECFLAGS) \
			${filter %.c,$(^)} -o $@ \
			$(LDFLAGS) $(ELDFLAGS) \
		|| rm -f $@

clean:
	rm -f shairport config.h

install:
	mkdir -p $(DESTDIR)/bin
	cp shairport $(DESTDIR)/bin/
