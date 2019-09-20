#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH

cd ./rootlessJB4/tars/

rm -rf iosbinpack64 tweaksupport 

tar -xvf ./tweaksupport.tar
tar -xvf ./iosbinpack.tar

# rm -f tweaksupport.tar iosbinpack.tar


