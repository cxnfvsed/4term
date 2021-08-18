.model small
.stack 100h

.186
.data
str2 db "Data from  COM2:",0Dh,0Ah,'$'
COM2 equ 02F8h
str3 db "Line break detected.",0Dh,0Ah,'$' 


.code
jmp start

   

get_str proc
mov dx,COM2
in al,dx;чтение принятого байта
ret
get_str endp    

start:
mov ax,@data
mov ds,ax
    
mov dx,02FDh ;регистр состояния линии для чтения
in al,dx ;чтение принятого байта
test al,10000b
jz ok
mov dx,offset str3 ; вывод строки str3
mov ah,9
int 21h
jmp end

ok:
mov ah,9
mov dx,offset str2; вывод строки str3
int 21h 
    
output:
mov ax,0 ;инициализация порта
call get_str
mov dl,al
mov ah,2 ;чтение символа из порта
int 21h
 
end: ;завершение порграммы         
mov ax,4C00h
int 21h
end start