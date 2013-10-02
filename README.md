## How to set up

### SDKs

Xcode 5 does not include the OS X 10.7 SDK, nor the full iOS 6.1 SDK.

* To install the OS X 10.7 SDK, [download Xcode 4.3.3](https://developer.apple.com/downloads/index.action)
  and copy the SDK to Xcode 5. E.g.:

     $ [sudo] cp -R /Volumes/Xcode/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs

* To install the iOS 6.1 SDK, [download Xcode 4.6.3](https://developer.apple.com/downloads/index.action)
  and copy the SDK to Xcode 5. E.g.:

     $ [sudo] cp -R /Volumes/Xcode/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs

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
$ DEBUG=true rake
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
