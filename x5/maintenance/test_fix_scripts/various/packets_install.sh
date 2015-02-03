#! /bin/bash

#leaving stderr intact to clearly see errors in case something goes wrong
# Normally should not emit any output
yum install -y perl perl-CPAN perl-Net-SSLeay perl-IO-Socket-SSL > /dev/null
