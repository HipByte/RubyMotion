## How to set up

### SDKs

The latest Xcode version does not contain all the SDKs that RubyMotion supports.
These are generally not required for development anyways, but if you do need
them, you can download them all from [here](#TODO) and install them like so:

* To install, for instance, the OS X 10.7 SDK:

     $ [sudo] cp -R /path/to/SDKs-Archive/MacOSX10.7.sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs

* To install, for instance, the iOS 6.1 SDK:

     $ [sudo] cp -R /path/to/SDKs-Archive/iPhoneSimulator6.1.sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs
     $ [sudo] cp -R /path/to/SDKs-Archive/iPhoneOS6.1.sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs


### Clone RubyMotion source

```
$ git clone git@github.com:lrz/RubyMotion.git
```


### Set up LLVM

```
$ svn checkout https://llvm.org/svn/llvm-project/llvm/branches/release_33 llvm-3.3
$ cd llvm-3.3 
$ patch -p0 < /path/to/RubyMotionRepository/llvm.patch
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ ./configure --enable-bindings=none --enable-optimized --with-llvmgccdir=/tmp
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make
$ sudo env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make install
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
