#!/bin/bash

md5=$(md5sum <<< "dummy" | awk '{print $1}')
sha256=$(sha256sum <<< "dummy" | awk '{print $1}')

sed \
    --regexp-extended \
    --expression "s/\b[[:alnum:]]{32}\b/$md5/g" \
    --expression "s/\b[[:alnum:]]{64}\b/$sha256/g" \
    --expression "s/ip=[0-9\.]+;/ip=8.8.8.8;/g"
