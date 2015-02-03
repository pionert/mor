PROJECT  = mor_system_monitor
LIBS	 = -lcurl
INCL	 = -I/usr/include
FLAG	 = -Wall -g -std=c99
CC		 = gcc

$(PROJECT): $(PROJECT).o
	$(CC) $(FLAG) -o $(PROJECT) $(PROJECT).o $(LIBS)

$(PROJECT).o: $(PROJECT).c
	$(CC) $(FLAG) -c $< 

.PHONY: clean

clean:
	rm -fr $(PROJECT) $(PROJECT).o
