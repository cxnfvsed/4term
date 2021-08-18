#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

int main()
{
    fprintf(stdout, "child process is called\n");
    fprintf (stdout,"Type in q to exit: ");
    while(getc(stdin)!= (int)'\n');
    exit(0);
}
