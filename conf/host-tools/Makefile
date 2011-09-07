
CFLAGS	= -std=gnu99 -g -O0
CC		= gcc
DESTDIR ?= /tmp/tt
BIN		= $(DESTDIR)/bin

tools-src = ${wildcard *.c}
tools = ${patsubst %, ${BIN}/%, ${tools-src:.c=}}

LDFLAGS-cross_linker = -lelf

VPATH = .

all : $(tools)
	make -f Makefile.kconfig DESTDIR=$(DESTDIR)
	
$(BIN):
	mkdir -p $(BIN)

$(BIN)/% : %.c
	$(CC) $(CFLAGS) $< -o $@ ${LDFLAGS-$*}

clean:
	rm -f $(tools)
	make -f Makefile.kconfig DESTDIR=$(DESTDIR) clean

install: all
