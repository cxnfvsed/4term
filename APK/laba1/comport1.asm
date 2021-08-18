.model small
.stack 100h

.186
.data
str1 db "Enter in the COM1:",0Dh,0Ah,'$'
COM1 equ 03F8h
str2 db "Break detected.",0Dh,0Ah,'$'

.code
jmp start

start:
mov ax,@data
mov ds,ax
mov ah,9
mov dx,offset str1;вывод строки str1 
int 21h
mov dx,0 ;получение статуса порта
mov ah,3
int 14h
test ah,10000b ;проверка готовности принять байт
jz ok
mov dx,offset str2 ;вывод строки str2
mov ah,9
int 21h
jmp end


ok:       ;запись символа
mov ah,1
int 21h
mov dx,0 ;получение статуса порта
mov ah,1 ;запись символа в последовательный порт
int 14h

end: ;завершение работы
mov ax,4C00h
int 21h

end start