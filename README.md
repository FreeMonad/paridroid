PariDroid
=========

Pari/GP for Android.

Setting Up
==========

First, clone the PariDroid git repository.

       git clone https://github.com/FreeMonad/paridroid.git

You will need to download the Android SDK Tools and the Android NDK to compile. These can be downloaded from the Android Developer website.

Note that the ADT package is not necessary (unless you want to use Eclipse), you just need the SDK tools and the NDK.

It is recommended to extract the Android SDK (resp. NDK) tarball into =$HOME/opt/android/sdk= (resp. =$HOME/opt/android/ndk= ), then place the following in your =~/.bashrc= file:

   export SDK=$HOME/opt/android/sdk/android-sdk-linux
   export NDK=$HOME/opt/android/ndk/android-ndk-r8d
   
   alias android=$SDK/tools/android

Then run then =android= command and install at least one Android platform to target. If you need a default, then pick =android-4=.

Now clone the Pari/GP source code into a subdirectory =paridroid/pari=.

    git clone http://pari.math.u-bordeaux.fr/git/pari.git

Finally, turn the =paridroid/PariDroid= directory in to a proper android project:

	 cd paridroid/PariDroid
	 android update project -p . -t android-4

For more information, see the Android documentation and manual pages.

Building
========

First, configure the sources and prepare to compile.

       cd paridroid
       perl configure.pl $NDK

This should create (non-empty) directories =paridroid/pari/android/android-toolchain= and =paridroid/pari/Oandroid-arm=.

Now we can compile with =make=.