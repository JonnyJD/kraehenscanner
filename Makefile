LEX    := flex
LFLAGS := 
CC     := gcc
CCW    := i486-mingw32-gcc
VERSION := 1.4.17
VERSIONSTRING := '"kskscanner - Version $(VERSION) vom 17.12.2013"'
CFLAGS := -Wall -pedantic -DVERSIONSTRING=$(VERSIONSTRING)

linux: bin/kskscanner

all: linux w32

w32: bin/kskscanner.exe

bin/kskscanner: src/kskscanner.o
	$(CC) $(CFLAGS) $^ -o $@

bin/kskscanner.exe: src/kskscanner.w32.o
	$(CCW) $(CFLAGS) $^ -o $@

src/kskscanner.w32.o: src/kskscanner.c
	$(CCW) $(CFLAGS) -c -o $@ $^

# wegen der Versionsnummer in der Makefile
src/kskscanner.c: Makefile

install-home: bin/kskscanner
	cp bin/kskscanner ~/bin
	sudo cp bin/kskscanner /srv/http/localhost/cgi-bin/

install-server: bin/kskscanner
	sudo cp bin/kskscanner /usr/lib/cgi-bin/

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

upload: packages
	export VERSION=$(VERSION) && ./upload

mostly-clean:
	rm -rf src/*.o src/kskscanner.c kskscanner/

clean: mostly-clean
	rm -rf bin/kskscanner bin/kskscanner.cgi bin/kskscanner.exe
