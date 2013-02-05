#!/bin/sh

# get libedit tarball from http://opensource.apple.com/release/mac-os-x-1068/
curl -O http://opensource.apple.com/tarballs/libedit/libedit-13.tar.gz

tar xzf libedit-13.tar.gz
cd libedit-13
xcodebuild

cp build/Release/libedit.2.dylib ../bin
ln -s ../bin/libedit.2.dylib ../bin/libedit.dylib
