.model small
.stack 100h

.186
.data
str2 db "Data from COM2:",0Dh,0Ah,'$'
COM2 equ 02F8h
str3 db "Line break detected",0Dh,0Ah,'$'

.code
jmp start

get_str  proc ;получение строки
    mov dx,1
    mov ah,2   ;чтение символа из последовательного порта
    int 14h
    ret
get_str endp

start:
mov ax,@data
mov ds,ax
mov ah,9
mov dx,offset str2 ;вывод строки str2
int 21h
mov ah,3 ;получение статуса порта
mov dx,1
int 14h
test ah,10000b 
jz output
mov dx,offset str3  ;вывод строки str3
mov ah,9
int 21h

output:
mov ax,0  ;инициализация порта
call get_str ;вызов процедуры получения строки
mov dl,al  ;
mov ah,2 ;чтение символа из порта
int 21h
mov ax,4C00h
int 21h

end start