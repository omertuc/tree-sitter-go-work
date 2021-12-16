VERSION := 0.1.0

# install directory layout
PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib
PCLIBDIR ?= $(LIBDIR)/pkgconfig

# collect C++ sources, and link if necessary
CPPSRC := $(wildcard src/*.cc)

ifeq (, $(CPPSRC))
	ADDITIONALLIBS := 
else
	ADDITIONALLIBS := -lc++
endif

# collect sources
SRC := $(wildcard src/*.c)
SRC += $(CPPSRC)
OBJ := $(addsuffix .o,$(basename $(SRC)))

# ABI versioning
SONAME_MAJOR := 0
SONAME_MINOR := 0

CFLAGS ?= -O3 -Wall -Wextra -Werror
CXXFLAGS ?= -O3 -Wall -Wextra -Werror
override CFLAGS += -std=gnu99 -fPIC
override CXXFLAGS += -fPIC

# OS-specific bits
ifeq ($(shell uname),Darwin)
	SOEXT = dylib
	SOEXTVER_MAJOR = $(SONAME_MAJOR).dylib
	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).dylib
	LINKSHARED += -dynamiclib -Wl,$(ADDITIONALLIBS),-install_name,$(LIBDIR)/libtree-sitter-gowork.$(SONAME_MAJOR).dylib
else
	SOEXT = so
	SOEXTVER_MAJOR = so.$(SONAME_MAJOR)
	SOEXTVER = so.$(SONAME_MAJOR).$(SONAME_MINOR)
	LINKSHARED += -shared -Wl,$(ADDITIONALLIBS),-soname,libtree-sitter-gowork.so.$(SONAME_MAJOR)
endif
ifneq (,$(filter $(shell uname),FreeBSD NetBSD DragonFly))
	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
endif
				
all: libtree-sitter-gowork.a libtree-sitter-gowork.$(SOEXTVER)

libtree-sitter-gowork.a: $(OBJ)
	$(AR) rcs $@ $^

libtree-sitter-gowork.$(SOEXTVER): $(OBJ)
	$(CC) $(LDFLAGS) $(LINKSHARED) $^ $(LDLIBS) -o $@
	ln -sf $@ libtree-sitter-gowork.$(SOEXT)
	ln -sf $@ libtree-sitter-gowork.$(SOEXTVER_MAJOR)

install: all
	install -d '$(DESTDIR)$(LIBDIR)'
	install -m755 libtree-sitter-gowork.a '$(DESTDIR)$(LIBDIR)'/libtree-sitter-gowork.a
	install -m755 libtree-sitter-gowork.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-gowork.$(SOEXTVER)
	ln -sf libtree-sitter-gowork.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-gowork.$(SOEXTVER_MAJOR)
	ln -sf libtree-sitter-gowork.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-gowork.$(SOEXT)
	install -d '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter
	install -m644 bindings/c/gowork.h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/
	install -d '$(DESTDIR)$(PCLIBDIR)'
	sed -e 's|@LIBDIR@|$(LIBDIR)|;s|@INCLUDEDIR@|$(INCLUDEDIR)|;s|@VERSION@|$(VERSION)|' \
	    -e 's|=$(PREFIX)|=$${prefix}|' \
	    -e 's|@PREFIX@|$(PREFIX)|' \
	    -e 's|@ADDITIONALLIBS@|$(ADDITIONALLIBS)|' \
	    bindings/c/tree-sitter-gowork.pc.in > '$(DESTDIR)$(PCLIBDIR)'/tree-sitter-gowork.pc

clean:
	rm -f $(OBJ) libtree-sitter-gowork.a libtree-sitter-gowork.$(SOEXT) libtree-sitter-gowork.$(SOEXTVER_MAJOR) libtree-sitter-gowork.$(SOEXTVER)

.PHONY: all install clean
