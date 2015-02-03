#
# Asterisk -- A telephony toolkit for Linux.
# 
# Makefile for PBX frontends (dynamically loaded)
#
# Copyright (C) 1999, Mark Spencer
#
# Mark Spencer <markster@linux-support.net>
#
# $Id: Makefile,v 0.1 2005/05/14 19:49:08 mkezys Exp $
#
# This program is free software, distributed under the terms of
# the GNU General Public License
#

#
# Set ASTERISKINCDIR variable to the directory containing the sources of
# Asterisk PBX.
#
#ASTERISKINCDIR=/usr/include/asterisk
ASTERISKINCDIR=/usr/src/asterisk/include

#
# Set ASTERISKMODDIR variable to the directory where ASTERISK's modules reside.
# The modules will be installed in this directory.
#
ASTERISKMODDIR=/usr/lib/asterisk/modules

#
# Set ASTERISKETCDIR variable to the directory where ASTERISK's configuration
# files reside. The config files will be installed in this directory.
#
ASTERISKETCDIR=/etc/asterisk


#ASTERISKINCLUDE=-I/usr/include/pgsql -I/usr/local/pgsql -I/usr/local/pgsql/include -I$(ASTERISKINCDIR)
ASTERISKINCLUDE=-I$(ASTERISKINCDIR)


# Install MOR app(s)

APPS=app_mor.so
#APPS=app_mor.so app_morcc.so

CC=gcc
INSTALL=install

#Tell gcc to optimize the asterisk's code
OPTIMIZE=-O6

#Include debug symbols in the executables (-g) and profiling info (-pg)
DEBUG=-g #-pg

CFLAGS+=-D_GNU_SOURCE

#
# MySQL stuff...  Autoconf anyone??
#
MODS+=$(shell if [ -d /usr/local/mysql/include ] || [ -d /usr/include/mysql ] || [ -d /usr/local/include/mysql ] || [ -d /opt/
CFLAGS+=$(shell if [ -d /usr/local/mysql/include ]; then echo "-I/usr/local/mysql/include"; fi)
CFLAGS+=$(shell if [ -d /usr/include/mysql ]; then echo "-I/usr/include/mysql"; fi)
CFLAGS+=$(shell if [ -d /usr/local/include/mysql ]; then echo "-I/usr/local/include/mysql"; fi)
CFLAGS+=$(shell if [ -d /opt/mysql/include/mysql ]; then echo "-I/opt/mysql/include/mysql"; fi)
MLFLAGS=
MLFLAGS+=$(shell if [ -d /usr/lib/mysql ]; then echo "-L/usr/lib/mysql"; fi)
MLFLAGS+=$(shell if [ -d /usr/lib64/mysql ]; then echo "-L/usr/lib64/mysql"; fi)
MLFLAGS+=$(shell if [ -d /usr/local/mysql/lib ]; then echo "-L/usr/local/mysql/lib"; fi)
MLFLAGS+=$(shell if [ -d /usr/local/lib/mysql ]; then echo "-L/usr/local/lib/mysql"; fi)
MLFLAGS+=$(shell if [ -d /opt/mysql/lib/mysql ]; then echo "-L/opt/mysql/lib/mysql"; fi)

#INCLUDE=-Iinclude -I../include -I/usr/include/postgresql
#CFLAGS=-pipe  -Wall -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations $(DEBUG) $(INCLUDE) -D_REENTRANT -D_GNU_SOURCE #-DMAKE_VALGRIND_HAPPY
#CFLAGS+=$(OPTIMIZE)
#CFLAGS+=$(shell if $(CC) -march=$(PROC) -S -o /dev/null -xc /dev/null >/dev/null 2>&1; then echo "-march=$(PROC)"; fi)
#CFLAGS+=$(shell if uname -m | grep -q ppc; then echo "-fsigned-char"; fi)
#CFLAGS+=$(shell if [ -f /usr/include/osp/osp.h ]; then echo "-DOSP_SUPPORT -I/usr/include/osp" ; fi)

ifeq (${OSARCH},FreeBSD)
OSVERSION=$(shell make -V OSVERSION -f /usr/share/mk/bsd.port.subdir.mk)
CFLAGS+=$(if ${OSVERSION}<500016,-D_THREAD_SAFE)
LIBS+=$(if ${OSVERSION}<502102,-lc_r,-pthread)
INCLUDE+=-I/usr/local/include
CFLAGS+=$(shell if [ -d /usr/local/include/spandsp ]; then echo "-I/usr/local/include/spandsp"; fi)
endif # FreeBSD

ifeq (${OSARCH},OpenBSD)
CFLAGS+=-pthread
endif

#Uncomment this to use the older DSP routines
#CFLAGS+=-DOLD_DSP_ROUTINES

CFLAGS+=$(shell if [ -f /usr/include/linux/zaptel.h ]; then echo "-DZAPTEL_OPTIMIZATIONS"; fi)
CFLAGS+=$(shell if [ -f /usr/local/include/zaptel.h ]; then echo "-DZAPTEL_OPTIMIZATIONS"; fi)

LIBEDIT=editline/libedit.a

CFLAGS+= $(DEBUG_THREADS)
CFLAGS+= $(TRACE_FRAMES)
CFLAGS+= $(MALLOC_DEBUG)
CFLAGS+= $(BUSYDETECT)
CFLAGS+= $(OPTIONS)

CFLAGS+=-fPIC
#CFLAGS+=-fPIC -lpthread -ldl -lncurses -lm

all: $(APPS)

clean:
	rm -f *.so *.o look .depend

%.so : %.o
	$(CC) $(SOLINK) -o $@ $<

install: all
	mkdir -p $(DESTDIR)$(ASTERISKMODDIR)
	for x in $(APPS); do $(INSTALL) -m 755 $$x $(DESTDIR)$(ASTERISKMODDIR) ; done

app_mor.o: app_mor.c
	$(CC) -pipe $(ASTERISKINCLUDE) $(CFLAGS) -c -o app_mor.o app_mor.c

app_mor.so: app_mor.o
	$(CC) -shared -Xlinker -x -o $@ $< -lmysqlclient -lz $(MLFLAGS)

app_mor_init.o: app_mor_init.c
	$(CC) -pipe $(ASTERISKINCLUDE) $(CFLAGS) -c -o app_mor_init.o app_mor_init.c

app_mor_init.so: app_mor_init.o
	$(CC) -shared -Xlinker -x -o $@ $< -lmysqlclient -lz $(MLFLAGS)

app_morcc.o: app_morcc.c
	$(CC) -pipe $(ASTERISKINCLUDE) $(CFLAGS) -c -o app_morcc.o app_morcc.c

app_morcc.so: app_morcc.o
	$(CC) -shared -Xlinker -x -o $@ $< -lmysqlclient -lz $(MLFLAGS)


ifneq ($(wildcard .depend),)
include .depend
endif

depend: .depend

.depend:
	../mkdep $(CFLAGS) `ls *.c`

env:
	env
