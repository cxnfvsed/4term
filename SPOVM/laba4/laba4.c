#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <stddef.h>
#include <sys/types.h>
#include <errno.h>
#include <sys/wait.h>


static int clockCounter=0;
static int exit_code = 1;
static int sigusr1 =0;
static int sigusr2=0;
static int alarm_clock = 1;

void alarm_signal(int sig);
void check_signal(int sig);
void* child_processing();

int main() {
    fprintf(stdout, "parent process is running.\n");

    int status;
    struct sigaction new_action;
    pthread_t pthread;

    int childThreadStatus; //thread status
    void* childAddress = &childThreadStatus;

    if (pthread_create(&pthread, NULL, child_processing, NULL) == 0) {
        printf("child process is started by the parent\n");
    } else {
        printf("error in pthread_create.(parent error)\n");
        exit(errno);
    }

    new_action.sa_handler = alarm_signal;
    sigemptyset(&new_action.sa_mask);
    new_action.sa_flags = 0;
    sigaction(SIGALRM, &new_action, 0);
    if (new_action.sa_handler==SIG_IGN) {
        printf("error in sigaction - SIGALRM.(parent error)\n");
        exit(errno);
    }

    new_action.sa_handler = alarm_signal;
    sigemptyset(&new_action.sa_mask);
    new_action.sa_flags = 0;
    if (sigaction(SIGINT, &new_action, 0) == -1) {
        printf("error in sigaction - SIGINT.(parent error)\n");
        exit(errno);
    }

    int error_thread;
    sigset_t signal_set;
    sigemptyset(&signal_set);
    sigaddset(&signal_set, SIGUSR1);
    sigaddset(&signal_set, SIGUSR2);

    error_thread = pthread_sigmask(SIG_BLOCK, &signal_set, NULL);

    if (error_thread != 0) {
        printf("error in thread_sigmask.(parent error)\n");
        exit(errno);
    }

    int flg = 5;
    while(exit_code) {
        flg = 5;
        while(flg) {
            flg--;
            alarm(1);
            while(alarm_clock != 0) {
                pause();
            }
            alarm_clock = 1;
            if(exit_code == 0) flg = 0;
        }
        if (pthread_kill(pthread, SIGUSR1) !=0 ) {
            printf("error in pthread_kill - SIGUSR1.(parent error)\n");
            exit(errno);
        }
    }

    alarm(0);
    if (pthread_kill(pthread, SIGUSR2) != 0) {
        printf("error in pthread_kill - SIGUSR2.(parent error)\n");
        exit(errno);
    }


    error_thread = pthread_join(pthread, &childAddress);
    if (error_thread != 0) {
        printf("error in pthread_join.(parent error)\n\n");
        exit(errno);
    }

    wait(&status);
    printf("parent process terminated.\n");
    printf("exit with status - %d\n", status);
    exit(0);
}

void alarm_signal(int sig){
    if(sig==SIGALRM){
        printf(".\n");
        clockCounter++;
        alarm_clock=0;
    }
    if(sig==SIGINT) exit_code =0;
}

void check_signal(int sig){
    if(sig==SIGUSR1) sigusr1=1;
    if(sig==SIGUSR2) sigusr2=1;
}

void* child_processing() {
    FILE *file;
    fprintf(stdout, "child process is running.\n");
    file = tmpfile();
    if (file==NULL) {
        perror("file wasn't created.(child error)\n");
        exit(errno);
    }

    struct sigaction new_action1;
    int error_thread;
    sigset_t signal_set;

    sigemptyset(&signal_set);
    sigaddset(&signal_set, SIGALRM);
    sigaddset(&signal_set, SIGINT);

    error_thread = pthread_sigmask(SIG_BLOCK, &signal_set, NULL);
    if (error_thread != 0) {
        printf("error in thread_sigmask.(child error)\n");
        exit(errno);
    }

    new_action1.sa_handler = check_signal;
    sigemptyset(&new_action1.sa_mask);
    new_action1.sa_flags = 0;
    sigaction(SIGUSR1, &new_action1, NULL);
    if ( new_action1.sa_handler==SIG_IGN) {
        perror("error in sigaction - SIGUSR1.(child error)\n");
        exit(errno);
    }

    new_action1.sa_handler = check_signal;
    sigemptyset(&new_action1.sa_mask);
    new_action1.sa_flags = 0;
    sigaction(SIGUSR2, &new_action1, NULL);
    if  (new_action1.sa_handler == SIG_IGN) {
        perror("error in sigaction - SIGUSR2.(child error)\n");
        exit(errno);
    }

    while (sigusr2 != 1) {
        fputc('.', file);

        if (sigusr1 == 1) {
            printf("Temporary file : %d symbols\n", clockCounter);
            sigusr1 = 0;
        }
    }

    if (fclose(file) == EOF) {
        printf("file wasn't close.(child error)\n");
        exit(errno);
    }

    printf("child process terminated.\n");
    pthread_exit(0);
}

