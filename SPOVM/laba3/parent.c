#include <signal.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/wait.h>

static int clock = 1;
static int exit_code = 1;

void _alarm(int signal);
int exceve (const char *pathname,char *const argv[],char * const envp[]);

int main(int argc,char **argv)
{

    int flag = 5;
    pid_t pid;
    int state;

    struct sigaction new_action;

    new_action.sa_handler = _alarm;//установка обработчика сигнала SIGINT
    sigemptyset(&new_action.sa_mask);//инициализируем набор сигналов
    new_action.sa_flags = 0;
    sigaction(SIGINT, &new_action, NULL);
    if (new_action.sa_handler == SIG_IGN) //если сигнал игнорируется - ошибка
    {
        perror("(parrent issue)SIGINT error\n");
        exit(errno);
    }

    fprintf(stdout, "parent process is called\n");

    new_action.sa_handler = _alarm;//установка обработчика сигнала SIGALRM
    sigemptyset(&new_action.sa_mask);//инициализируем набор сигналов
    new_action.sa_flags = 0;
    sigaction(SIGALRM, &new_action, NULL);
    if ( new_action.sa_handler == SIG_IGN) //если сигнал игнорируется - ошибка
    {
        perror("(parrent issue)SIGALRM error\n");
        exit(errno);
    }

    fprintf(stdout, "child process is started by parent\n");
    //создаем дочерний процесс
    pid = fork();
    if (pid == -1)
    {
        perror("fork() error\n"); //если не создался,выводим сообщения об ошибке
                                    //родителю возвращается -1
        exit(errno);
    }
    if (pid == 0)
    {
        if (execve("./child", argv, NULL) == -1)
        {
            perror("execve() error\n");
            exit(errno);
        }
    }

    while(exit_code)
    {
        flag = 5;
        while(flag)
        {
            flag--;
            alarm(1);//устанавливаем будильник на 1 секунду
            while(clock != 0)
            {
                pause();
            }
            clock = 1;
            if(exit_code == 0)
            {
                flag = 0;
            }
        }
        kill(pid, SIGUSR1); //завершаем процесс SIGUSR1
    }

    alarm(0);
    kill(pid, SIGUSR2);//завершаем процесс SIGUSR2
    wait(&state);
    printf("parent process is done\n");
    printf("status - %d\n",state);

    return 0;
}


void _alarm(int signal) //вывод точки
{
    if(signal == SIGALRM)
    {
        printf(".\n");
        clock = 0;
    }
    if(signal == SIGINT)
    {
        exit_code = 0;
    }
}
