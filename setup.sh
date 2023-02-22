#!/bin/bash

git clone https://github.com/zeionara/relentness.git $HOME/relentness
git clone https://github.com/zeionara/OpenKE.git $HOME/openke

pushd $HOME/openke
git checkout overhaul
popd

ln -s $HOME/openke $HOME/relentness/openke
echo -e "\nexport PYTHONPATH=\$PYTHONPATH:$HOME/openke/" >> $HOME/.bashrc

conda create -n reltf -f $HOME/relentness/environment.yml
