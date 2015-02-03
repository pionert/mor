#!/bin/bash

# Author:   Ričardas Stoma
# Company:  Kolmisoft
# Year:     2014
# About:    Apply Kolmisoft specific patch to new asterisk version


. /usr/src/mor/test/framework/bash_functions.sh


###########################################
########     GLOBAL VARIABLES      ########
###########################################


PATCH_FILE=/usr/src/mor/sh_scripts/asterisk/asterisk_kolmisoft.patch

ASTERISK_RELEASES=http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-
ASTERISK_VERSION=

KOLMISOFT_ASTERISK_RELEASES=http://www.kolmisoft.com/packets/asterisk-
KOLMISOFT_ASTERISK_VERSION=


download_asterisk() {

    report "Downloading $1$2.tar.gz" 3

    # download Kolmisoft asterisk version
    wget $1$2.tar.gz

    # check if download was successful
    if [ $? -ne 0 ]; then
        report "Failed to download asterisk. Try to download manually and check why it failed: wget $1$2.tar.gz" 1
        exit 1
    fi

    # check if downloaded file exists
    if [ ! -e asterisk-$2.tar.gz ]; then
        report "Asterisk archive file asterisk-2.tar.gz was not found" 1
        exit 1
    fi

}


report "Starting Asterisk patch process" 3

cd /usr/src/mor/sh_scripts/asterisk

# check if we got exactly one argument (which should be asterisk version)
if [ $# -ne 2 ]; then
    report "Script requires two arguments - current version of asterisk that is used in MOR and new asterisk version" 1
    exit 1
fi

# check if versions are different
if [ "$1" == "$2" ]; then
    report "Versions must be different" 1
    exit 0
fi

# delete old files
rm -fr asterisk-* &> /dev/null
rm -fr kolmisoft_asterisk-* &> /dev/null
rm -fr $PATCH_FILE &> /dev/null

ASTERISK_VERSION=$2
download_asterisk $ASTERISK_RELEASES $ASTERISK_VERSION

KOLMISOFT_ASTERISK_VERSION=$1
download_asterisk $KOLMISOFT_ASTERISK_RELEASES $KOLMISOFT_ASTERISK_VERSION
mv asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz kolmisoft_asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz

download_asterisk $ASTERISK_RELEASES $KOLMISOFT_ASTERISK_VERSION

# extract kolmisoft asterisk
report "Extracting kolmisoft_asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz" 3
tar xzf kolmisoft_asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz
rm -fr kolmisoft_asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz &> /dev/null
mv asterisk-$KOLMISOFT_ASTERISK_VERSION kolmisoft_asterisk-$KOLMISOFT_ASTERISK_VERSION

# extract asterisk
report "Extracting asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz" 3
tar xzf asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz
rm -fr asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz &> /dev/null

# extract new asterisk
report "Extracting asterisk-$ASTERISK_VERSION.tar.gz" 3
tar xzf asterisk-$ASTERISK_VERSION.tar.gz
rm -fr asterisk-$ASTERISK_VERSION.tar.gz &> /dev/null

# make patch file
report "Checking difference between original asterisk-$KOLMISOFT_ASTERISK_VERSION and Kolmisoft modified asterisk-$KOLMISOFT_ASTERISK_VERSION versions" 3
diff -wrupN asterisk-$KOLMISOFT_ASTERISK_VERSION kolmisoft_asterisk-$KOLMISOFT_ASTERISK_VERSION > $PATCH_FILE

# modify patch file to have proper paths
sed -i "s|$KOLMISOFT_ASTERISK_VERSION|$ASTERISK_VERSION|g" $PATCH_FILE

# patch asterisk
report "Patching asterisk-$ASTERISK_VERSION" 3
patch --no-backup-if-mismatch -p0 < $PATCH_FILE > asterisk_patch_output.txt

echo "------------------"
cat asterisk_patch_output.txt
echo "------------------"
echo ""

# check if patch rejected any changes
FAILED=`grep "FAILED" asterisk_patch_output.txt | wc -l`

# archive new asterisk version
tar czf kolmisoft_asterisk-$ASTERISK_VERSION.tar.gz asterisk-$ASTERISK_VERSION

if [ $FAILED -ne 0 ]; then
    report "Some changes were rejected. Check patch output if rejected changes do not affect asterisk" 2
else
    # removed files
    rm -fr asterisk-$ASTERISK_VERSION &> /dev/null
    rm -fr asterisk-$KOLMISOFT_ASTERISK_VERSION &> /dev/null
    rm -fr asterisk-$ASTERISK_VERSION.tar.gz &> /dev/null
    rm -fr asterisk-$KOLMISOFT_ASTERISK_VERSION.tar.gz &> /dev/null
    rm -fr kolmisoft_asterisk-$ASTERISK_VERSION &> /dev/null
    rn -fr $PATCH_FILE &> /dev/null
fi

# check if archive exists
if [ ! -e kolmisoft_asterisk-$ASTERISK_VERSION.tar.gz ]; then
    report "Patched asterisk archive was not found" 1
    exit 1
else
    report "Patched asterisk archive is placed in /usr/src/mor/sh_scripts/asterisk/kolmisoft_asterisk-$ASTERISK_VERSION.tar.gz" 0
    report "Asterisk successfully patched" 0
    exit 0
fi
