# Replacement for garbage 'waf'

all: libtalloc.la

LIBTOOL ?= libtool
INSTALL ?= install
DESTDIR ?= /tmp
LIBDIR ?= $(DESTDIR)/usr/lib
INCDIR ?= $(DESTDIR)/usr/include
CFLAGS += -I. -Wall -fPIC
#CC = gcc

VERSION=${shell grep '^VERSION' wscript | sed "s/[A-Z =']//g"}

talloc.lo : talloc.c talloc.h replace.h
	$(LIBTOOL) --tag=CC --mode=compile $(CC) $(CFLAGS) -c $< -o $@

libtalloc.la : talloc.lo
	@echo libtalloc VERSION $(VERSION)
	$(LIBTOOL) --tag=CC --mode=link $(CC) -release $(VERSION) -rpath $(LIBDIR) -o $@ $^ 

install:
	mkdir -p $(INCDIR) $(LIBDIR)/pkgconfig
	$(INSTALL) -c talloc.h $(INCDIR)/talloc.h
	$(LIBTOOL) --mode=install $(INSTALL) -c libtalloc.la $(LIBDIR)/libtalloc.la
	$(INSTALL) -c talloc.pc $(LIBDIR)/pkgconfig/talloc.pc
	
clean:
	rm -rf *.la  *.a *.o *.lo .libs
