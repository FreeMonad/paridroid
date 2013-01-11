.PHONY: all libpari clean

include ./Makefile.include

PARI_SRC=$(TOP)/pari

all: libpari

libpari:
	cd $(PARI_SRC)/Oandroid-arm && make
	mkdir $(TOP)/gen
	cp $(PARI_SRC)/Oandroid-arm/libpari.so $(TOP)/gen
	cp $(PARI_SRC)/Oandroid-arm/gp-dyn $(TOP)/gen

clean:
	cd $(PARI_SRC)/Oandroid-arm && make clean

uberclean: clean
	rm -rf $(TOP)/gen

