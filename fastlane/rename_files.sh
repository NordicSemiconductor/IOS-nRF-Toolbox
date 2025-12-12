#!/bin/bash

cd screenshots/en-US
for file in "iPad Air 13-inch (M3)"*; do
    new="${file/iPad Air 13-inch (M3)/APP_IPAD_PRO_3GEN_129}"
    mv "$file" "$new"
done
