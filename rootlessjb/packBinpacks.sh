#!/bin/bash

COPYFILE_DISABLE=1; export COPYFILE_DISABLE
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH

cd ./rootlessJB4/tars/

find . -name '.DS_Store' -delete
#find . -name '_CodeSignature' -delete
find . -type f -name '._*' -delete

#shopt -s globstar  ## Enables recursive glob match
#for f in **/._*; do [[ -f $f ]] && echo "$f"; done
#for f in **/._*; do [[ -f $f ]] && rm "$f"; done
#shopt -u globstar

rm -f iosbinpack.tar tweaksupport.tar

tar -cvf ./iosbinpack.tar ./iosbinpack64
tar -cvf ./tweaksupport.tar ./tweaksupport

rm -rf ./iosbinpack64 ./tweaksupport
