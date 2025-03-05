# Makefile for Graphic Mask

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

SRCDIR_MK = ../srcdir.mk
SRC_DIR = ../src
-include $(SRCDIR_MK)

AS = has060
ASFLAGS = -w2 -s__CRLF__
LD ?= hlk
LDFLAGS =
CV = cv
U8TOSJ = u8tosj

ifeq ($(findstring hlkx,$(LD)),hlkx)
USE_HLKX = true
endif


PROGS = gm.r gmss.r gsvexe.x
PROGS_X = $(PROGS:.r=.x)
OBJS = $(PROGS_X:.x=.o)
DOCS = README.txt CHANGELOG.txt

GM_ZIP = gm_p.zip


.PHONY: all archive clean
.PRECIOUS: %.o %.x

all: $(PROGS)

%.x: %.s
%.o: %.s gm_internal.mac
	$(AS) $(ASFLAGS) -o$@ $<

%.x: %.o
	$(LD) $(LDFLAGS) -o$@ $^

ifdef USE_HLKX
%.r: %.o
	$(LD) $(LDFLAGS) -r -o$@ $^
else
%.r: %.x
	$(CV) $< $@
endif


archive: $(GM_ZIP)

$(GM_ZIP): $(DOCS) $(PROGS)
	rm -f $@
	zip -9 $@ $^

%.txt: $(SRC_DIR)/../%.md
	rm -f $@
	$(U8TOSJ) < $^ > $@


clean:
	rm -f $(GM_ZIP) $(DOCS) $(PROGS) $(PROGS_X) $(OBJS)

# EOF
