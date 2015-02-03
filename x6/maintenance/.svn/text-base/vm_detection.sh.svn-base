#!/bin/bash

. /usr/src/mor/x6/framework/bash_functions.sh

detect_vm   # check if this machine is virtual?
if [ "$VM_DETECTED" == "0" ]; then
  echo "Physical server detected"
else
  echo "Virtual server detected: $VM_TYPE"
  if [ "$VM_TYPE" == "LXC" ]; then
    report "Sorry but your virtualization technology LXC is not supported" 1
    exit 1
  fi
fi
