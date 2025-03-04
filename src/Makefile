# $Id: Makefile,v 1.1 1994/09/13 21:57:34 JACK Exp $

CC	= gcc
CFLAGS	= -Wall			\
	  -O			\
	  -fomit-frame-pointer	\
	  -fstrength-reduce	\
	  -fall-bsr		\
	  -fcombine-regs	\
	  -fforce-mem		\
#	  -fforce-addr		\

AS	= as
ASFLAGS	= -u -w

LD	= gcc
LDFLAGS	=

#-----------------------------------------------#

PROGS	= gm.x gmss.x gsvexe.x

ALLTARGET	= $(PROGS)

#-----------------------------------------------#

all: $(PROGS)

%.x: %.o
	$(LD) $(LDFLAGS) $(LDLIBS) -o $@ $^

clean:
	rm -f *.o *.x *.bak *~ .*~ \#* $(ALLTARGET)

#-----------------------------------------------#

gm.o : gm.s gm_internal.mac
gmss.o : gmss.s gm_internal.mac
gsvexe.o : gsvexe.s gm_internal.mac

