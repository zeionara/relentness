#!/bin/bash

memory_in_kb=$(grep MemTotal /proc/meminfo | cut -d ':' -f2 | xargs | cut -d ' ' -f1)
echo $((memory_in_kb / 1024 / 1024)) Gb

