#!/bin/bash

echo $(sudo lshw -C display | grep product | cut -d ':' -f2 | sed -E 's/(.+)/\1;/g' | xargs | rev | cut -d ';' -f2- | rev)

