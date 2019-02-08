# Replacement for garbage 'waf'

TARGET=termbox
LIBTARGET=lib$(TARGET)

all: $(LIBTARGET).la

LIBTOOL ?= libtool
INSTALL ?= install
DESTDIR ?= /tmp
LIBDIR ?= $(DESTDIR)/usr/lib
INCDIR ?= $(DESTDIR)/usr/include
CFLAGS += -I. -Wall -fPIC

VERSION=1.1.2

SRC = ${wildcard *.c}
OBJ = ${SRC:.c=.lo}

%.lo : %.c
	$(LIBTOOL) --tag=CC --mode=compile $(CC) $(CFLAGS) -c $^ -o $@

$(LIBTARGET).la : ${OBJ}
	@echo $(PACKAGE) VERSION $(VERSION)
	$(LIBTOOL) --tag=CC --mode=link $(CC) -release $(VERSION) -o $@ $^ -rpath $(LIBDIR)

install:
	mkdir -p $(INCDIR) $(LIBDIR)/pkgconfig
	$(INSTALL) -c $(TARGET).h $(INCDIR)/$(TARGET).h
	$(LIBTOOL) --mode=install $(INSTALL) -c $(LIBTARGET).la $(LIBDIR)/
	$(INSTALL) -c *.pc $(LIBDIR)/pkgconfig/$(TARGET).pc

clean:
	rm -rf *.la  *.a *.o *.lo .libs
