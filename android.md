# RubyMotion for Android: Getting Started

Thanks for taking the time to test the beta of RubyMotion for Android.

At the time of this writing, it is still under heavy development. You should expect bugs, missing features and rough edges. Please report any issue you will find so that we can make sure it will be ready for prime time.

## Setting up the environment

Please follow the steps to set up a working RubyMotion for Android development environment.

If you have done these steps already, there is no need to do them again when you get to try a new build of RubyMotion for Android.

**Important:** even if it's not technically necessary, RubyMotion for Android requires a Mac environment for now.

### Installing Java

The RubyMotion build system requires a Java compiler to be installed. By default, OS X does not come with Java.

Follow the steps [on this page](http://support.apple.com/kb/DL1572) to get Java installed on your environment. 

After doing that you can verify that Java has been properly installed:

<pre>
$ javac -version
javac 1.6.0_65
</pre>

Java 1.7 should work but we recommend sticking to Java 1.6.

### Downloading the Android SDK

Download the [Eclipse ADT](http://developer.android.com/sdk/index.html) bundle from the official Android website. You will have to accept the terms of conditions before the download.

Despite its name, the Android SDK resides within this bundle.

Once downloaded, open the .zip file. You will see 2 directories inside, `eclipse` and `sdk`. The later is the one that RubyMotion will need.

We recommend that you copy the `sdk` directory somewhere in your home directory. In this document we will use `~/android-rubymotion`.

<pre>
$ mkdir ~/android-rubymotion
$ cp -r ~/Downloads/adt-bundle-mac-x86_64-20140702/sdk ~/android-rubymotion
</pre>

Once you do that make sure the `~/android-rubymotion/sdk` directory has been properly copied. This is what it should contain (at the time of this writing):

<pre>
$ ls ~/android-rubymotion/sdk 
build-tools	extras		platform-tools	platforms	tools
</pre> 

Unless you plan to use Eclipse (haha), you can safely delete the .zip file as well as the directory that was extracted from it.

### Setting up the Android SDK

Now that the Android SDK has been copied, you still need to set it up by downloading internal packages. Run the `android` tool:

<pre>
$ ~/android-rubymotion/sdk/tools/android
</pre>

This will pop up a window titled "*Android SDK Manager* with a selection of packages that should be installed. Click the *Install* button and wait until it's done. It can take some time.

### Downloading the Android NDK

Download the [Mac OS X 64-bit NDK](https://developer.android.com/tools/sdk/ndk/index.html) package from the official Android website. You will have to accept the terms of conditions before the download.

Once downloaded, open the .tar.bz2 file, then copy its content inside `~/android-rubymotion` under the `ndk` directory:

<pre>
$ cp -r ~/Downloads/android-ndk-r10 ~/android-rubymotion/ndk
</pre>

To confirm that the copy was successful, this is what it should contain (at the time of this writing):

<pre>
$ ls ~/android-rubymotion/ndk
GNUmakefile			ndk-gdb-py.cmd
README.TXT			ndk-gdb.py
RELEASE.TXT			ndk-stack
build				ndk-which
docs				platforms
documentation.html		prebuilt
find-win-host.cmd		remove-windows-symlink.sh
ndk-build			samples
ndk-build.cmd			sources
ndk-depends			tests
ndk-gdb				toolchains
ndk-gdb-py
</pre>

After that, you can safely delete the .tar.bz2 file as well as the directory that was extracted from it.

### Configuring RubyMotion for Android

We are almost finished! It is now time to point RubyMotion to the Android SDK and NDK directories.

Add the following lines to your `~/.profile` file (you can create the file if it does not exist yet):

<pre>
export RUBYMOTION_ANDROID_SDK=~/android-rubymotion/sdk
export RUBYMOTION_ANDROID_NDK=~/android-rubymotion/ndk
</pre>

Once done, restart your terminal so that these environmental changes are taken into account.

You can verify that the environment variables are properly set:

<pre>
$ env | grep RUBYMOTION_ANDROID
RUBYMOTION_ANDROID_SDK=...
RUBYMOTION_ANDROID_NDK=...
</pre>

### Configuring your Android device for development

You will need a functional Android device configured for development when writing Android apps in RubyMotion. (The provided emulator is way too slow.)

In case you haven't done it already, make sure your device is connected to your Mac via a USB cable, then perform the following steps:

1. Open the **Settings** app.
2. Scroll down and tap on the **About phone** or **About tablet** item, depending of the type of the device you are using. This will open a new screen.
3. Scroll down again and tap 7 times on the **Build number** item. A message should appear after that, clarifying that you are now a developer (well, that was easy?).
4. Go back to the previous screen and scroll down again, a **Developer options** item is now available. Tap on it.
5. Check the **USB debugging** item. This will allow your Mac to communicate with the device for development tasks. A window will appear on the device, asking you to authorize the Mac. Make sure to confirm that.

You should now be good to go!

If you are running an older version of Android these steps might not work for you. We recommend that you do a Google search for *enable developer mode* with your Android version number.

At the time of this writing, the devices where RubyMotion is known to run are:

- Nexus 5
- Nexus 7
- Samsung Galaxy S2
- Samsung Galaxy Note
- Motorola G
- Motorola DEFY

## Getting started

Let's create a *Hello World* app.

Go to a directory of your choice, then create a new project.

<pre>
$ cd /tmp
$ motion create --template=android Hello
$ cd Hello
</pre>

A new `Hello` directory has been created. Check out the `Rakefile` and the `app/main_activity.rb` files. 

You can try to run the app on your device.

<pre>
$ rake device
</pre>

The app should start right away (make sure you unlocked the device screen first). The window should be blank. If you hit ^C on the terminal the app should quit.

Now, edit the `app/main_activity.rb` file so that it includes the following code.

<pre>
class MainActivity < Android::App::Activity
  def onCreate(savedInstanceState)
    puts "Hello World!"
    super
    view = Android::Widget::TextView.new(self)
    view.text = "Hello World!"
    self.contentView = view
  end
end
</pre>

If you run `rake device` again, you should see the hello world message appearing on your device. Also, the same message will be printed on your terminal (due to the `#puts` call).

Here you go, Hello World in Android with RubyMotion!

## Current Status

Following is the current status of RubyMotion for Android. Keep in mind that this is still a work in progress.

### Android

The following Android API levels are supported: 3, 4, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 and L (soon-to-be 20). You can find more information about Android API levels (and especially which versions of Android they relate to) from [this page](http://developer.android.com/guide/topics/manifest/uses-sdk-element.html).

RubyMotion is known to work on both Dalvik and ART. However we do recommend developing and testing on Dalvik.

### Toolchain

- The REPL is not available yet.
- The debugger interface is not available yet.

### Runtime

The following classes are fully implemented:

- `NilClass`
- `TrueClass` / `FalseClass`
- `Fixnum`
- `Float`

The following classes are partially implemented:

- `Object` is missing too many methods.
- `Bignum` is missing the following methods: coerce -@ % div divmod modulo remainder fdiv ** & | ^ ~ << >> [] <=> eql?  to_f abs size odd?  even?
- `Proc` is missing the following methods: [] === yield to_proc arity clone dup == eql?  hash to_s lambda?  binding curry
- `Array` is missing the following methods: \#[] \#try_convert initialize initialize_copy eql?  at fetch concat push pop shift unshift insert each_index reverse_each length size empty?  find_index index rindex reverse reverse!  sort sort!  sort_by!  collect collect!  map map!  select select!  keep_if values_at delete delete_at delete_if reject reject!  replace clear include?  slice slice!  + * uniq uniq!  compact compact!  count shuffle!  shuffle take take_while drop drop_while
- `String` is missing the following methods: \#try_convert replace clear encoding empty?  bytesize getbyte setbyte to_data pointer force_encoding valid_encoding?  ascii_only?  [] []= slice slice!  insert index rindex * << concat <=> casecmp eql?  include?  start_with?  end_with?  to_str intern dump split to_i hex oct ord chr to_f chomp chomp!  chop chop!  sub sub!  gsub gsub!  downcase downcase!  upcase upcase!  swapcase swapcase!  capitalize capitalize!  ljust rjust center strip lstrip rstrip strip!  lstrip!  rstrip!  lines each_line chars each_char bytes each_byte codepoints each_codepoint succ succ!  next next!  upto reverse reverse!  count delete delete!  squeeze squeeze!  tr tr!  tr_s tr_s!  sum partition rpartition crypt transform
- `Hash` is missing the following methods: \#[] \#try_convert rehash to_hash to_a eql?  fetch store default default= default_proc default_proc= key index size length empty?  each_value each_key each_pair each values_at shift delete delete_if keep_if select select!  reject reject!  clear invert update replace merge!  merge assoc rassoc flatten include?  member?  has_key?  has_value?  key?  value?  compare_by_identity compare_by_identity?
- `Thread` is missing the following methods: \#fork \#main \#stop \#kill \#exit \#pass \#list \#abort_on_exception \#abort_on_exception= raise join value kill terminate exit run wakeup [] []= key?  keys priority priority= status alive?  stop?  abort_on_exception abort_on_exception= safe_level group
- `Regexp` is missing the following methods: \#compile \#quote \#escape \#union \#last_match \#try_convert eql?  ~ === source casefold?  options fixed_encoding?  encoding names named_captures
- `MatchData` is missing the following methods: regexp names size length offset begin end captures values_at pre_match post_match to_s string inspect eql?  ==

The following classes are not implemented yet:

- `Binding`
- `Encoding`
- `Enumerator`
- `Math`
- `Method` / `UnboundMethod`
- `Mutex`
- `Time`
- `File` / `Dir` / `IO`
- `ThreadGroup`
- `ObjectSpace`
- `Process`
- `Range`
- `Rational`
- `Struct`

The following classes will probably not be implemented:


## Additional resources

Check the [samples](https://github.com/HipByte/RubyMotionSamples/tree/master/android) repository for sample code. Feel free to contribute new samples too.

We are working on a proper runtime and project management guide for the toolchain. Stay tuned.

## Report issues

Please report all issues you will find on our [bug tracker](http://hipbyte.myjetbrains.com/youtrack/issues/RM). You will have to create an account to do so, then request *reporter* privileges (send us an [email](mailto:info@hipbyte.com) for that).

When creating an issue, please assign *Android* as the *Component* field.