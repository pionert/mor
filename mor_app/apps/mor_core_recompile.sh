#! /bin/sh

# Author:   Ričardas Stoma
# Company:  Kolmisoft
# Year:     2013
# About:    Recompile app_mor module without stopping calls


. /usr/src/mor/x5/framework/bash_functions.sh


###########################################
########     GLOBAL VARIABLES      ########
###########################################


# how frequent we should check for active calls
CHECK_INTERVAL=5
# asterisk module directory
ASTERISKMODDIR=/usr/lib/asterisk/modules
# current version of mor core defined in source files (will be updated later)
CURRENT_CORE=
# installed core version (will be updated later)
INSTALLED_CORE=
# save start time to this variable
START_TIME=`date +"%F %T"`
START_TIME_SECONDS=`date +"%s"`
# current time (will be updated late)
CURRENT_TIME_SECONDS=
# time difference
TIME_DIFF=
# show debug messages
DEBUG=0
# where to display debug output? default - do not display
DEBUG_OUTPUT=/dev/null
# skip file modification error (usefull when recompiling very old core files)
FORCE=0
# force no screen
NO_SCREEN=0
# do not udpate database
NO_DB=0
# core branch
CORE_BRANCH=trunk
# path to source files
SOURCE_FILES_PATH=/usr/src/mor/mor_app/apps/source
# are we installing core?
INSTALL=0
# MOR GUI version
MOR_VERSION=


###########################################
########         FUNCTIONS         ########
###########################################


#   Function to replace a line in a file (only used to replace unique parts)

replace_line() {

    if [ ! -f $1 ]; then
        report "$1 file not found" 1
        my_exit 1
    fi

    local LINE_NUMBER=`cat $1 | grep -n "$2" | cut -d: -f1`

    if ! echo $LINE_NUMBER | grep -Eq '^[0-9]+$'; then
        report "Line number is not an integer" 1
        report "$2 cannot be found in $1" 1
        if [ $FORCE -ne 1 ]; then
            my_exit 1
        fi
    else
        if [ $LINE_NUMBER -gt 0 ]; then
            sed -i "${LINE_NUMBER}s|.*|$3|" $1
        fi
    fi

}

#   Function to replace a string in a file

replace_string() {

    if [ ! -f $1 ]; then
        report "$1 file not found" 1
        if [ $FORCE -ne 1 ]; then
            my_exit 1
        fi
    fi

    sed -i "s|$2|$3|g" $1

}

#   Function to remove source files on error or normal exit

my_exit() {

    report "Cleaning source files" 3

    # remove src_tmp directory
    if [ -d $SOURCE_FILES_PATH/src_tmp ]; then
        if ! rm -fr $SOURCE_FILES_PATH/src_tmp; then
            report "Cannot remove $SOURCE_FILES_PATH/src_tmp"
            exit 1
        fi
    fi

    # remove src directory
    if [ -d $SOURCE_FILES_PATH/src ]; then
        if ! rm -fr $SOURCE_FILES_PATH/src; then
            report "Cannot remove source files $SOURCE_FILES_PATH/src"
            exit 1
        fi
    fi

    # remove app_mor.so
    if [ -f $SOURCE_FILES_PATH/app_mor.so ]; then
        if ! rm -fr $SOURCE_FILES_PATH/app_mor.so; then
            report "Cannot remove $SOURCE_FILES_PATH/app_mor.so"
            exit 1
        fi
    fi

    # remove app_mor_tmp.so
    if [ -f $SOURCE_FILES_PATH/app_mor_tmp.so ]; then
        if ! rm -fr $SOURCE_FILES_PATH/app_mor_tmp.so; then
            report "Cannot remove $SOURCE_FILES_PATH/app_mor_tmp.so"
            exit 1
        fi
    fi

    if ! rm -fr $SOURCE_FILES_PATH/*.c; then
        report "Cannot remove $SOURCE_FILES_PATH/*.c"
        exit 1
    fi

    if ! rm -fr $SOURCE_FILES_PATH/*.h; then
        report "Cannot remove $SOURCE_FILES_PATH/*.h"
        exit 1
    fi

    if ! rm -fr $SOURCE_FILES_PATH/*.o; then
        report "Cannot remove $SOURCE_FILES_PATH/*.o"
        exit 1
    fi

    if ! rm -fr /root/.subversion/auth; then
        report "Cannot remove /root/.subversion/*"
        exit 1
    fi

    if ! rm -fr $SOURCE_FILES_PATH/Makefile; then
        report "Cannot remove $SOURCE_FILES_PATH/Makefile"
        exit 1
    fi

    if ! rm -fr $SOURCE_FILES_PATH/mor_core_recompile.sh; then
        report "$SOURCE_FILES_PATH/mor_core_recompile.sh"
        exit 1
    fi

    if ! rm -fr $SOURCE_FILES_PATH/.svn; then
        report "Cannot remove $SOURCE_FILES_PATH/.svn"
        my_exit 1
    fi

    if ! rm -fr $SOURCE_FILES_PATH; then
        report "Cannot remove $SOURCE_FILES_PATH"
        my_exit 1
    fi

    CURRENT_TIME_SECONDS=`date +"%s"`
    TIME_DIFF=$(( ($CURRENT_TIME_SECONDS - $START_TIME_SECONDS)/60 ))
    report "Script run time \e[1;34m$TIME_DIFF\e[0m minutes" 3

    report "Cleaning successfull" 0

    if [ $1 -ne 0 ]; then
        # change dialplan routing
        replace_string /etc/asterisk/extensions_mor.conf "n,mor_tmp" "n,mor"
        # reload dialplan
        asterisk -rx "dialplan reload" &> $DEBUG_OUTPUT
        report "Dialplan changed: new calls are routed to app_mor" 0
    else
        report "MOR Core has been successfully recompiled!" 0
    fi

    exit $1

}

get_use_count() {

    USE_COUNT=`asterisk -rx "module show like mor" | grep app_mor.so | grep -Po "(?<= )\d+"`

    if ! echo $USE_COUNT | grep -Eq '^[0-9]+$'; then
       report "Use count is not an integer: $USE_COUNT" 1
       my_exit 1
    fi

    return $USE_COUNT

}

get_active_calls_count() {

    ACTIVE_CALLS=`asterisk -rx "$1 show status" | grep -Po '(?<=now/limit: )\d+/' | tr '/' ' '`

    if ! echo $ACTIVE_CALLS | grep -Eq '^[0-9]+$'; then
       report "Active calls count is not an integer: $ACTIVE_CALLS" 1
       my_exit 1
    fi

    return $ACTIVE_CALLS

}

wait_for_calls() {

    COUNTER=0
    while [ 1 ]; do

        get_active_calls_count $1
        ACTIVE_CALLS=$?

        # check if we still have active calls
        if [ $ACTIVE_CALLS -eq 0 ]; then
            break
        fi

        sleep $CHECK_INTERVAL
        let COUNTER+=$CHECK_INTERVAL

        report "Active calls count for $1 = $ACTIVE_CALLS" 3

        #check for timeout
        if [ $COUNTER -eq 60 ]; then
            COUNTER=0
            CURRENT_TIME_SECONDS=`date +"%s"`
            TIME_DIFF=$(( ($CURRENT_TIME_SECONDS - $START_TIME_SECONDS)/60 ))
            report "Script started \e[1;32m$START_TIME\e[0m Script run time \e[1;34m$TIME_DIFF\e[0m minutes" 3
        fi

    done

    report "No active calls for $1 detected" 0

    sleep 5

}

check_if_can_recompile() {

    COUNTER=0

    for i in 1 2 3 4 5; do

        get_use_count
        USE_COUNT=$?

        get_active_calls_count mor
        ACTIVE_CALLS=$?

        REAL_MSG_AC=`asterisk -rx "mor show status" | grep -P '(?<=now/limit: )\d+/'`
        REAL_MSG_USE=`asterisk -rx "module show like mor" | grep app_mor.so | grep -P "(?<= )\d+"`

        if [ $ACTIVE_CALLS -eq $USE_COUNT ]; then
            report "Use count = $USE_COUNT, active calls = $ACTIVE_CALLS" 0
            COUNTER=$(( COUNTER + 1))
        else
            report "Use count = $USE_COUNT, active calls = $ACTIVE_CALLS)" 1
        fi

        echo "$REAL_MSG_AC" &> $DEBUG_OUTPUT
        echo "$REAL_MSG_USE" &> $DEBUG_OUTPUT

        sleep 1

    done

    if [ $COUNTER -gt 2 ]; then
        report "Core can be recompiled" 0
    else
        report "Core can not be recompiled. Asterisk restart is required..." 1
        my_exit 1
    fi

}

check_if_core_authorized() {

    # check if we can determine authorization
    CAN_DETECT=`asterisk -rx "mor show status" | grep -Po "\---------------------------------------------------" | wc -l`

    if [ $CAN_DETECT -eq 1 ]; then
        # get installed MOR Core version
        AUTHORIZED=`asterisk -rx "mor show status" | grep -oP "(?<=MOR Core Status) \(not authorized\)" | wc -l`

        if [ $AUTHORIZED -eq 1 ]; then
            report "MOR Core is not authorized!" 1
        else
            report "MOR Core is authorized" 0
        fi
    else
        report "Can't determine if MOR Core is authorized" 3
    fi

}

check_if_mor_exists() {

    # check if core is installed
    IS_INSTALLED=`asterisk -rx "mor show status" | grep -oP "MOR Core Status" | wc -l`

    if [ "$IS_INSTALLED" == "0" ]; then
        return 0
    else
        return 1
    fi

}

check_if_gui_exists() {

    STATUS=`svn status /home/mor &> /dev/stdout | grep 'is not a working copy' | wc -l`

    if [ "$STATUS" == "1" ]; then
        return 0
    else
        return 1
    fi

}


###########################################
########        MAIN SCRIPT        ########
###########################################


rm -fr /tmp/.mor_global_test-fix_framework_variables &> $DEBUG_OUTPUT

# get path to this script
mkdir -p $SOURCE_FILES_PATH
cd $SOURCE_FILES_PATH

check_if_gui_exists

if [ $? -eq 0 ]; then

    RESP2=
    report "MOR GUI not found. Please enter Core version: (12/x3/x4/x5/x6)" 3
    read -t 60 RESP2

    if [ "$RESP2" != "x3" ] && [ "$RESP2" != "x4" ] && [ "$RESP2" != "x5" ] && [ "$RESP2" != "x6" ] && [ "$RESP2" != "12" ]; then
        report "Version not found. Aborting script..." 1
        my_exit 0
    fi

    if [ "$RESP2" == "x3" ]; then
        MOR_VERSION="x3"
        CORE_BRANCH=branches/12
    fi
    if [ "$RESP2" == "12" ]; then
        MOR_VERSION="12"
        CORE_BRANCH=branches/12
    fi
    if [ "$RESP2" == "x4" ]; then
        MOR_VERSION="x4"
        CORE_BRANCH=trunk
    fi
    if [ "$RESP2" == "x5" ]; then
        MOR_VERSION="x5"
        CORE_BRANCH=branches/x5
    fi
    if [ "$RESP2" == "x6" ]; then
        MOR_VERSION="x6"
        CORE_BRANCH=branches/x6
    fi


else

    # get current GUI version
    MOR_VERSION=`svn info /home/mor | grep -Po "(?<=branches/).+"`
    if [ $MOR_VERSION == "12" ]; then
        MOR_VERSION="x3"
        CORE_BRANCH=branches/12
    fi
    if [ $MOR_VERSION == "12.126" ]; then
        CORE_BRANCH=branches/12
    fi
    if [ $MOR_VERSION == "x5" ]; then
        MOR_VERSION="x5"
        CORE_BRANCH=branches/x5
    fi
    if [ $MOR_VERSION == "x6" ]; then
        MOR_VERSION="x6"
        CORE_BRANCH=branches/x6
    fi
fi

for i in "$@"; do

    if [ "$i" == "RESTORE" ]; then
        my_exit 1
    fi

    if [ "$i" == "FORCE" ]; then
        FORCE=1
    fi

    if [ "$i" == "DEBUG" ]; then
        DEBUG=1
    fi

    if [ "$i" == "NO_SCREEN" ]; then
        NO_SCREEN=1
    fi

    if [ "$i" == "NO_DB" ]; then
        NO_DB=1
    fi

    if [ "$i" == "INSTALL" ]; then
        INSTALL=1
    fi

done

# require to be running from screen
if [ $NO_SCREEN -eq 0 ]; then
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual" 1
        exit 1
    fi
fi

# if debug is enabled, redirect debug output to stdout
if [ $DEBUG -eq 1 ]; then
    DEBUG_OUTPUT=/dev/stdout
fi

check_if_mor_exists

if [ $? -eq 0 ]; then
    RESP1=
    report "MOR Core not found. Install new MOR Core? (y/n)" 3
    read -t 60 RESP1
    if [ "$RESP1" != "y" ]; then
        report "Aborting script..." 1
        my_exit 0
    fi
    INSTALL=1
fi

if [ $INSTALL -eq 1 ]; then
    report "Starting MOR Core installation" 3
else
    report "Starting MOR Core recompilation" 3
fi

# compare asteriks internal 'USE COUNT' variable to MOR Core 'ACTIVE CALLS'
# if 'USE COUNT' > 'ACTIVE CALLS' we can not recompile Core, because it requires asterisk restart
if [ $INSTALL -eq 0 ]; then
    report "Checking if MOR Core can be recompiled using this script..." 3
    check_if_can_recompile
fi

if ! rm -fr $SOURCE_FILES_PATH/.svn; then
    report "Cannot remove $SOURCE_FILES_PATH/.svn"
    my_exit 1
fi

# check if source files are downloaded

if [ ! -f $SOURCE_FILES_PATH/app_mor.h ]; then

    report "Downloading MOR Core source files. Please enter password:" 3
    svn co --username support --no-auth-cache http://svn.kolmisoft.com/mor/core/$CORE_BRANCH $SOURCE_FILES_PATH/

    if [ $? -eq 1 ]; then
        report "Failed to download MOR Core source files"
        my_exit 1
    fi

    report "MOR Core source files downloaded successfully" 0
    report "Path to source files: $SOURCE_FILES_PATH" 0

    if [ $INSTALL -eq 0 ]; then
        report "Make all the necessary modifications and execute this script again to proceed Core upgrade" 3
    else
        report "Make all the necessary modifications and execute this script again to proceed Core install" 3
    fi
    exit 0

fi

# get current MOR Core version from source files
CURRENT_CORE=`cat $SOURCE_FILES_PATH/app_mor.h | grep MOR_VERSION | grep -o '"*[a-Z0-9.]\+"'`

if ! rm -fr /root/.subversion/auth; then
    report "Cannot remove /root/.subversion/*"
    my_exit 1
fi

report "MOR version is \"$MOR_VERSION\" and Core version is $CURRENT_CORE. Is this correct? (y/n)" 3

read -t 60 RESP
if [ "$RESP" != "y" ]; then
    report "Aborting script..." 1
    my_exit 0
fi

if [ $MOR_VERSION == "x3" ] || [ $MOR_VERSION == "12.126" ] || [ $MOR_VERSION == "x4" ] || [ $MOR_VERSION == "x5" ] || [ $MOR_VERSION == "x6" ]; then

    if [ $MOR_VERSION == "x3" ]; then
        MOR_VERSION="12"
    fi

    if [ $NO_DB -eq 0 ]; then
        report "Updating database" 3
        svn_update /usr/src/mor
        /usr/src/mor/db/$MOR_VERSION/import_changes.sh
        report "Database update is completed" 0
    fi

fi

cd $SOURCE_FILES_PATH

# create src directory
if ! mkdir -p $SOURCE_FILES_PATH/src; then
    report "Cannot create $SOURCE_FILES_PATH/src directory" 1
    my_exit 1
fi
report "$SOURCE_FILES_PATH/src directory created" 0

if ! cp -fr *.c ./src; then
    report "error while making a copy of current source files (c)" 1
    my_exit 1
fi
if ! cp -fr *.h ./src; then
    report "error while making a copy of current source files (h)" 1
    my_exit 1
fi
if ! cp -fr Makefile ./src; then
    report "error while making a copy of current source files (Makefile)" 1
    my_exit 1
fi
report "MOR Core source files are copied to $SOURCE_FILES_PATH/src" 0

# create src_tmp directory
if ! mkdir -p $SOURCE_FILES_PATH/src_tmp; then
    report "Cannot create $SOURCE_FILES_PATH/src_tmp directory" 1
    my_exit 1
fi
report "$SOURCE_FILES_PATH/src_tmp directory created" 0

# check if we have app_mor files in src directory
if ! ls $SOURCE_FILES_PATH/src | grep 'app_mor.c' > /dev/null; then
    report "source files not found in $SOURCE_FILES_PATH/src" 1
    my_exit 1
fi
report "MOR Core source files found in $SOURCE_FILES_PATH/src" 0

# make a copy of current source files
rm -fr $SOURCE_FILES_PATH/src_tmp/*
if ! cp -fr $SOURCE_FILES_PATH/src/* $SOURCE_FILES_PATH/src_tmp/; then
    report "error while making a copy of current source files" 1
    my_exit 1
fi
report "MOR Core source files are copied to $SOURCE_FILES_PATH/src_tmp" 0

if [ $INSTALL -eq 0 ]; then
    # modify core tmp version
    report "MOR Core source files are being modified" 3

    # replace #define AST_MODULE "app_mor"
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.h "#define AST_MODULE \"app_mor\"" "#define AST_MODULE \"app_mor_tmp\""

    # replace static char *app = "mor";
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.h "static char \*app = \"mor\";" "static char \*app = \"mor_tmp\";"

    # replace e->command = \"mor show status\";
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "e->command = \"mor show status\";" "\t\t\te->command = \"mor_tmp show status\";"

    # replace e->command = \"mor show addons\";
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "e->command = \"mor show addons\";" "\t\t\te->command = \"mor_tmp show addons\";"

    # replace e->command = \"mor logger\";
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "e->command = \"mor logger\";" "\t\t\te->command = \"mor_tmp logger\";"

    # replace e->command = \"mor log cdr\";
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "e->command = \"mor log cdr\";" "\t\t\te->command = \"mor_tmp log cdr\";"

    # replace e->command = \"mor reload\";
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "e->command = \"mor reload\";" "\t\t\te->command = \"mor_tmp reload\";"

    # replace ast_cli(a->fd, "MOR Core Status\n");
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "ast_cli(a->fd, \"MOR Core Status\\\n\");" "\tast_cli(a->fd, \"MOR Core (tmp) Status\\\n\");"

    # replace ast_cli(a->fd, "MOR Core active addons\n");
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "ast_cli(a->fd, \"MOR Core active addons\\\n\");" "\tast_cli(a->fd, \"MOR Core (tmp) active addons\\\n\");"

    # replace ast_cli(a->fd, "Version: %s\n", MOR_VERSION);
    replace_line $SOURCE_FILES_PATH/src_tmp/app_mor.c "ast_cli(a->fd, \"Version: %s\\\n\", MOR_VERSION);" "\tast_cli(a->fd, \"Version: %s (tmp)\\\n\", MOR_VERSION);"

    # change Makefile
    replace_string $SOURCE_FILES_PATH/src_tmp/Makefile "app_mor.so" "app_mor_tmp.so"

    # add ".tmp" after core version
    sed -i 's|MOR_VERSION \"[0-9a-Z]\+.[0-9a-Z]\+.[0-9a-Z]\+|&.tmp|' $SOURCE_FILES_PATH/src_tmp/app_mor.h

    report "Modification completed" 0
fi

# check if asterisk is running
ps -A | grep -v safe_asterisk | grep asterisk &> $DEBUG_OUTPUT
if [ $? -eq 1 ]; then
    report "Astrisk is not running" 1
    my_exit 1
fi
report "Asterisk is running" 0

if [ $INSTALL -eq 0 ]; then
    # make old core backup
    cp -fr $ASTERISKMODDIR/app_mor.so $ASTERISKMODDIR/app_mor.so.backup
    report "MOR Core backup is placed in $ASTERISKMODDIR/app_mor.so.backup" 3
fi

# recompile app_mpr
cd $SOURCE_FILES_PATH/src
make clean &> $DEBUG_OUTPUT
if ! make &> $DEBUG_OUTPUT; then
    report "app_mor compilation error" 1
    my_exit 1
fi
if ! cp -fr $SOURCE_FILES_PATH/src/app_mor.so $SOURCE_FILES_PATH/app_mor.so; then
    report "Cannot copy app_mor.so" 1
    my_exit 1
fi
report "app_mor recompiled successfully" 0

if [ $INSTALL -eq 0 ]; then

    # recompile app_mpr_tmp
    cd $SOURCE_FILES_PATH/src_tmp
    make clean &> $DEBUG_OUTPUT
    if ! make &> $DEBUG_OUTPUT; then
        report "app_mor_tmp compilation error" 1
        my_exit 1
    fi
    if ! cp -fr $SOURCE_FILES_PATH/src_tmp/app_mor_tmp.so $SOURCE_FILES_PATH/app_mor_tmp.so; then
        report "Cannot copy app_mor_tmp.so" 1
        my_exit 1
    fi
    report "app_mor_tmp recompiled successfully" 0

fi

# return to script path
cd $SOURCE_FILES_PATH

# remove source files from the system
if ! rm -fr $SOURCE_FILES_PATH/*.o; then
    report "Cannot remove $SOURCE_FILES_PATH/*.o"
    my_exit 1
fi
if ! rm -fr $SOURCE_FILES_PATH/*.c; then
    report "Cannot remove $SOURCE_FILES_PATH/*.c"
    my_exit 1
fi
if ! rm -fr $SOURCE_FILES_PATH/*.h; then
    report "Cannot remove $SOURCE_FILES_PATH/*.h"
    my_exit 1
fi
if ! rm -fr $SOURCE_FILES_PATH/src_tmp; then
    report "Cannot remove $SOURCE_FILES_PATH/src_tmp"
    my_exit 1
fi
if ! rm -fr $SOURCE_FILES_PATH/src/*; then
    report "Cannot remove $SOURCE_FILES_PATH/src_tmp"
    my_exit 1
fi
if ! rm -fr $SOURCE_FILES_PATH/Makefile; then
    report "Cannot remove $SOURCE_FILES_PATH/Makefile"
    my_exit 1
fi
report "Source files removed" 0

if [ $INSTALL -eq 0 ]; then

    # unload app_mor_tmp
    asterisk -rx "module unload app_mor_tmp" &> $DEBUG_OUTPUT
    # install app_mor_tmp
    if ! install -m 755 $SOURCE_FILES_PATH/app_mor_tmp.so $ASTERISKMODDIR; then
        report "app_mor_tmp.so cannot be installed" 1
        my_exit 1
    fi

    # load app_mor_tmp
    asterisk -rx "module load app_mor_tmp" &> $DEBUG_OUTPUT
    report "app_mor_tmp.so installed" 0
    # check if app_mor_tmp is active
    asterisk -rx "mor_tmp show status" | grep "Version" &> $DEBUG_OUTPUT
    if [ $? -eq 1 ]; then
        report "app_mor_tmp is not active" 1
        my_exit 1
    fi

    # change dialplan routing
    replace_string /etc/asterisk/extensions_mor.conf "n,mor" "n,mor_tmp"
    # reload dialplan
    asterisk -rx "dialplan reload" &> $DEBUG_OUTPUT
    report "Dialplan changed: new calls are routed to app_mor_tmp" 0

    # periodically check if mor_app still has active calls
    wait_for_calls mor

fi

# unload app_mor
asterisk -rx "module unload app_mor" &> $DEBUG_OUTPUT
# install app_mor
if ! install -m 755 $SOURCE_FILES_PATH/app_mor.so $ASTERISKMODDIR; then
    report "app_mor.so cannot be installed" 1
    my_exit 1
fi

# load app_mor
asterisk -rx "module load app_mor.so" &> $DEBUG_OUTPUT
report "app_mor.so installed" 0

if [ $INSTALL -eq 0 ]; then

    # change dialplan routing
    replace_string /etc/asterisk/extensions_mor.conf "n,mor_tmp" "n,mor"
    # reload dialplan
    asterisk -rx "dialplan reload" &> $DEBUG_OUTPUT
    report "Dialplan changed: new calls are routed to app_mor" 0

    # periodically check if mor_app_tmp still has active calls
    wait_for_calls mor_tmp

    # unload app_mor_tmp
    asterisk -rx "module unload app_mor_tmp" &> $DEBUG_OUTPUT
    if ! rm -fr $ASTERISKMODDIR/app_mor_tmp.so; then
        report "Cannot remove app_mor_tmp.so from $ASTERISKMODDIR" 2
    fi
    report "app_mor_tmp.so removed from $ASTERISKMODDIR" 0

fi

# get installed MOR Core version
INSTALLED_CORE=\"`asterisk -rx "mor show status" | grep -Po "(?<=Version: )[a-zA-Z0-9.]*"`\"

# compare Core versions (from source files and installed)
if [ $INSTALLED_CORE == $CURRENT_CORE ]; then
    report "Installed Core version ($INSTALLED_CORE) matches version from source files ($CURRENT_CORE)" 0
else
    report "Installed Core version ($INSTALLED_CORE) doesn't match version from the source files ($CURRENT_CORE)" 1
    my_exit 1
fi

check_if_core_authorized

my_exit 0
