#!/bin/bash

source etc/source_env

pyfr_venv=pyfr-venv

pyfr_repo=https://github.com/PyFR/PyFR.git
pyfr_tag=develop

pyfr=${pyfr_repo##*/}
pyfr=${pyfr%.*}

if [ ! -d $pyfr ]; then

git clone --depth=1  --branch $pyfr_tag $pyfr_repo

else

exit 1

fi


python3 -m virtualenv $pyfr_venv

source $pyfr_venv/bin/activate

pip3 install --no-cache ./$pyfr

deactivate
