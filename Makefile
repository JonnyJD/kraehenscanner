LEX    := flex
LFLAGS := 
CC     := gcc
CCW    := i486-mingw32-gcc
VERSION := 1.4.2
VERSIONSTRING := '"kskscanner - Version $(VERSION) vom 29.9.2008"'
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

install: bin/kskscanner
	cp bin/kskscanner ~/bin

packages: kskscanner-$(VERSION)-w32.zip kskscanner-$(VERSION)-src.tgz

kskscanner-$(VERSION)-src.tgz:
	make mostly-clean
	mkdir kskscanner
	cp -a src kskscanner
	cp Makefile kskscanner
	tar -cvzf $@ kskscanner

kskscanner-$(VERSION)-w32.zip: bin/kskscanner.exe
	make mostly-clean
	mkdir kskscanner
	cp -a src kskscanner
	cp Makefile kskscanner
	cp $^ kskscanner
	cp kskscanner.bat kskscanner
	zip -r $@ kskscanner

upload: static packages
	./upload

mostly-clean:
	rm -rf src/*.o src/kskscanner.c kskscanner/

clean: mostly-clean
	rm -rf bin/kskscanner bin/kskscanner.cgi bin/kskscanner.exe
