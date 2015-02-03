CC		= gcc
OBJECTS	= escalation.o
LIBS	= -L/usr/local/lib -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lm
PROJECT	= escalation

$(PROJECT): $(OBJECTS)
	$(CC) -Wall -g -o $(PROJECT) $(OBJECTS) $(LIBS)

escalation.o: escalation.c
	$(CC) -Wall -g -c $<

.PHONY: clean

clean:
	rm -fr $(PROJECT) $(OBJECTS)	