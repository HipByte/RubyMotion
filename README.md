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


### Compilers

You need to have Xcode 5 installed as `/Applications/Xcode.app`.

You also need to have Xcode 4 installed as `/Applications/Xcode4.app`. Xcode 4 is only required to build the REPL module.

You also need to have installed the latest version of the command-line tools. `/usr/bin/clang -v` should report the following:

```
Apple LLVM version 5.0 (clang-500.2.75) (based on LLVM 3.3svn)
Target: x86_64-apple-darwin12.4.1
Thread model: posix
```


### Special hacks

Mavericks only: the /usr/lib/system/libdnsinfo.dylib file has to exist in order to build the REPL module. The file can be found in the MacOSX 10.8 SDK (or earlier version) and can simply be copied in /usr/lib/system. Apparently there is no runtime dependency, so the file can be removed from the system and the RubyMotion REPL will still get to work as expected.

Edit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator{6.0,6.1}.sdk/System/Library/Frameworks/CoreText.framework/Headers/CTRunDelegate.h and comment the declaration of CTRunDelegateGetTypeID(). This function is not exported, the symbol is missing, and it's a bug in iOS.

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
