#define _POSIX_C_SOURCE 200809L
#include <pthread.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <limits.h>

long int process_int_arg(char* arg, const char* error_msg);
int compare_ints(const void* a, const void* b);
static void* thread(void* arg);

// аргумент для thread()
struct thread_info {       
    pthread_t           thread_id;  
    int                 thread_num;
    char**              address_pointer;
    int                 chunk_size;
    int*                block_size;
    int*                last_round_flag;
    pthread_barrier_t*  b1;
    pthread_barrier_t*  b2;
};

int main(int argc, char *argv[]) {
    long int pageNumber = 1;
    long int threadNumber = 20;

    // Анализируем командную строку
    if (argc < 2 || argc > 4) {
        fprintf(stderr, "format: file [number of threads] [pages]\n");
        exit(EXIT_FAILURE);
    }
    
    if (argc > 2) {
        threadNumber = process_int_arg(argv[2], "threadNumber");
    }
    if (argc > 3) {
        pageNumber = process_int_arg(argv[3], "pageNumber");
    }

    int page_size = sysconf(_SC_PAGE_SIZE);
    int chunk_size = pageNumber * page_size;
    int block_size = chunk_size * threadNumber;
   

    int file_descriptor = open(argv[1], O_RDWR);
    if (file_descriptor == -1)
        printf("open file");

    // Получаем размер файла
    struct stat file_stat;
    if (fstat(file_descriptor, &file_stat) == -1) {
        printf("fstat");
    }
    int status;
    // Инициализируем барьеры
    pthread_barrier_t b1;
    pthread_barrier_t b2;

    if ((pthread_barrier_init(&b1, NULL, threadNumber + 1))!= 0) {
        printf( "barrier1 init");
    }

    if ((pthread_barrier_init(&b2, NULL, threadNumber + 1)) != 0) {
        printf("barrier2 init");
    }

    // Создаем потоки
    int mapped_block_size = 0;
    int last_round_flag = 0;
    char* address;
    struct thread_info *info;
    info = calloc(threadNumber, sizeof(struct thread_info));
    if (info == NULL) {
        printf("calloc");
    }

    for (int i = 0; i < threadNumber; ++i) {
        info[i].thread_num  = i + 1;
        info[i].address_pointer = &address;
        info[i].chunk_size = chunk_size;
        info[i].block_size = &mapped_block_size;
        info[i].last_round_flag = &last_round_flag;
        info[i].b1 = &b1;
        info[i].b2 = &b2;

        status = pthread_create(&info[i].thread_id, NULL, &thread, &info[i]);
        if (status != 0) {
            printf( "pthread_create");
        }
    }

    // Цикл обработки
    off_t offset = 0;
    off_t remaining_size = file_stat.st_size;
    int count = 0;
    while (remaining_size > 0) {
        if (remaining_size > block_size) {
            mapped_block_size = block_size;
        } else {
            mapped_block_size = remaining_size;
        }
       
        address = mmap(NULL, mapped_block_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, file_descriptor, offset);
    
        if (address == MAP_FAILED)
            printf("mmap");
        offset += block_size;
        remaining_size -= block_size;

        if (remaining_size <= 0)
            last_round_flag = 1;

        status = pthread_barrier_wait(&b1);
        if (status != 0 && status != PTHREAD_BARRIER_SERIAL_THREAD) {
            printf( "barrier_wait(barrier1)");
        }

        status = pthread_barrier_wait(&b2);
        if (status != 0 && status != PTHREAD_BARRIER_SERIAL_THREAD) {
            printf( "barrier_wait(barrier2)");
        }

        if ((msync(address, mapped_block_size, MS_SYNC)) == -1) {
            printf("msync");
        }

        if ((munmap(address, mapped_block_size)) == -1)
            printf("munmap");

        // Вывод процентов обработки
        ++count;
        if (count == 800) {
            count = 0;
            float processed_value = (float)(file_stat.st_size - remaining_size) / file_stat.st_size * 100;
            if (processed_value > 100.00f)
                processed_value = 100.00f;
            fprintf(stdout, "completed: %.3f%%\n", processed_value);
        }
    }

    fprintf(stdout, "completed: %.3f%%\n", 100.000f);

    // Завершаемся
    pthread_barrier_destroy(&b1);
    if (status != 0) {
        printf( "b1 destroy");
    }
    pthread_barrier_destroy(&b2);
    if (status != 0) {
        printf( "b2 destroy");
    }

    status = close(file_descriptor);
    if (status == -1) {
        printf("close file");
    }

    exit(EXIT_SUCCESS);
}


long int process_int_arg(char* arg, const char* error_msg) {
    char* endptr;
    errno = 0;
    long int val = strtol(arg, &endptr, 10);
    if ((errno == ERANGE && (val == LONG_MAX || val == LONG_MIN))
        || (errno != 0 && val == 0)) {
        printf("wrong number");
    }
    if (endptr == arg) {
        fprintf(stderr, "%s: No digits were found\n", error_msg);
        exit(EXIT_FAILURE);
    }
    return val;
}

int compare_ints(const void* a, const void* b) {
    uint32_t arg1 = *(const uint32_t*)a;
    uint32_t  arg2 = *(const uint32_t*)b;

    if (arg1 < arg2) return -1;
    if (arg1 > arg2) return 1;
    return 0;
}

static void* thread(void* arg) {
    int status;
    struct thread_info* info = arg;

    while (!(*info->last_round_flag)) {
        status = pthread_barrier_wait(info->b1);
        if (status != 0 && status != PTHREAD_BARRIER_SERIAL_THREAD) {
            printf("barrier_wait(barrier2)");
        }

        // Считаем смешение для данного потока
        int start = (info->thread_num - 1) * info->chunk_size;
        if (start >= *info->block_size) {
            status = pthread_barrier_wait(info->b2);
            if (status != 0 && status != PTHREAD_BARRIER_SERIAL_THREAD) {
                printf( "barrier_wait(barrier2)");
            }
            pthread_exit(0);
        }

        // Считаем размер обрабатываемого блока
        int size;
        if ((*info->block_size - start) > info->chunk_size)
            size = info->chunk_size;
        else {
            size = *info->block_size - start;
        }
        size = size - (size % sizeof(uint32_t));

        qsort(*info->address_pointer + start, size / sizeof(uint32_t),
              sizeof(uint32_t), compare_ints);

        status = pthread_barrier_wait(info->b2);
        if (status != 0 && status != PTHREAD_BARRIER_SERIAL_THREAD) {
            printf("barrier_wait(barrier2)");
        }
    }

    pthread_exit(0);
}

