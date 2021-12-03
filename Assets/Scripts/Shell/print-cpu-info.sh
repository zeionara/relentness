#!/bin/bash

echo $(lscpu | grep 'Model name:' | cut -d ':' -f2 | xargs) $(lscpu | grep -e '^CPU(s):' | cut -d ':' -f2 | xargs) cores

