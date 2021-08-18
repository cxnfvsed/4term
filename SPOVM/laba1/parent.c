#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>


int main()
{
    fprintf(stdout,"parent process called\n");
    pid_t pid;
    int cstatus;
    pid = fork();
    if(pid == -1)
    {
        fprintf(stdout,"Error - %d\n",errno);
    }
    if(pid == 0)
    {
        execve("./child",NULL,NULL);
    }
    fprintf(stdout,"Parent process running\n");
    wait(&cstatus);
    fprintf(stdout,"Child process executed with code %d\n", cstatus);
    exit(0);
}

