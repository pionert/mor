#!/bin/bash

# clean iptables after initial install which blocks almost everything (except port 22 for ssh)
iptables -F
service iptables save
