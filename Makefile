prefix=/usr/local
exec_prefix=$(prefix)
libdir=$(exec_prefix)/lib

CC=gcc
CFLAGS=-pthread -g3 -O3 -D_FORTIFY_SOURCE=2 -fPIC
CPPFLAGS=
DEFS=
INSTALL=/usr/bin/install -c
LDFLAGS=-shared -pthread -Wl,--warn-common
LIBS=
MKDIR_P=/bin/mkdir -p
SHELL=/bin/sh

ASTMODDIR=$(libdir)/asterisk/modules
MODULES=codec_opus_open_source format_ogg_opus_open_source format_vp8 res_format_attr_opus

.SUFFIXES: .c .so

.PHONY: all clean install uninstall $(MODULES)

all: $(MODULES)

clean:
	rm */*.so

install: $(MODULES)
	$(MKDIR_P) $(ASTMODDIR)
	$(INSTALL) */*.so $(ASTMODDIR)

uninstall:
	cd $(ASTMODDIR) && rm $(addsuffix .so,$(MODULES))

codec_opus_open_source: LIBS+=-lopus
codec_opus_open_source: DEFS+=-DAST_MODULE=\"codec_opus_open_source\" \
	-DAST_MODULE_SELF_SYM=__internal_codec_opus_open_source_self
codec_opus_open_source: codecs/codec_opus_open_source.so

format_ogg_opus_open_source: CPATH+=-I/usr/include/opus
format_ogg_opus_open_source: LIBS+=-lopus -lopusfile
format_ogg_opus_open_source: DEFS+=-DAST_MODULE=\"format_ogg_opus_open_source\" \
	-DAST_MODULE_SELF_SYM=__internal_format_ogg_opus_open_source_self
format_ogg_opus_open_source: formats/format_ogg_opus_open_source.so

format_vp8: DEFS+=-DAST_MODULE=\"format_vp8\" -DAST_MODULE_SELF_SYM=__internal_format_vp8_self
format_vp8: formats/format_vp8.so

res_format_attr_opus: DEFS+=-DAST_MODULE=\"res_format_attr_opus\" \
	-DAST_MODULE_SELF_SYM=__internal_res_format_attr_opus_self
res_format_attr_opus: res/res_format_attr_opus.so

.c.so:
	$(CC) -o $@ $(CPATH) $(DEFS) $(CPPFLAGS) $(CFLAGS) $(LIBS) $(LDFLAGS) $<
