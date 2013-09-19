## How to set up
### Set up LLVM

```
$ svn checkout https://llvm.org/svn/llvm-project/llvm/branches/release_33 llvm-3.3
$ cd llvm-3.3 
$ patch -p0 < /path/to/RubyMotionRepository/llvm.diff
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ ./configure --enable-bindings=none --enable-optimized --with-llvmgccdir=/tmp
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make
$ sudo env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make install
```

### Set up RubyMotion
```
$ git clone git@github.com:lrz/RubyMotion.git
$ cd RubyMotion
$ git submodule init
$ git submodule update
$ cd vm; git checkout master; cd ..
$ bundle install
```


## How to debug on RubyMotion app
First, comment out `[ios, sim].map ...` (line 31) in `data/Rakefile` as following:

```ruby
 29     # remove debug symbols
 30     strip = File.join(PLATFORMS_DIR, '../usr/bin/strip')
 31     # [ios, sim].map { |x| Dir.glob(x + '/*.{a,dylib}') }.flatten.each { |x| sh("\"#{strip}\" -S \"#{x}\"") }
```

Then, build RubyMotion

```
$ rake optz_level=0
$ sudo rake install
```

At last, debug on RubyMotion app

```
$ rake debug=1 no_continue=1
```

Or, debug on RubyMotion app in iOS device

```
$ rake device debug=1 no_continue=1
```
