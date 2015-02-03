#!/bin/bash
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================
. /usr/src/mor/x6/framework/bash_functions.sh

if [  ! -f "/usr/bin/rrdtool" ]; then
    yum -y install rrdtool
fi

which_os # keep it here, do not remove
PSWS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
( cd /sys/class/net && printf "%s\n" * ) >/tmp/interfaces
if [ $OS = "CENTOS" ]; then
    yum -y install rrdtool-perl rrdtool-devel rrdtool

if [ ! -f /tmp/elunastats.tar.gz ]; then
    yum -y install perl-Module-Build perl-DateTime perl-CGI

  cd /tmp
  rm -rf stats
  rm -rf elunastats
  wget http://$KOLMISOFT_IP/packets/elunastats.tar.gz
  tar xvfz elunastats.tar.gz
fi
if [ ! -d /var/www/html/stats ]; then
mkdir -p /var/www/html/stats
cd /tmp/stats
rpm --install /tmp/stats/rr/libart_lgpl-2.3.17-4.i386.rpm
rpm --install /tmp/stats/rr/libart_lgpl-devel-2.3.17-4.i386.rpm
rpm --install /tmp/stats/rr/rrdtool-1.2.19-1.el5.kb.i386.rpm   
tar xvfz /tmp/stats/DateTime-0.4501.tar.gz
tar xvfz /tmp/stats/DateTime-Locale-0.42.tar.gz
tar xvfz /tmp/stats/DateTime-TimeZone-0.8301.tar.gz
tar xvfz /tmp/stats/HTML-Template-2.9.tar.gz       
tar xvfz /tmp/stats/HTML-Template-Expr-0.07.tar.gz
tar xvfz /tmp/stats/List-MoreUtils-0.22.tar.gz     
tar xvfz /tmp/stats/Params-Validate-0.91.tar.gz   
tar xvfz /tmp/stats/Parse-RecDescent-1.96.0.tar.gz
tar xvfz /tmp/stats/version-0.76.tar.gz           
tar xvfz /tmp/stats/elunastats.tar.gz
cp -R /tmp/stats/stats /var/www/html
cd /tmp/stats/DateTime-0.4501
    perl Makefile.PL           
    make                       
    make install               
cd /tmp/stats/DateTime-Locale-0.42
    perl Makefile.PL               
    make                           
    make install                   
cd /tmp/stats/DateTime-TimeZone-0.8301
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/HTML-Template-2.9       
    perl Makefile.PL                   
    make                               
    make install
cd /tmp/stats/HTML-Template-Expr-0.07
    perl Makefile.PL
    make
    make install
cd /tmp/stats/List-MoreUtils-0.22
    perl Makefile.PL
    make
    make install
cd /tmp/stats/Params-Validate-0.91
    perl Makefile.PL
    make
    make install
cd /tmp/stats/Parse-RecDescent-1.96.0
    perl Makefile.PL
    make
    make install
cd /tmp/stats/version-0.76
    perl Makefile.PL
    make
    make install
rm -rf /tmp/stats
rm -rf /tmp/elunastats.tar.gz
cd /tmp
checkforcgi=`cat /etc/httpd/conf/httpd.conf  | grep /var/www/html/stats/`
if [ ! "$checkforcgi" = "<Directory /var/www/html/stats/>" ]; then
echo "<Directory /var/www/html/stats/>
AddHandler cgi-script .pl
Options +ExecCGI
DirectoryIndex index.pl
</Directory>" >>/etc/httpd/conf/httpd.conf # apache will be restarted later
fi
fi #done with install
       
#cron check
checkforcron=`crontab -l | grep /var/www/html/stats/update.pl`
rm -rf /tmp/crontab.tmp
crontab -l >/tmp/crontab.tmp
# test()
if [ ! "$checkforcron" = "*/5 * * * * /var/www/html/stats/update.pl" ]; then
        echo "*/5 * * * * /var/www/html/stats/update.pl" >>/tmp/crontab.tmp
fi
/usr/bin/crontab /tmp/crontab.tmp
#(main)       
for interfacename2 in `cat /tmp/interfaces`; do
    if [ ! -d /var/www/html/stats/rrd/${interfacename2}_in ]; then
        mkdir -p /var/www/html/stats/rrd/${interfacename2}_in
fi
    biginterfacename2=$(awk -v v="$interfacename2" 'BEGIN{print toupper(v)}') # translate var to VAR
if [ ! -f /var/www/html/stats/rrd/${interfacename2}_in/create.sh ]; then
echo "#!/bin/bash
  rrdtool create ${interfacename2}_in.rrd \\
  --start \`date +%s\` \\
  --step 300 \\
  DS:in:COUNTER:600:0:U \\
  RRA:AVERAGE:0.5:1:2016 \\
  RRA:AVERAGE:0.5:6:1344 \\
  RRA:AVERAGE:0.5:24:732 \\
  RRA:AVERAGE:0.5:144:1460" >>/var/www/html/stats/rrd/${interfacename2}_in/create.sh
chmod 755 /var/www/html/stats/rrd/${interfacename2}_in/create.sh
fi
if [ ! -f /var/www/html/stats/rrd/${interfacename2}_in/graph.pm ]; then
echo "\$GRAPH_TITLES{'${interfacename2}_in'} = \"{#server#} - $interfacename2 Inbound Traffic\";
\$GRAPH_CMDS{'${interfacename2}_in'} = <<\"${biginterfacename2}_IN_GRAPH_CMD\";
--title \"{#server#} - $biginterfacename2 Inbound Traffic\"
--vertical-label=\"Bytes\"
--lower-limit 0
DEF:in={#path#}${interfacename2}_in.rrd:in:AVERAGE
AREA:in{#color5#}:\"Inbound  \"
GPRINT:in:LAST:\"Current\\\: %5.2lf %s  \"
GPRINT:in:AVERAGE:\"Average\\\: %5.2lf %s  \"
GPRINT:in:MAX:\"Maximum\\\: %5.2lf %s\\\n\"
LINE1:in{#linecolor#}
${biginterfacename2}_IN_GRAPH_CMD
1; # Return true" >>/var/www/html/stats/rrd/${interfacename2}_in/graph.pm
chmod 755 /var/www/html/stats/rrd/${interfacename2}_in/graph.pm
fi
if [ ! -f /var/www/html/stats/rrd/${interfacename2}_in/update.sh ]; then
echo "#!/bin/bash
rrdtool update ${interfacename2}_in.rrd \\
  -t in \\
  N:\`/sbin/ifconfig $interfacename2 |grep bytes|cut -d\":\" -f2|cut -d\" \" -f1\`" >>/var/www/html/stats/rrd/${interfacename2}_in/update.sh
chmod 755 /var/www/html/stats/rrd/${interfacename2}_in/update.sh
fi
done
                                #OUT
#-----------------------create $interface_out----------------------------------------------
for interfacename in `cat /tmp/interfaces`; do
if [ ! -d /var/www/html/stats/rrd/${interfacename}_out ]; then
mkdir -p /var/www/html/stats/rrd/${interfacename}_out
fi
   
    #$a = expr `ls | tail -n 1 | awk '{split ($0,a,"_"); print a[1]}'` + 1
   
    biginterfacename=$(awk -v v="$interfacename" 'BEGIN{print toupper(v)}') # translate var to VAR
    #echo $biginterfacename
#${interface}_out
if [ ! -f /var/www/html/stats/rrd/${interfacename}_out/create.sh ]; then
#GEN create.sh $interface_out----------------------------------------------------------------   
    echo -n "#!/bin/bash
    rrdtool create " >>/var/www/html/stats/rrd/${interfacename}_out/create.sh
   
    echo -n "$interfacename" >>/var/www/html/stats/rrd/${interfacename}_out/create.sh
   
    echo -n "_out.rrd \\
    --start \`date +%s\` \\
    --step 300 \\
    DS:out:COUNTER:600:0:U \\
    RRA:AVERAGE:0.5:1:2016 \\
    RRA:AVERAGE:0.5:6:1344 \\
    RRA:AVERAGE:0.5:24:732 \\
    RRA:AVERAGE:0.5:144:1460" >>/var/www/html/stats/rrd/${interfacename}_out/create.sh
chmod 755 /var/www/html/stats/rrd/${interfacename}_out/create.sh
fi
#----------------------------------------------------------end of gen create.sh
if [ ! -f /var/www/html/stats/rrd/${interfacename}_out/graph.pm ]; then
#GEN graph.pm $interface_out-------------------------------------------------------------------------
echo -n "\$GRAPH_TITLES{'" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "$interfacename" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "_out'} = \"{#server#} - $biginterfacename Outbound Traffic\";
\$GRAPH_CMDS{'" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "$interfacename" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "_out'} = <<\"" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "$biginterfacename" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "_OUT_GRAPH_CMD\";
--title \"{#server#} - $biginterfacename Outbound Traffic\"
--vertical-label=\"Bytes\"
--lower-limit 0
DEF:out={#path#}" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "$interfacename" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "_out.rrd:out:AVERAGE
AREA:out{#color5#}:\"Outbound \"
GPRINT:out:LAST:\"Current\\\: %5.2lf %s  \"
GPRINT:out:AVERAGE:\"Average\\\: %5.2lf %s  \"
GPRINT:out:MAX:\"Maximum\\\: %5.2lf %s\\\n\"
LINE1:out{#linecolor#}" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo "" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo -n "$biginterfacename" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
echo  "_OUT_GRAPH_CMD
1; # Return true" >>/var/www/html/stats/rrd/${interfacename}_out/graph.pm
chmod 755 /var/www/html/stats/rrd/${interfacename}_out/graph.pm
fi
#----------------------------------------------------------------END OF GEN graph.pm
if [ ! -f /var/www/html/stats/rrd/${interfacename}_out/update.sh ]; then
#GEN update.pl $interface_out----------------------------------------------------
echo -n "#!/bin/bash
rrdtool update " >>/var/www/html/stats/rrd/${interfacename}_out/update.sh
echo -n "$interfacename" >>/var/www/html/stats/rrd/${interfacename}_out/update.sh
echo -n "_out.rrd \\
  -t out \\
    N:\`/sbin/ifconfig $interfacename |grep bytes|cut -d\":\" -f3|cut -d\" \" -f1\`" >>/var/www/html/stats/rrd/${interfacename}_out/update.sh
chmod 755 /var/www/html/stats/rrd/${interfacename}_out/update.sh
fi
#-----------------------------------------------------------------
   
done
# gen psw
if [ ! -f /var/www/html/stats/.htpasswd ]; then
    touch /var/www/html/stats/.htpasswd
    htpasswd -b -m /var/www/html/stats/.htpasswd admin $PSWS
   
    rm -rf /root/statspassword
    touch /root/statsPassword
    echo "Your Login and Password from stats system is: admin $PSWS" >/root/statsPassword
fi
if [ ! -f /var/www/html/stats/.htaccess ]; then
    touch /var/www/html/stats/.htaccess
    echo "AuthUserFile /var/www/html/stats/.htpasswd
          AuthName \"Restricted access, password located in /root/statsPassword file\"
          AuthType Basic
          Require valid-user" > /var/www/html/stats/.htaccess
          /etc/init.d/httpd restart
fi
chmod 777 /var/www/html/stats/graphs
echo "Updating... (This can take some minutes to complete if running first time)"
exec /var/www/html/stats/update.pl
#if [ $OS = "CENTOS" ]; then
#done for centos
elif [ $OS = "DEBIAN" ]; then
checkforcgi2=`cat /etc/apache2/apache2.conf | grep /var/www/stats/`
if [ ! "$checkforcgi2" = "<Directory /var/www/stats/>" ]; then
echo "<Directory /var/www/stats/>
AddHandler cgi-script .pl
Options +ExecCGI
DirectoryIndex index.pl
</Directory>" >>/etc/apache2/apache2.conf
fi
if [ ! -f /usr/bin/rrdtool ]; then
apt-get -y install rrdtool
fi
( cd /sys/class/net && printf "%s\n" * ) >/tmp/interfaces
if [ ! -f /tmp/elunastats.tar.gz ]; then
  cd /tmp                               
  rm -rf stats                         
  rm -rf elunastats                     
  wget http://$KOLMISOFT_IP/packets/elunastats.tar.gz
  tar xvfz elunastats.tar.gz                         
fi                                                   
if [ ! -d /var/www/stats ]; then
mkdir -p /var/www/stats
cd /tmp/stats
tar xvfz /tmp/stats/DateTime-0.4501.tar.gz
tar xvfz /tmp/stats/DateTime-Locale-0.42.tar.gz
tar xvfz /tmp/stats/DateTime-TimeZone-0.8301.tar.gz
tar xvfz /tmp/stats/HTML-Template-2.9.tar.gz       
tar xvfz /tmp/stats/HTML-Template-Expr-0.07.tar.gz
tar xvfz /tmp/stats/List-MoreUtils-0.22.tar.gz     
tar xvfz /tmp/stats/Params-Validate-0.91.tar.gz   
tar xvfz /tmp/stats/Parse-RecDescent-1.96.0.tar.gz
tar xvfz /tmp/stats/version-0.76.tar.gz           
tar xvfz /tmp/stats/elunastats.tar.gz             
cp -R /tmp/stats/stats /var/www
cd /tmp/stats/DateTime-0.4501       
    perl Makefile.PL               
    make                           
    make install                   
cd /tmp/stats/DateTime-Locale-0.42 
    perl Makefile.PL               
    make                           
    make install                   
cd /tmp/stats/DateTime-TimeZone-0.8301
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/HTML-Template-2.9         
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/HTML-Template-Expr-0.07   
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/List-MoreUtils-0.22       
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/Params-Validate-0.91     
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/Parse-RecDescent-1.96.0   
    perl Makefile.PL                   
    make                               
    make install                       
cd /tmp/stats/version-0.76             
    perl Makefile.PL                   
    make                               
    make install                       
rm -rf /tmp/stats
rm -rf /tmp/elunastats.tar.gz
cd /tmp                     
fi #done with install
                     
#cron check and maybe install()
checkforcron=`crontab -l | grep /var/www/stats/update.pl`
rm -rf /tmp/crontab.tmp                                       
crontab -l >/tmp/crontab.tmp                                 
# test()                                                     
if [ ! "$checkforcron" = "*/5 * * * * /var/www/stats/update.pl" ]; then
        echo "*/5 * * * * /var/www/stats/update.pl" >>/tmp/crontab.tmp
fi                                                                         
/usr/bin/crontab /tmp/crontab.tmp                                           
#(main)       
for interfacename2 in `cat /tmp/interfaces`; do
    if [ ! -d /var/www/stats/rrd/${interfacename2}_in ]; then
        mkdir -p /var/www/stats/rrd/${interfacename2}_in       
fi                                                               
    biginterfacename2=$(awk -v v="$interfacename2" 'BEGIN{print toupper(v)}') # translate var to VAR
#'
if [ ! -f /var/www/stats/rrd/${interfacename2}_in/create.sh ]; then
echo "#!/bin/bash
  rrdtool create ${interfacename2}_in.rrd --start \`date +%s\` --step 300 DS:in:COUNTER:600:0:U RRA:AVERAGE:0.5:1:2016 RRA:AVERAGE:0.5:6:1344 RRA:AVERAGE:0.5:24:732 RRA:AVERAGE:0.5:144:1460" >>/var/www/stats/rrd/${interfacename2}_in/create.sh
chmod 755 /var/www/stats/rrd/${interfacename2}_in/create.sh                   
fi                                                                                 
if [ ! -f /var/www/stats/rrd/${interfacename2}_in/graph.pm ]; then
echo "\$GRAPH_TITLES{'${interfacename2}_in'} = \"{#server#} - $interfacename2 Inbound Traffic\";
\$GRAPH_CMDS{'${interfacename2}_in'} = <<\"${biginterfacename2}_IN_GRAPH_CMD\";
--title \"{#server#} - $biginterfacename2 Inbound Traffic\"
--vertical-label=\"Bytes\"
--lower-limit 0
DEF:in={#path#}${interfacename2}_in.rrd:in:AVERAGE
AREA:in{#color5#}:\"Inbound  \"
GPRINT:in:LAST:\"Current\\\: %5.2lf %s  \"
GPRINT:in:AVERAGE:\"Average\\\: %5.2lf %s  \"
GPRINT:in:MAX:\"Maximum\\\: %5.2lf %s\\\n\"
LINE1:in{#linecolor#}
${biginterfacename2}_IN_GRAPH_CMD
1; # Return true" >>/var/www/stats/rrd/${interfacename2}_in/graph.pm
chmod 755 /var/www/stats/rrd/${interfacename2}_in/graph.pm         
fi                                                                       
if [ ! -f /var/www/stats/rrd/${interfacename2}_in/update.sh ]; then
echo "#!/bin/bash                                                       
rrdtool update ${interfacename2}_in.rrd -t in N:\`/sbin/ifconfig $interfacename2 |grep bytes|cut -d\":\" -f2|cut -d\" \" -f1\`" >>/var/www/stats/rrd/${interfacename2}_in/update.sh
chmod 755 /var/www/stats/rrd/${interfacename2}_in/update.sh                                                                           
fi                                                                                                                                         
done
                                #OUT
#-----------------------create $interface_out----------------------------------------------
for interfacename in `cat /tmp/interfaces`; do                                             
if [ ! -d /var/www/stats/rrd/${interfacename}_out ]; then
mkdir -p /var/www/stats/rrd/${interfacename}_out           
fi                                                           
                                                             
    #$a = expr `ls | tail -n 1 | awk '{split ($0,a,"_"); print a[1]}'` + 1
                                                                         
    biginterfacename=$(awk -v v="$interfacename" 'BEGIN{print toupper(v)}') # translate var to VAR
    #echo $biginterfacename                                                                       
#${interface}_out                                                                                 
#'
if [ ! -f /var/www/html/rrd/${interfacename}_out/create.sh ]; then
#GEN create.sh $interface_out----------------------------------------------------------------   
    echo -n "#!/bin/bash                                                                         
    rrdtool create " >>/var/www/stats/rrd/${interfacename}_out/create.sh                   
                                                                                                 
    echo -n "$interfacename" >>/var/www/stats/rrd/${interfacename}_out/create.sh           
                                                                                                 
    echo -n "_out.rrd --start \`date +%s\` --step 300 DS:out:COUNTER:600:0:U RRA:AVERAGE:0.5:1:2016 RRA:AVERAGE:0.5:6:1344 RRA:AVERAGE:0.5:24:732 RRA:AVERAGE:0.5:144:1460" >>/var/www/stats/rrd/${interfacename}_out/create.sh
chmod 755 /var/www/stats/rrd/${interfacename}_out/create.sh
fi                                                             
#----------------------------------------------------------end of gen create.sh
if [ ! -f /var/www/stats/rrd/${interfacename}_out/graph.pm ]; then
#GEN graph.pm $interface_out-------------------------------------------------------------------------
echo -n "\$GRAPH_TITLES{'" >>/var/www/stats/rrd/${interfacename}_out/graph.pm                   
echo -n "$interfacename" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "_out'} = \"{#server#} - $biginterfacename Outbound Traffic\";
\$GRAPH_CMDS{'" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "$interfacename" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "_out'} = <<\"" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "$biginterfacename" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "_OUT_GRAPH_CMD\";
--title \"{#server#} - $biginterfacename Outbound Traffic\"
--vertical-label=\"Bytes\"
--lower-limit 0
DEF:out={#path#}" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "$interfacename" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "_out.rrd:out:AVERAGE
AREA:out{#color5#}:\"Outbound \"
GPRINT:out:LAST:\"Current\\\: %5.2lf %s  \"
GPRINT:out:AVERAGE:\"Average\\\: %5.2lf %s  \"
GPRINT:out:MAX:\"Maximum\\\: %5.2lf %s\\\n\"
LINE1:out{#linecolor#}" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo "" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo -n "$biginterfacename" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
echo  "_OUT_GRAPH_CMD
1; # Return true" >>/var/www/stats/rrd/${interfacename}_out/graph.pm
chmod 755 /var/www/stats/rrd/${interfacename}_out/graph.pm
fi                                                             
#----------------------------------------------------------------END OF GEN graph.pm
if [ ! -f /var/www/stats/rrd/${interfacename}_out/update.sh ]; then
#GEN update.pl $interface_out----------------------------------------------------
echo -n "#!/bin/bash                                                             
rrdtool update " >>/var/www/stats/rrd/${interfacename}_out/update.sh       
echo -n "$interfacename" >>/var/www/stats/rrd/${interfacename}_out/update.sh
echo -n "_out.rrd -t out N:\`/sbin/ifconfig $interfacename |grep bytes|cut -d\":\" -f3|cut -d\" \" -f1\`" >>/var/www/stats/rrd/${interfacename}_out/update.sh
chmod 755 /var/www/stats/rrd/${interfacename}_out/update.sh
fi
#-----------------------------------------------------------------
                                                                 
done                                                             
# gen
if [ ! -f /var/www/stats/.htpasswd ]; then
    touch /var/www/stats/.htpasswd       
    htpasswd -b -m /var/www/stats/.htpasswd admin $PSWS
    rm -rf /root/statspassword
    touch /root/statsPassword
    echo "Your Login and Password from stats system is: admin $PSWS" >/root/statsPassword
fi
if [ ! -f /var/www/stats/.htaccess ]; then
    touch /var/www/stats/.htaccess
    echo "AuthUserFile /var/www/stats/.htpasswd
          AuthName \"Restricted access, password located in /root/statsPassword file\"
          AuthType Basic
          Require valid-user" > /var/www/stats/.htaccess
          /etc/init.d/apache2 restart
fi
chmod 777 /var/www/stats/graphs
echo "Updating... (This can take some minutes to complete if running first time)"
exec /var/www/stats/update.pl
fi #done for DEBIAN
#------------------------------------END------------------------------------------
