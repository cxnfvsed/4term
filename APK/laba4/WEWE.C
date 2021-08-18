#include <dos.h>
#include <conio.h>
#include <stdio.h>

#define COUNTER 9
#define DELAY 10


void soundGo()
{
	int count, byte;
	int hz[COUNTER] = { 329,329,329,415,523,659,587,523,659 };
	int duration[COUNTER] = {200,100,200,400,200,200,400,200,400};
	int countDelay[COUNTER] = {100,100,100,100,100,100,100,100,100};

	for (count = 0; count < COUNTER; count++)
	{
 	// 2th channel setting:
        // port 42h (system timer, channel 2, speaker sound)
        // port 43h (command register) 

		outp(0x43, 0xB6); //0xB6 - configure 2 channel by port 43h 
		byte = 1193180 / hz[count]; 
		outp(0x42, byte % 256); //smallest byte of the frequency divider
		outp(0x42, byte /= 256); //highest byte of the frequency divider

		outp(0x61, inp(0x61) | 3); //turn the dynamics on
		delay(duration[count]);  //wait 
		outp(0x61, inp(0x61) & 0xFC); //turnning off 'em

		delay(countDelay[count]); //wait
	}

}
void statusWord()
{

	// port 40h (channel 0, system clock interrupion)
    // port 41h (channel 1, memory regeneration)
    // port 42h (channel 2, speaker sound)

	int channel, state;
	int i;
	char stateWord[8];
	int ports[] = { 0x40, 0x41, 0x42 };
	int controlWord[] = { 226, 228, 232 };     // 11 10 001 0, 11 10 010 0, 11 10 100 0
											 //       --1          -1-          1--
	printf("\nStatus word: \n");

	for (channel = 0; channel < 3; channel++)
	{
		outp(0x43, controlWord[channel]);    // select channel (CLC commands)
		state = inp(ports[channel]);         // read state

		for (i = 7; i >= 0; i--)         // translate the word to binary
		{
			stateWord[i] = state % 2 + '0';
			state /= 2;
		}

		printf("\nChannel %d: ", channel);
		for (i = 0; i < 8; i++)
			printf("%c", stateWord[i]);
		printf("\n");
	}


}


void main()
{
char choice;
	clrscr(); //clearing the screen
        
	//making menu type shit
	do
	{
	printf("1 - play sound \n");
	printf("2- show status word\n");
	fflush(stdin);
	scanf("%s",&choice);
	switch(choice)
	{
	case '1': soundGo(); break; //playing sound in that case
	case '2': statusWord(); break; //showing the status word in that
	}
	}while(choice!='0');
      //	sound();
       //	statusWord();
}


