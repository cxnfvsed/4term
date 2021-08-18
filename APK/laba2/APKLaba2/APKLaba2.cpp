#include <time.h>
#include <iostream>
using namespace std;

#define SIZE 4
#define COUNTER 1000000 //количество вычислений

void printArray(int array[SIZE][SIZE]); //вывод массива

int main()
{
	srand(time(NULL));
	int array1[SIZE][SIZE], array2[SIZE][SIZE], array3[SIZE][SIZE];

	for (int i = 0; i < SIZE; i++) //ввод матрицы
	{
		for (int j = 0; j < SIZE; j++)
		{
			//заполнение матриц рандомными значениями
			array1[i][j] = rand() % 100; 
			array2[i][j] = rand() % 100;
		}
	}
	//вывод исходных матриц
	printf("Array 1:\n");
	printArray(array1);
	printf("Array 2:\n");
	printArray(array2);

	// рассчет на языке си
	clock_t begin_c = clock(); //начинаем отсчет времени
	for(int i=0;i<COUNTER;i++)
	{
		for (int i = 0; i < SIZE; i++)
		{
			for (int j = 0; j < SIZE; j++)
			{
				array3[i][j] = array1[i][j] | array2[i][j]; //применяем операцию побитового или |
			}
		}
	}
	clock_t end_c = clock();

	//выводим результат
	printf("Result using C:\n");
	printArray(array3);
	printf("\n");

	// рассчет на ассемблере
	clock_t begin_asm = clock();
	for(int i=0;i<COUNTER;i++)
	{
		int cnt = 16;
		__asm
		{
			MOV ECX, cnt			   
			XOR ESI, ESI				   // сброс флагов, индекс источника
			START :
			MOV EAX, array1[ESI]	   // EAX = array1[ESI], аккумулятор
			MOV EDX, array2[ESI]	   // EDX = array2[ESI], регистр данных
			OR EDX, EAX			   // операция логического ИЛИ
			MOV array3[ESI], DX   // array3[ESI] = DX - запись результата в 3 массив
			INC ESI             //следующий элемент
			LOOP START
		}
	}
	clock_t end_asm = clock();
	//вывод результата
	printf("Result using ASM:\n");
	printArray(array3);
	printf("\n");

	// рассчет с использованием MMX
	clock_t begin_mmx = clock();
	for (int i=0;i<COUNTER;i++)
	{
		int cnt = 8;
		_asm
		{
			MOV ECX, cnt					// цикл - 8 итерация(т.к. в массиве 16 элементов размером
										// 4 байта = 64, а MMX позволяет за одну инструкцию обработать 8 байт)
			XOR ESI, ESI					// сброс флагов, индекс источника
			STARTM :
			MOVQ MM0, array1[ESI]	    // запись данных в MMX регистр 
			MOVQ MM1, array2[ESI]		// запись данных в MMX регистр 
			POR MM0, MM1				// операция логического ИЛИ
			MOVQ array3[ESI], MM0       //записываем результат в 3 массив
			INC ESI;                    // некст элемент
			LOOP STARTM
			EMMS							// очищаем регистры
		}
	}
	clock_t end_mmx = clock();
	//вывод результата
	printf("Result using MMX:\n");
	printArray(array3);
	printf("\n");
	//вывод затраченного на выполнение времени
	printf("Computing using C\n");
	printf("time: %.6lf sec\n\n", (float)(end_c - begin_c) / CLOCKS_PER_SEC);

	printf("Computing using ASM\n");
	printf("time: %.6lf sec\n\n", (float)(end_asm - begin_asm) / CLOCKS_PER_SEC);

	printf("Computing using MMX\n");
	printf("time: %.6lf sec\n\n", (float)(end_mmx - begin_mmx) / CLOCKS_PER_SEC);

	system("pause");
	return 0;

}


void printArray(int array[SIZE][SIZE])
{
	for (int i = 0; i < SIZE; i++)
	{
		printf("\t");
		for (int j = 0; j < SIZE; j++)
		{
			printf("\t %d ", array[i][j]);
		}
		printf("\n");
	}
	printf("\n");
}



