# $Id: Makefile,v 0.1 2005/05/14 21:58:58 mkezys Exp $
# Staging directory
# Files are copied here temporarily during the install process
# For example, make DESTDIR=/tmp/asterisk woud put things in
# /tmp/asterisk/etc/asterisk
DESTDIR=

ASTLIBDIR=$(INSTALL_PREFIX)/usr/lib/asterisk
ASTVARLIBDIR=$(INSTALL_PREFIX)/var/lib/asterisk
ASTETCDIR=$(INSTALL_PREFIX)/etc/asterisk
ASTSPOOLDIR=$(INSTALL_PREFIX)/var/spool/asterisk
ASTLOGDIR=$(INSTALL_PREFIX)/var/log/asterisk
ASTHEADERDIR=$(INSTALL_PREFIX)/usr/include/asterisk
ASTCONFPATH=$(ASTETCDIR)/asterisk.conf
ASTBINDIR=$(INSTALL_PREFIX)/usr/bin
ASTSBINDIR=$(INSTALL_PREFIX)/usr/sbin
ASTVARRUNDIR=$(INSTALL_PREFIX)/var/run

MODULES_DIR=$(ASTLIBDIR)/modules
AGI_DIR=$(ASTVARLIBDIR)/agi-bin


all:
	make -C agi

install:
	make -C agi install

clean:
	make -C agi clean
