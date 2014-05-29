## How to set up

### SDKs

The latest Xcode version does not contain all the SDKs that RubyMotion supports.
These are generally not required for development anyways, but if you do need
them, you can download them all from [here](http://cat-soft.jp/share/SDKs.dmg) and install them like so:

* To install, for instance, the OS X 10.7 SDK:

     $ [sudo] cp -R /path/to/SDKs-Archive/MacOSX10.7.sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs

* To install, for instance, the iOS 6.1 SDK:

     $ [sudo] cp -R /path/to/SDKs-Archive/iPhoneSimulator6.1.sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs
     $ [sudo] cp -R /path/to/SDKs-Archive/iPhoneOS6.1.sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs


### Compilers

You need to have Xcode 5.1 installed as `/Applications/Xcode.app`.

You also need to have Xcode 5 installed as `/Applications/Xcode5.app`. Xcode 5 is only required to build kernel.c.

You also need to have Xcode 4 installed as `/Applications/Xcode4.app`. Xcode 4 is only required to build the REPL module.

You also need to have installed the latest version of the command-line tools. `/usr/bin/clang -v` should report the following:

```
Apple LLVM version 5.1 (clang-503.0.38) (based on LLVM 3.4svn)
Target: x86_64-apple-darwin13.1.0
Thread model: posix
```


### Special hacks

Mavericks only: the `/usr/lib/system/libdnsinfo.dylib` file has to exist in order to build the REPL module. The file can be found in the MacOSX 10.8 SDK (or earlier version) and can simply be copied in `/usr/lib/system`. Apparently there is no runtime dependency, so the file can be removed from the system and the RubyMotion REPL will still get to work as expected.


### External tools

You need to have [class-dump](https://github.com/nygard/class-dump) installed. This can be installed through [homebrew](https://github.com/mxcl/homebrew/wiki/Installation) with:

```
$ brew install class-dump
```


### Java for Android

When create a bridgesupport file for android, it requires Java SE 6 by Apple provided (not Oracle's Java SE 8)
You can get it from http://support.apple.com/kb/DL1572


### Clone RubyMotion source

```
$ git clone git@github.com:lrz/RubyMotion.git
```


### Set up LLVM

```
$ svn checkout https://llvm.org/svn/llvm-project/llvm/branches/release_33 llvm-3.3
$ cd llvm-3.3 
$ patch -p0 < /path/to/RubyMotionRepository/llvm.patch
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ MACOSX_DEPLOYMENT_TARGET=10.6 ./configure --enable-bindings=none --enable-optimized --with-llvmgccdir=/tmp
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ MACOSX_DEPLOYMENT_TARGET=10.6 make
$ sudo env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ MACOSX_DEPLOYMENT_TARGET=10.6 make install
```


### Set up RubyMotion

```
$ cd /path/to/RubyMotionRepository
$ git submodule update --init
$ cd vm; git checkout master; cd ..
$ bundle install
```


## How to debug on RubyMotion app

Build RubyMotion as following (enable `DEBUG` environment variable)

```
$ env DEBUG=true rake
$ sudo rake install
```

Debug on RubyMotion app

```
$ rake debug=1 no_continue=1
```

Or, debug on RubyMotion app in iOS device

```
$ rake device debug=1 no_continue=1
```

## How to build with Xcode Developer Preview

Download and install Xcode Developer Preview into /Applications folder.
And its folder would has three Xcode version (Xcode.app, Xcode4.app and Xcode51-DP.app)

Then, run

```
$ ./build.sh
```
