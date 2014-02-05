#!/bin/sh

# EX)
#   ./build.sh clean:vm
#   ./build.sh
rake $*
SDK_BETA=1 XCODE_PLATFORMS_DIR=/Applications/Xcode51-Beta5.app/Contents/Developer/Platforms rake $*
