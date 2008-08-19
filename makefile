LEX    := flex
LFLAGS := 
CC     := gcc
CCW    := i486-mingw32-gcc
CFLAGS := -Wall -pedantic

bin/kskscanner: src/kskscanner.o
	$(CC) $(CFLAGS) $^ -o $@

w32: bin/kskscanner.exe

bin/kskscanner.exe: src/kskscanner.w32.o
	$(CCW) $(CFLAGS) $^ -o $@

src/kskscanner.w32.o: src/kskscanner.c
	$(CCW) $(CFLAGS) -c -o $@ $^

install:
	cp bin/kskscanner ~/bin

packages: kskscanner.src.tgz kskscanner.w32.zip

kskscanner.src.tgz:
	make clean
	mkdir kskscanner
	cp -a src kskscanner
	cp makefile kskscanner
	tar -cvzf $@ kskscanner

kskscanner.w32.zip: bin/kskscanner.exe
	make clean
	mkdir kskscanner
	cp -a src kskscanner
	cp makefile kskscanner
	cp $^ kskscanner
	cp kskscanner.bat kskscanner
	zip -r $@ kskscanner

upload: kskscanner.src.tgz kskscanner.w32.zip
	./upload

clean:
	rm -rf src/*.o src/kskscanner.c kskscanner
