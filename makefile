LEX    := flex
LFLAGS := 
CC     := gcc
CCW    := i486-mingw32-gcc
VERSION := 1.4.1
VERSIONSTRING := '"kskscanner - Version $(VERSION) vom 14.9.2008"'
CFLAGS := -Wall -pedantic -DVERSIONSTRING=$(VERSIONSTRING)

linux: bin/kskscanner

all: linux static w32

static: bin/kskscanner.cgi

w32: bin/kskscanner.exe

bin/kskscanner: src/kskscanner.o
	$(CC) $(CFLAGS) $^ -o $@

bin/kskscanner.cgi: src/kskscanner.o
	$(CC) $(CFLAGS) --static $^ -o $@


bin/kskscanner.exe: src/kskscanner.w32.o
	$(CCW) $(CFLAGS) $^ -o $@

src/kskscanner.w32.o: src/kskscanner.c
	$(CCW) $(CFLAGS) -c -o $@ $^

install:
	cp bin/kskscanner ~/bin

packages: kskscanner-$(VERSION).src.tgz kskscanner-$(VERSION).w32.zip

kskscanner-$(VERSION).src.tgz:
	make clean
	mkdir kskscanner
	cp -a src kskscanner
	cp makefile kskscanner
	tar -cvzf $@ kskscanner

kskscanner-$(VERSION).w32.zip: bin/kskscanner.exe
	make clean
	mkdir kskscanner
	cp -a src kskscanner
	cp makefile kskscanner
	cp $^ kskscanner
	cp kskscanner.bat kskscanner
	zip -r $@ kskscanner

upload: kskscanner-$(VERSION).src.tgz kskscanner-$(VERSION).w32.zip
	./upload

clean:
	rm -rf src/*.o src/kskscanner.c bin/kskscanner bin/kskscanner.cgi bin/kskscanner.exe
