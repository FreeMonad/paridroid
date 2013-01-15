.PHONY: all libpari libpari-ndk ndk-modules paridroid clean uberclean

include ./Makefile.include

PARI_SRC=$(TOP)/pari
PARIDROID_SRC=$(TOP)/PariDroid
NDK_MODULES=$(TOP)/ndk-modules

all: libpari paridroid

ndk-modules: libpari-ndk

libpari-ndk: libpari
	mkdir -p $(NDK_MODULES)/pari/lib
	cp $(PARI_SRC)/Oandroid-arm/libpari.so $(NDK_MODULES)/pari/lib
	mkdir -p $(NDK_MODULES)/pari/include
	cp -r $(PARI_SRC)/Oandroid-arm/*.h $(NDK_MODULES)/pari/include
	cp -r $(PARI_SRC)/src/headers/*.h $(NDK_MODULES)/pari/include

libpari:
	cd $(PARI_SRC)/Oandroid-arm && make

paridroid: ndk-modules
	cd $(PARIDROID_SRC) && ant debug

clean:
	rm -f $(PARI_SRC)/pari.cfg
	cd $(PARIDROID_SRC) && ant clean

uberclean: clean
	rm -rf $(PARI_SRC)/android
	rm -rf $(NDK_MODULES)/pari/lib/*.so
	rm -rf $(NDK_MODULES)/pari/include/*.h
	cd $(PARI_SRC)/Oandroid-arm && make clean
