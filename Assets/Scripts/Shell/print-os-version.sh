#!/bin/bash

echo $(lsb_release -a 2>/dev/null | grep Description | cut -d ':' -f2) $(lsb_release -a 2>/dev/null | grep Codename | cut -d ':' -f2)

