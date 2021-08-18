#include <signal.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>

static int signal1 = 0;
static int signal2 = 0;
static int signal3 = 0;

void signal_handler(int signal);


int main()
{
    fprintf(stdout,"child process is called\n");
    int time = 0;
    FILE *file;
    if ((file = tmpfile()) == NULL)
    {
        perror("(child issue)File wasn't created!\n");
        exit(errno);
    }

    struct sigaction new_action;//объявляем объект структуры для расширенной обработки сигналов
    new_action.sa_handler = SIG_IGN;//установка обработчика сигнала SIGINT
    sigemptyset(&new_action.sa_mask);//инициализируем набор сигналов
    new_action.sa_flags = 0;
    if (sigaction(SIGINT,&new_action,NULL) == -1) //если сигнал игнорируется - ошибка
    {
        perror("(child issue)SIGINT error\n");
        exit(errno);
    }
    new_action.sa_handler = signal_handler;//установка обработчика сигнала SIGALRM
    sigemptyset(&new_action.sa_mask);//инициализируем набор сигналов
    new_action.sa_flags = 0;
    sigaction(SIGALRM, &new_action, NULL);
    if (new_action.sa_handler == SIG_IGN) //если сигнал игнорируется - ошибка
    {
        perror("(child issue)SIGALRM error!\n");
        exit(errno);
    }

    new_action.sa_handler = signal_handler; //установка обработчика сигнала SIGUSR1
    sigemptyset(&new_action.sa_mask); //инициализируем набор сигналов
    new_action.sa_flags = 0;
    if (sigaction(SIGUSR1, &new_action, NULL) == -1) //если сигнал игнорируется - ошибка
    {
        perror("SIGUSR1 error\n");
        exit(errno);
    }

    new_action.sa_handler = signal_handler;//установка обработчика сигнала SIGUSR2
    sigemptyset(&new_action.sa_mask);//инициализируем набор сигналов
    new_action.sa_flags = 0;
    sigaction(SIGUSR2, &new_action, NULL);
    if (new_action.sa_handler == SIG_IGN) //если сигнал игнорируется - ошибка
    {
        perror("SIGUSR2 error\n");
        exit(errno);
    }

    while(signal3 != 1)
    {
        alarm(1); //установка будильника на 1с
        while(signal1 != 1)
        {
            pause();
        }
        fprintf(file, "%d seconds passed\n", time);
        time++;
        signal1 = 0;
        if(signal2 == 1){
            printf("%d\n", time);
            signal2 = 0;
        }
    }
    alarm(0);
    printf("child process is done\n");
    fclose(file);
    exit(0);
    return 0;
}


void signal_handler(int signal){
    if(signal == SIGALRM)  // сигнал обычно указывает на истечение таймера
    {
        signal1 = 1;
    }
    if(signal == SIGUSR1) //пользовательские сигналы
    {
        signal2 = 1;
    }
    if(signal == SIGUSR2) //пользовательские сигналы
    {
        signal3 = 1;
    }
}
