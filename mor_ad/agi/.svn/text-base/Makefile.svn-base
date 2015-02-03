#
# Asterisk -- A telephony toolkit for Linux.
# 
# Makefile for AGI-related stuff
#
# Copyright (C) 1999-2006, Digium
#
# Mark Spencer <markster@digium.com>
#
# This program is free software, distributed under the terms of
# the GNU General Public License
#

INSTALL=install

DESTDIR=/var/lib/asterisk/agi-bin

.PHONY: clean all uninstall

AGIS=mor_ad_agi

ifeq ($(OSARCH),SunOS)
  LIBS+=-lsocket -lnsl -lmysqlclient
endif

#include $(ASTTOPDIR)/Makefile.rules

all: $(AGIS)

mor_ad_agi:mor_ad_agi.o

install: all
#	mkdir -p $(DESTDIR)$(AGI_DIR)
	for x in $(AGIS); do $(INSTALL) -m 755 $$x $(DESTDIR)$(AGI_DIR) ; done

uninstall:
	for x in $(AGIS); do rm -f $(DESTDIR)$(AGI_DIR)/$$x ; done

clean:
	rm -f *.so *.o look mor_ad_agi
	rm -f .*.o.d .*.oo.d

ifneq ($(wildcard .*.d),)
   include .*.d
endif
