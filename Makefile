.PHONY: all apk paridroid libpari clean ndk-clean pari-clean uberclean

include ./Makefile.include

PARI_SRC=$(TOP)/pari
PARIDROID_SRC=$(TOP)/PariDroid
NDK_MODULES=$(PARIDROID_SRC)/jni

all: libpari paridroid

apk: paridroid
	cp $(PARIDROID_SRC)/bin/PariDroid-debug.apk $(TOP)/PariDroid.apk

paridroid: $(NDK_MODULES)/paridroid/org_freemonad_paridroid_PariNative.h
	cd $(NDK_MODULES) && $(NDK)/ndk-build V=1
	cd $(PARIDROID_SRC) && ant debug

$(NDK_MODULES)/paridroid/org_freemonad_paridroid_PariNative.h: libpari
	cd $(PARIDROID_SRC) && ant debug
	cd $(PARIDROID_SRC)/bin/classes && javah -jni org.freemonad.paridroid.PariNative
	mv $(PARIDROID_SRC)/bin/classes/org_freemonad_paridroid_PariNative.h $(NDK_MODULES)/paridroid/org_freemonad_paridroid_PariNative.h

libpari:
	cd $(PARI_SRC)/Oandroid-arm && make
	mkdir -p $(NDK_MODULES)/pari/lib
	cp $(PARI_SRC)/Oandroid-arm/libpari.so $(NDK_MODULES)/pari/lib
	mkdir -p $(NDK_MODULES)/pari/include
	cp -r $(PARI_SRC)/Oandroid-arm/*.h $(NDK_MODULES)/pari/include
	cp -r $(PARI_SRC)/src/headers/*.h $(NDK_MODULES)/pari/include

clean:
	rm -f $(TOP)/PariDroid.apk
	cd $(PARIDROID_SRC) && ant clean

ndk-clean:
	cd $(NDK_MODULES) && $(NDK_PATH)/ndk-build clean V=1

pari-clean: 
	rm -f $(PARI_SRC)/pari.cfg
	rm -rf $(PARI_SRC)/android
	cd $(PARI_SRC)/Oandroid-arm && make clean

uberclean: clean ndk-clean pari-clean
	rm -rf $(NDK_MODULES)/pari/lib/*.so
	rm -rf $(NDK_MODULES)/pari/include/*.h

