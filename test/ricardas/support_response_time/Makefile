CC		= gcc
OBJECTS	= support_response_time.o
LIBS	= -L/usr/lib -L/usr/lib/mysql -lmysqlclient -lm
PROJECT	= support_response_time

$(PROJECT): $(OBJECTS)
	$(CC) -Wall -g -o $(PROJECT) $(OBJECTS) $(LIBS)

support_response_time.o: support_response_time.c
	$(CC) -Wall -g -c $<

.PHONY: clean

clean:
	rm -fr $(PROJECT) $(OBJECTS)	