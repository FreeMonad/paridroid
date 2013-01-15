.PHONY: all libpari clean

include ./Makefile.include

PARI_SRC=$(TOP)/pari

all: libpari

libpari:
	cd $(PARI_SRC)/Oandroid-arm && make

ndk-modules: libpari-ndk

libpari-ndk: libpari
	mkdir -p $(TOP)/ndk-modules/libpari
	cp $(PARI_SRC)/Oandroid-arm/libpari.so $(TOP)/ndk-modules/libpari

clean:
	cd $(PARI_SRC)/Oandroid-arm && make clean
	rm -f $(PARI_SRC)/pari.cfg

uberclean: clean
	rm -rf $(PARI_SRC)/android

