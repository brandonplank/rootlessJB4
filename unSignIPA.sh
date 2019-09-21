#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH

rm -rf Payload

unzip rootlessJB4.ipa 

find . -name '.DS_Store' -delete
find . -name '_CodeSignature' -delete

find . -name 'embedded.mobileprovision' -delete

rm -f ./Payload/rootlessJB4.app/embedded.mobileprovision
rm -rf ./Payload/rootlessJB4.app/_CodeSignature

#touch ./Payload/rootlessJB4.app/embedded.mobileprovision
mkdir ./Payload/rootlessJB4.app/_CodeSignature

rm -f rootlessJB4.ipa
zip -r rootlessJB4.ipa ./Payload/

rm -rf Payload
