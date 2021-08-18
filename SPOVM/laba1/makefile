.PHONY:start
.PHONY:clean

start:	parent.c	child.c
	gcc -w -Wall -Wextra -o parent parent.c
	gcc -w -Wall -Wextra -o child child.c

clean:
	rm -rf *.o parent
	rm -rf *.o child
