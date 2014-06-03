#!/bin/sh

# EX)
#   ./build.sh clean:vm
#   ./build.sh
rake $*
SDK_BETA=1 XCODE_PLATFORMS_DIR=/Applications/Xcode6-Beta.app/Contents/Developer/Platforms rake $*
