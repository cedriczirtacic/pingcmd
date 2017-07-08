CC=gcc
CFLAGS=-Wall -O1

all: clean pingcmd

pingcmd: 
	$(CC) $(CFLAGS) -o pingcmd pingcmd.c

clean:
	rm -f pingcmd
