## How to set up
### Set up LLVM

```
$ curl -O http://llvm.org/releases/2.9/llvm-2.9.tgz
$ tar xvzf llvm-2.9.tgz
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ ./configure --enable-bindings=none --enable-optimized --with-llvmgccdir=/tmp
$ env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make
$ sudo env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make install
```

Then,

```
$ cp /Library/RubyMotion/bin/llc /usr/local/bin/
```

### Set up RubyMotion
```
$ git clone git@github.com:lrz/RubyMotion.git
$ cd RubyMotion
$ git submodule init
$ git submodule update
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
```

At last, debug on RubyMotion app

```
$ rake debug=1 no_continue=1
```