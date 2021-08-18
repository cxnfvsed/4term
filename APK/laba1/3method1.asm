.model small
.stack 100h

.186
.data
str1 db "Enter in COM1:",0Dh,0Ah,'$'
COM1 equ 03F8h
str2 db "Line break detected.",0Dh,0Ah,'$'


.code
jmp start



start:
mov ax,@data
mov ds,ax 
;настройка COM1
mov dx,03FDh
in al,dx; пересылаем байт из порта
test al,10000b
jz ok ;если передан,то переходим к процедуре
;иначе выводим сообщение об ошибке
mov dx,offset str2 ;вывод строки str2
mov ah,9
int 21h
jmp end 
    
    
ok:
mov dx,03FBh;для чтения и записи
xor ax,ax;очищаем регистр
mov ax,080h
out dx,al ;вывод данных из регистра в порт
mov dx,03F8h ;если старший бит - 0
;то передаем данные
mov ax,000Ch ;устанавливаем частоту порта
out dx,al
mov dx,03FBh
xor ax,ax
mov ax,0011b ;установка режима 8N1
out dx,al
    ;настройка COM2
mov dx,02FBh;чтение и запись
xor ax,ax
mov ax,080h
out dx,al
mov dx,02F8h
mov ax,000Ch;установка частоты порта 9600
out dx,al
mov dx,02FBh;чтение и запись
xor ax,ax
mov ax,0011b;установка режима 8N1
out dx,al
mov ah,9
mov dx,offset str1
int 21h 

input:
        
mov ah,1 ;запись символа в порт
int 21h
mov dx,COM1
out dx,al ;вывод из регистра в порт
        
end:   ;завершение работы программы 
mov ax,4C00h
int 21h
end start