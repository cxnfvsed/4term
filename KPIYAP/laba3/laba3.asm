.model small 
.stack 100h
.data
    numberTen             dw  000Ah 
    sizeOfNumber          equ 2
    maxMassiveLength      equ 08h ;8
    numberStringLength    equ 20 
    
    i                     dw ? ;для прохода по матрице
    j                     dw ? 
    rows                  dw ?
    cols                  dw ?
    total                 dw ? 
    one                   dw 1
    mulArray              dw maxMassiveLength dup ('$') 
    resultArray           dw maxMassiveLength dup ('$')   ;хранение результата умножения
    array                 dw maxMassiveLength*maxMassiveLength dup('$') ;матрица                                     
    numberString          db numberStringLength dup('$')
    inputLimitsString     db "minimal value = -32768, maximal = 32767$" 
    invalidLengthString   db "input error. 1 <= length <= 8$"
    inputRowsString       db "enter the rows size $"
    inputColsString       db "enter the columns size $" 
    inputArrayString      db "fill in the matrix $" 
    invalidInputString    db "input error $" 
    tryAgainString        db "try again: $" 
    inputInviteString     db "enter the number: $"
    newLine               db 13, 10,'$'
    space                 db " $"
    overflow              db "Overflow $"
.code 
 
;ввод числа  
inputNumbers proc
    call printNewLine    ;переходим на новую строку
    lea dx, inputInviteString  ;выводим приглашение на ввод
    call outputString  
    
repeatElementInput:
    lea dx, numberString  ;передаем число в строку
    call inputString          
    lea si, numberString[2]
    call parseString     ;переводим строку в число
    jc invalidInput
    call loadNumber      ;сохраняем введенное число и продолжаем ввод
    loop inputNumbers
ret

invalidInput:           ;сообщение об ошибки при кривом вводе
    call printNewLine
    lea dx, invalidInputString
    call outputString
    jno tryAgainOutput  ;повторный ввод при ошибке
tryAgainOutput:
    lea dx, tryAgainString  ;приглашение на повторный ввод
    call outputString
    jmp repeatElementInput  ;повторный ввод
    
loadNumber:
    mov [di], ax        ;сохраняем  элемент
    add di, sizeOfNumber    ;и переходим дальше
ret 
inputNumbers endp

;перевод строки в число
;dx,bx,ax юзаются в процессе перевода, si - адрес строки
;результат записывается в ax,
parseString proc
    xor dx,dx
    xor bx,bx
    xor ax,ax  
    xor ch,ch
    jmp inHaveSign    ;проверка на наличие знака
parseStringLoop:
    mov bl, [si]  ;записываем число(1 цифра = 1 байту) 
    jmp isNumber   ;проверка на число
validString:
    sub bl, '0'  ;отнимаем 30h, получая число
    imul numberTen ;ax * 10
    jo invalidString           ;число больше 16 бит
    js invalidString           ;число больше 15 бит
    cmp ch, 1                  ;если число с минусом
    je negativeAdd
    add ax, bx
    js invalidString           ;проверка положительного числа на появление знака 
checkInvalid:
    inc si
    jmp parseStringLoop
             
negativeAdd:
    sub ax, bx   ;
    jmp checkInvalid             
             
isNumber:
    cmp bl, 0Dh          ;конец строки(нажат enter)
    je endParsing        ;если дошли до конца строки - прекращаем перевод строки
    cmp bl, '0'                               
    jl invalidString     ;если ASCII < '0'
    cmp bl, '9'
    jg invalidString     ;если ASCII > '9'      
    jmp validString      ;число
  
inHaveSign:
    cmp [si], '-'   ;проверка на минус
    je negative
    cmp [si], '+'   ;проверка на плюс
    jne isNullString
    inc si     
    jmp isNullString
    
negative: 
    mov ch, 1  ;если число с минусом устанавливаем ch = 1
    inc si      ;и становимся на само число
    jmp isNullString

isNullString:
    cmp [si], 0Dh  ;если конец строки - ошибка(отсутствие ввода)
    je invalidString
    jmp parseStringLoop
        
invalidString:
    ;pop bx   ;1 или -1
    xor ch, ch         
    stc   ;CF = 1
ret

endParsing:
    clc  ;CF = 0
    xor ch, ch
ret
parseString endp

;вывод числа
;ax - само число, di - адрес результата 
;после преобразования di указатель после символа '$'
numberToString proc
    push 0          
    push 0024h  ;$
    add ax, 0000h      
    js numberIsNegative ;если есть знак (число < 0)  
numberToStringConvertingLoop:    
    xor dx,dx
    div numberTen ;переводим число в строку
    add dx, '0' ;добавляем аски код нуля,чтобы получить строку из числа
    push dx
    cmp ax, 0h
    jne numberToStringConvertingLoop   
moveNumberToBuffer:
    pop ax
    cmp al, '$'    ;сравниваем с символом конца строки
    je endConverting  ;если конец - заканчиваем перевод
    mov [di], al    ;сохраняем адрес элемента
    inc di        ;и переходим на некст
    jmp moveNumberToBuffer
endConverting:
    pop ax
    mov [di], '$'
ret

numberIsNegative:
    mov [di], '-'
    inc di
    not ax  ;инверсия битов в ах
            ;добавляем единицу для доп кода        
    inc ax ;для правильного преобразования из отрицательного в положительное
    jmp NumberToStringConvertingLoop 
numberToString endp    

;ввод кол-ва рядов
rowInput proc 
    call printNewLine    
    lea dx, inputRowsString
    call outputString         
    lea di, rows  
    mov cx, 0001h ;ввод одного числа
    call inputNumbers
    cmp ax, maxMassiveLength   ;больше размера строки
    jg invalidRowsInput
    cmp ax, 0001h       ;не одно число
    jl invalidRowsInput     
    call printNewLine
ret

invalidRowsInput:     ;ошибка ввода
    call printNewLine
    lea dx, invalidLengthString
    call outputString        ;вывод сообщения об ошибке
    call printNewLine
    jmp rowInput      ;повторный ввод
rowInput endp
   
;ввод колва строк   
colInput proc 
    call printNewLine    
    lea dx, inputColsString
    call outputString         
    lea di, cols  
    mov cx, 0001h  ;ввод одного числа
    call inputNumbers
    cmp ax, maxMassiveLength  ;сравниваем с допустимой длинной строки
    jg invalidColsInput
    cmp ax, 0001h        ;введеное одно число
    jl invalidColsInput     
    call printNewLine
ret    
    
invalidColsInput:   ;ошибка ввода
    call printNewLine
    lea dx, invalidLengthString
    call outputString  ;выводим сообщение об ошибке
    call printNewLine
    jmp colInput      ;повторный ввод
colInput endp 

getTotal proc       ;процедура получения размера матрицы
    mov ax, rows      ;помещаем rows в ах
    mov bx, cols      ;помещаем cols в Ьх
    mul bx            ;умножаем ах на ьх
    mov total, ax     ;записываем результат 
ret
getTotal endp

;ввод массива
msInput proc
    call printNewLine ;новая строка
    lea dx, inputArrayString   ;приглашение на ввод
    call outputString             
    xor cx, cx
    mov cx, total     ;записываем размер матрицы
    lea di, array      ;передаем массив
    call inputNumbers
    call printNewLine 
ret
msInput endp 
  
;вывод масива
msOutput proc
    mov i, 0000h    ;встаем на начало матрицы
    mov j, 0000h
    lea si, array ;передаем адрес массива
    jmp loop2  
loop1:      
    lea dx, newLine
    call outputString
    mov j, 0000h
    inc i 
    mov cx, i
    cmp cx, cols
    je loop2return
loop2: 
    mov ax, [si]      ;элемент по адресу си
    add si, sizeOfNumber             ;некст
    
    lea di, numberString[2]
    call numberToString         ;переводим число в строку для вывода
    lea dx, numberString[2]
    call outputString   ;выводим число и после него пробел
    lea dx, space
    call outputString
    inc j          ;выводим элементы столбца в строке 
    mov cx, j
    cmp cx , rows   ;если конец матрицы по столбцам
    jne loop2 
    jmp loop1   ;переход на новую строку матрицы
loop2return:    
ret
msOutput endp 

findMul proc         ;умножение элементов
    lea di, mulArray
    lea si, array 
    ;lea bx, resultArray
    mov i, 0000h
    mov j, 0000h 
    xor bp,bp
    xor ax, ax    ;храним результат
    inc ax
    jmp mulLoop2  
mulLoop1:    
    mov [di], ax     ;адрес результата
    add di, sizeOfNumber   ;переход на следующий элемент
    add bx, sizeOfNumber  
    add bp, sizeOfNumber
    lea si,array       ;адрес матрицы
    add si,bp      ;отступ на столбец(переход на некст столбец)
    xor ax, ax
    inc ax 
    mov i, 0000h   ;увеличиваем столбец, обнуляя i
    inc j 
    mov cx, j      ;сравниваем на последний столбец
    cmp cx, rows
    je mulLoop2return
mulLoop2: 
    imul one, [si]    ;счиатаем произведение
    jo overflowMul    ;проверка на переполнение
     
mulLoop2next: 
    add si, rows      ;переход на некст строку
    add si, rows 
    inc i
    mov cx, i
    cmp cx , cols     ;проверка на ласт строку
    jne mulLoop2 
    jmp mulLoop1
mulLoop2return:    
ret
findMul endp
 

printMul proc     ;вывод результата
    lea si, mulArray
    lea bx, resultArray
    mov i, 0000h
    
startPrintMul:   
    cmp [bx], 0       ;с большего аналогично выводу массива
    je printOverflow
    mov ax, [si]     
    
    lea di, numberString[2]
    call numberToString

    lea dx, numberString[2]
    call outputString   
    call printNewLine

nextPrint:    
    inc i                  ;переходим на следующий элемент
    add si, sizeOfNumber  ;смещаясь на размер одного элемента
    add bx, sizeOfNumber
    mov cx, i
    cmp cx, rows          ;если не вышли за размер - продолжаем выводить
    jne startPrintMul 
ret
printMul endp

printOverflow:   ;переполнение 
    lea dx, overflow
    call outputString
    call printNewLine
    jmp nextPrint
    
overflowMul: 
    mov word ptr [bx], 0
    jmp mulLoop2next
               
;процедуры ввода и вывода 
printNewLine proc   ;переход на новую строку
    lea dx, newLine
    call outputString
ret
printNewLine endp

outputString proc ;вывод строки
    mov ah, 09h
    int 21h    
ret
outputString endp

inputString proc  ;ввод строки
    mov ah, 0Ah
    int 21h
ret
inputString endp

start:
    mov ax, data
    mov ds, ax
    mov es, ax
    xor ax, ax 
    
    mov [numberString], numberStringLength  ;храним макс длину строки
    lea dx, inputLimitsString
    call outputString       ;выводим начальную строку
    call printNewLine

    call rowInput           ;ввод кол-ва рядов 
    call colInput           ;ввод кол-ва строк 
    call getTotal           ;размер матрицы
    call msInput            ;ввод матрицы
    call msOutput           ;вывод матрицы
    call findMul            ;находим произведение столбцов
    call printNewLine       ;переход на новую строку
    call printMul           ;выводим произведение
    
exit:                       ;выход 
    mov ax, 4c00h
    int 21h    
ends

end start    
