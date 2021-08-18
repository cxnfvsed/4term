
.model tiny 

org 100h
  
.data    
flag db "Grabber"
    
    ;interuptions
returnOldInteruptFlag   db 0
originalIRQ0 			dd ?
originalIRQ1 			dd ? 
    	
keyCode db 0 
saveFlag db 0   
rawBufer db screenWidth dup (?)
superThing db 0Ah  
screenWidth equ 80  
screenHeight equ 25
    
fileName db 125 dup (?)
fileDescriptor dd ? 
      

cmdError db "cmd params error", 0Dh, 0Ah, "format : executable name file name", '$'
       
fileCreationError 					db "file wasnt created.", 0Dh, 0Ah, '$'
       
pressKeyString						db "press the key (not 'Q').", 0Dh, 0Ah, '$' 
keyPressedString					db "ctrl + entered key to grab.", 0Dh, 0Ah, "ctrl + 'Q' quit resident program.", 0Dh, 0Ah, '$'   
QKeyPressedString					db "'Q' is reserved for exiting the program.", 0Dh, 0Ah, '$'
	    
programAlreadyInMemoryString  		db "program is already in memory.", 0Dh, 0Ah, '$'       
interuptionsReturnStringLenght   	equ 49
interuptionsReturnString        	db 0Dh, 0Ah, "original interruptions returned successfully.", 0Dh, 0Ah
		
fileOpenErrorStringLenght 			equ 27
fileOpenErrorString					db 0Dh, 0Ah, "error in save proccess!", 0Dh, 0Ah	    
	    
grabStringLenght 					equ 9
grabString							db 0Dh, 0Ah, "grab!", 0Dh, 0Ah	
   

.code
start:       
jmp handlerInstall
  
   
readStringFrom macro pointer ;вывод строки
    mov ah, 09h  
    lea dx, pointer 
    int 21h
endm  

 insertMessageInVideoMemory macro message, lenght   ;вывод строки через прерывания биоса
	mov ax, cs
	mov es, ax
	mov ah, 03h
	mov bh, 0
	int 10h 								;позиция курсора
	
	mov ah, 13h                             ;вывод строки с атрибутами
	mov al, 00000001b						 
	mov bh, 0                               
	mov bl, 07h                             ;аттрибут
	mov cx, lenght                          
	lea bp, message
	int 10h  								
endm

    
IRQ0 proc far
pusha
push ds
push es
	        
mov ax, cs
mov ds, ax 
	        
cmp saveFlag, 1
je saveCMD
	        
cmp returnOldInteruptFlag, 1   ;если 1 то вернуть старые обработчики
je returnInteruptions
        
jmp IRQ0End
saveCMD:  
mov cs:saveFlag, 0  
openFile:
mov ah, 3dh   ;открываем файл
mov al, 00000001b	
lea dx, fileName 
cli     ;запрет прерываний
int 21h  
sti    ;разрешение прерываний
jc fileOpenError
				
mov fileDescriptor, ax
jmp grabConsole
			    
fileOpenError:  ;проверка ошибки
insertMessageInVideoMemory fileOpenErrorString, fileOpenErrorStringLenght
mov cs:returnOldInteruptFlag, 1    ;устанавливаем флаг занятости
jmp IRQ0End  
                	
                	
grabConsole:
mov ax, 0B800h ;сегментный адрес видеопамяти
mov es, ax 
	
mov di, 0
mov cx, screenHeight ;высота окна 
getCLLoop:	
push cx	 
lea si, rawBufer
lea dx, rawBufer 
mov cx, screenWidth ;ширина
getRawLoop:  
;побайтно переписываем в файл						
mov al, es:di
mov [si], al
inc si
add di, 2
loop getRawLoop
mov ah, 40h ;запись в файл
mov bx, fileDescriptor
mov cx, screenWidth 
inc cx
lea dx, rawBufer
int 21h	 
			     
pop cx
loop getCLLoop
		         
closeFile:
mov ah, 3Eh
mov bx, fileDescriptor
cli
int 21h
sti	
					
insertMessageInVideoMemory grabString, grabStringLenght  
		        	
jmp IRQ0End 			
	      
returnInteruptions:   ;установка старых адресов прерываний
installOldInteruptionsAddressed: 
mov ah, 25h                			  	 
mov al, 08h ;IRQ0                     		
mov dx, word ptr cs:originalIRQ0      
mov ds, word ptr cs:originalIRQ0 + 2  
int 21h                                	;установка исходного адреса   
mov ah, 25h
mov al, 09h ;IRQ1                    
mov dx, word ptr cs:originalIRQ1
mov ds, word ptr cs:originalIRQ1 + 2 	;установка исходного адреса   
int 21h                    				
		        
printInteruptionMessage:                                      	
insertMessageInVideoMemory interuptionsReturnString, interuptionsReturnStringLenght
IRQ0End: 
pushf
call cs:dword ptr originalIRQ0  ;вызов старого обработчика
pop es
pop ds
popa 
iret 
IRQ0 endp
    
IRQ1 proc far 
pusha
pushf
call cs:dword ptr originalIRQ1  ;вызов старого обработчика
        
mov ah, 01h
int 16h			;ожидание ввода   
jz IRQ1end 		;если ничего   

         
mov dh, ah		;храним скан код  
        
mov ah, 02h
int 16h   
and al, 4		;проверка на ктрл
cmp al, 0	
jne checkExecuteKey  
jmp IRQ1end 	;не ктрл
        
checkExecuteKey:        
cmp dh, cs:keyCode ;проверка скан кода на кью	
jne checkQ   
   
mov cs:saveFlag, 1
mov ah, 00h
int 16h     
      
jmp IRQ1end
        
checkQ:
cmp dh, 10h ;если кью, то завершаем работу
jne IRQ1end
mov cs:returnOldInteruptFlag, 1  ;флаг занятости в 1
        
mov ah, 00h
int 16h 		
IRQ1end:
popa 
iret 
IRQ1 endp


handlerInstall: 

getCommandLineParameters:
mov ch, 0
mov cl, [0080h]    ;размер кмд
		    
cmp cl, 1
jbe noParamError
		                      
mov si, 81h            ;начало параметров с пробела
lea di, fileName
getInfoLoop:
spaceCheck:   ;поиск пробела
cmp [si], ' '
je spaceFound ;нашли
movsb 
jmp endGetInfoLoop
spaceFound: ;пропускаем
inc si
		            
endGetInfoLoop:
loop getInfoLoop
			
createFile:
mov ah, 3Ch  ;создаем файл
mov cx, 00000000b 
lea dx, fileName   ;имя 
int 21h 
			
jc cantCreateFile ;проверка на создание
mov fileDescriptor, ax  
				
closeNewFile:
mov ah, 3Eh  ;закрытие файла
mov bx, fileDescriptor  ;дескриптор
int 21h
		    		
readStringFrom pressKeyString
        
getExecuteKeyCode:
mov ah, 00h   ;ожидание ввода с клавы
int 16h
        	
cmp ah, 10h  ;если кью
je Qpressed
jmp gotKey
		    	
Qpressed:
readStringFrom QKeyPressedString  ;выводим сообщение
jmp handlerInstall  ;и ожидаем ввод занова  
		    	
gotKey:
mov keyCode, ah    ;сохраняем скан код клавиши
readStringFrom keyPressedString	
		    
        
getOriginalInterruptionsAddresses:  ;получение адреса исходного прерывания     
mov ah, 35h  ;получть адрес обработчика
mov al, 09h  ; IRQ1
int 21h   
mov word ptr originalIRQ1, bx ;смещение обработчика 
mov word ptr originalIRQ1 + 2, es  ;сегмент обработчика 
        
mov ah, 35h  ;аналогично
mov al, 08h 
int 21h 							  
	        
mov word ptr originalIRQ0, bx ;написано выше
mov word ptr originalIRQ0 + 2, es  	 
	    
checkAlreadyLoaded:
lea di,   flag      
lea si,   flag
mov cx, 7
repe cmpsb  
je loaded  
        
setOwnInterruptions:
mov ah, 25h  ;установка адреса обработчика прерывания
mov al, 09h   ;номер прерывания IRQ1
mov dx, offset IRQ1 ;смещение обработчика в сегменте
int 21h 
        	
mov ah, 25h ;аналогично для IRQ0
mov al, 08h 
mov dx, offset IRQ0
int 21h
	       
stayResident:
mov ah, 31h   ;оставить программу резидентной
mov dx, (handlerInstall - start + 10Fh) / 16 ;размер резидентной части программы в параграфах
int 21h
        
noParamError:   ;сообщения ошибок
readStringFrom cmdError 
jmp handlerInstallEnd
cantCreateFile:
readStringFrom fileCreationError 
jmp handlerInstallEnd
loaded:
readStringFrom programAlreadyInMemoryString 
jmp handlerInstallEnd
			
handlerInstallEnd:
mov ax, 4Ch
int 21h                           
end start