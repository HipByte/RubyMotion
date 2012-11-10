#!/bin/sh

git clone git://github.com/lsegal/ripper18.git
cd ripper18
git checkout refs/tags/1.0.5
/usr/bin/rake build
mkdir -p ../lib/ripper18
cp -R lib/ ../lib/ripper18
cp ext/ripper.bundle ../lib/ripper18