.model      small
.stack      100h

.data
    startMessage      db "CONSOLE PARAMETERS: ", '$'
    iterationsMsg     db "ITERATIONS COUNT: ", '$'
    fileMsg           db "FILENAME: ", '$'
    applicationError  db "APPLICATION START ERROR!", '$'
    stringMsg         db "STRING NUMBER: ", '$'
    negativeExit      db "ENTER CORRECT NUMBER!", '$'
    allocatingError   db "ALLOCATING MEMORY ERROR!", '$'
    startupError      db "STARTUP ERROR!", '$'
    badFileMessage    db "CANNOT OPEN FILE", 0dh, 0ah, '$'
    badArguments      db "BAD ARGUMENTS ERROR!", 0dh, 0ah, '$'
    fileError         db "ERROR OPENING FILE!", '$'
    badFileName       db "BAD FILE NAME!", '$'

    partSize          equ 256
    wasPreviousLetter dw 0
    realPartSize      dw 256
    descriptor        dw 0
    pointerPosition   dd 0
    path              db 256 dup('$')
    tempVariable      dw 0
    isEndl            db 0
    spacePos          dw 0
    base              dw 10
    iterations        dw 0
    stringNumber      dw 0
    parsingStep       dw 1
    endl              db 13, 10, '$'
    endlCounter       dw 0
    
    tempString        db 256 dup('$')
    fileName          db 256 dup(0)
    dtaBuffer         db 128 dup(0)
    applicationName   db 256 dup(0)
    part              db partSize dup('$')
    
    ;адресс блока параметров для epb (загрузить и выполнить программу)
    EPB         dw 0                     ;текущее окружение
                dw offset commandline, 0  ;адрес командной строки
                dw 005Ch, 0, 006Ch, 0    ;адрес FCB программы      
    commandline db 125                   ;длина кмд
                db " /?"
    commandtext db 122 dup (?)

    dsize=$-startMessage          ;размер сегмента данных 
.code

;вывод параметров консоли
printString proc  
    push    bp
    mov     bp, sp   
    pusha                                                     
    mov     dx, [ss:bp+4+0] ;обращение к сегменту стека для загрузки первого параметра    
    mov     ax, 0900h   ;при вызове подпрограммы
    int     21h 
    mov     dx, offset endl  ;переходн на новую строку
    mov     ax, 0900h
    int     21h  
    popa
    pop     bp      
    ret 
endp

;output string
puts proc
    mov     ah, 9
    int     21h
    ret
endp

;проверка на корректность имени файла
badFileNameCall proc
    lea     dx, badFileName
    call    puts
    call    exit
endp

exit proc
    mov     ax, 4c00h
    int     21h
endp

;проверка на ввод в пределах [1..255]
badRange:
    lea     dx, negativeExit  ;вывод ошибки
    call    puts
    call    exit
ret

;строку в число
toInteger proc
    pusha        
    xor     di, di
    lea     di, path ;строка для проверки
    xor     bx, bx     
    xor     ax, ax   
    xor     cx, cx
    xor     dx, dx
    mov     bx, spacePos  ;храним позицию пробела
    
    skipSpacesInteger:
        cmp     [di + bx], byte ptr ' ' ;пропускаем пробел
        jne     unskippingInteger
        inc     bx
        jmp     skipSpacesInteger
    
    unskippingInteger:
        cmp     [di + bx], byte ptr '-' ;вывод ошибки,если отрицательное число
        jne     atoiLoop
        jmp     atoiError

    atoiLoop: 
    ;перевод        
        cmp     [di + bx], byte ptr '0'     ;аски код < 0
        jb      atoiError  
        cmp     [di + bx], byte ptr '9'   ;аски код > 9
        ja      atoiError                     
        mul     base            ;mul 10
        mov     dl, [di + bx] 
        jo      atoiError 
        sub     ax, '0'   ;отнимаем 30h,чтобы получить число
        jo      atoiError  ;проверяем переполнение
        add     ax, dx    ;сохраняем и парсим дальше
        inc     bx 
        cmp     [di + bx], byte ptr ' '  ;если не число - заканчиваем
        jne     atoiLoop  
        jmp     atoiEnd 
    
    atoiError:
        jmp     badRange

    atoiEnd: 
        mov     tempVariable, ax  ;храним полученное число
        mov     spacePos, bx    ;и текущую позицию пробела
        inc     parsingStep         ;увеличиваем кол-во итераций перевода
        cmp     tempVariable, 255    ;проверяем наше число на нужном промежутке
        jg      badRange
        cmp     tempVariable, 0
        je      badRange
        popa
        ret
endp

;число в строку
toString proc
    pusha
    xor     di, di
    lea     di, tempString
    mov     ax, tempVariable
    xor     bx, bx
    mov     bx, di
    xor     cx, cx
    mov     cx, 256
    setZeroString: ;зануляем строку
        mov     [di], byte ptr '$'
        loop    setZeroString
        lea     di, tempString
    itoaLoop:
        xor     dx, dx
        div     base  
        add     dl, '0' ;+30h для получения строки из числа
        mov     [di], dl
        inc     di                   
        cmp     ax, 0    ;проверка на число
        ja      itoaLoop            ;продолжаем
        dec     di
        xor     si, si
        mov     si, bx 
        popa
        ret
endp

;ошибка запуска программы
applicationStartError:
    lea     dx, applicationError
    call    puts
    call    exit
ret

;выделение памяти
;allocateMemory proc
   ; push    ax
;    push    bx 
;    mov     bx, ((csize/16)+1)+256/16+((dsize/16)+1)+256/16 ;psp stack data segment stack segment
;    mov     ah, 4Ah   ;4Ah измменить размер блока памяти
;    int     21h 
;    jc      allocateMemoryError
;    jmp     allocateMemoryEnd  
;mov sp,csize + 100h+200h
;mov ah,4ah
;stack_shift = csize + 100h + 200h
;mov bx,stack_shift shr 4 + 1
;int 21h
;
;mov ax,cs
;mov word ptr EPB+4,ax
;mov word ptr EPB+8,ax
;mov word ptr EPB+0Ch,ax  
;
;    allocateMemoryError:  ;ошибка при выделении
;        lea     dx, allocatingError
;        call    puts
;        call    exit    
;    allocateMemoryEnd:
;        pop     bx
;        pop     ax
;        ret
;endp
;
;количество запусков
getIterations proc
    pusha
    xor     ax, ax
    call    toInteger   ;получаем наше ввведеное число
    mov     ax, tempVariable
    mov     iterations, ax    ;и храним его для дальнейших действий
    popa
    ret
endp

;загрузить и запустить приложение
loadAndRun proc
    mov     ax, 4B00h      ;4Bh загрузить и выполнить программу
    lea     dx, applicationName  ;адрес с полным именем программы
    lea     bx, EPB  ;адрес блока epb  
    int     21h
    jb      applicationStartError    ;проверка ошибки запуска
    ret
endp

;ошибка вызова файла
fileErrorCall:
    lea     dx, fileError
    call    puts
    call    exit
ret

;получение имени файла
getFilename proc
    pusha
    lea     di, path ; строка с данными 
    xor     bx, bx     
    xor     ax, ax   
    mov     bx, spacePos
    skipSpacesString:
        cmp     [di + bx], byte ptr ' ' ;пропускаем пробелы в имени
        jne     unskippingString
        inc     bx
        jmp     skipSpacesString
    unskippingString:
        lea si, fileName ;строка с именем файла
    copyFilename:
        xor     ax, ax
        mov     al, [di + bx] 
        mov     [si], al   ;поэлементно пеерписываем имя файла из path в fileName
        inc     bx
        inc     si
        cmp     [di + bx], byte ptr '$'
        jne     copyFilename
        mov     spacePos, bx
        popa
        ret
endp

;получение номера строки
getStringNumber proc
    pusha
    xor     ax, ax
    call    toInteger
    mov     ax, tempVariable ;тут лежит введеное число == номеру строки
    mov     stringNumber, ax ;номер строки
    popa
    ret
endp

;получение имени выполняемого файла (проход по файлу)
getApplicationName proc
    pusha
    xor     ax, ax
    mov     dx, offset fileName    ;имя файла для поиска
    mov     ah, 3Dh        ;открыть файл 3Dh
    mov     al, 00h         ;для чтения
    int     21h
    mov     descriptor, ax
    mov     bx, ax
    jnc     readFilePart  ;CF = 0 - нет ошибки при открытии
    jmp     fileErrorCall;   иначе выводим ошибку
    readFilePart:    
        mov     ah, 42h     ;указатель чтения\записи файла
        mov     cx, word ptr [offset pointerPosition]  ;  старший байт смещения
        mov     dx, word ptr [offset pointerPosition + 2] ; младший байт смещения  (перемещение от начала файла)
        mov     al, 0     ;начало файла
        mov     bx, descriptor   ;индетификатор файла
        int     21h
        mov     cx, partSize ;число байт для считывания
        lea     dx, part   ;адрес буфера для приема данных
        mov     ah, 3Fh     ;чтение фалйа с дескриптором
        mov     bx, descriptor
        int     21h
        mov     realPartSize, ax ;помещаем число считаных байт 
        call    searchApplicationName
        call    memset
        cmp     realPartSize, partSize
        jb      closeFile
        mov     bx, stringNumber 
        cmp     endlCounter, bx
        je      closeFile  ;закрываем файл
        ;если нет - идем дальше
        mov     cx, word ptr [offset pointerPosition]
        mov     dx, word ptr [offset pointerPosition + 2]
        add     dx, ax
        adc     cx, 0
        mov     word ptr [offset pointerPosition], cx
        mov     word ptr [offset pointerPosition + 2], dx
        jmp     readFilePart
    closeFile:
    exitFromFile:
        mov     ah, 3Eh        ;закрыть файл
        mov     bx, descriptor
        int     21h
        popa
        ret
endp

;поиска имени в файле (проход по строке)
searchApplicationName proc
    pusha
    xor     si, si
    partParsing:
        call    checkEndl  ;проверка на ендл
        mov     ax, stringNumber ;номер нашей строки
        cmp     endlCounter, ax ;если нужная строка
        je      parseApplicationName   ;обрабатываем имя программы
        cmp     isEndl, 0
        je      increment
        inc     endlCounter
        jmp     partParsingCycle
        increment:
            inc     si
        partParsingCycle:
            mov     isEndl, 0
            cmp     si, realPartSize
            jb      partParsing        ;if lower
            popa
            ret
    parseApplicationName:
        cmp     isEndl, 1
        jne     parseStart   
        call    badFileNameCall
        parseStart:
            lea     di, applicationName ;помещаем имя проги
            copyApplicationName: ;копируем иимя в ди  
            ;в пройденном промежутке в файле ищем имя
                xor     ax, ax
                mov     al, [part + si]
                mov     [di], al
                inc     si
                inc     di   
                ;проверка на конец строки
                cmp     [part + si], 0dh
                je      exitFromParsing
                cmp     [part + si], 0ah
                je      exitFromParsing
                cmp     si, realPartSize
                je      exitFromParsing
                jmp     copyApplicationName    
    exitFromParsing:
        popa
        ret
endp

;проверка на конец строки
checkEndl proc
    mov     al, [part + si]
    xor     ah,ah
    cmp     al, 0dh
    je      checkNextSymbol
    cmp     al, 0ah
    jne     exitFromEndlCheck
    inc     si
    call    setIsEndl ;если новая строка - устанавливаем флаг конца строки
    exitFromEndlCheck:
    ret
endp

;проверка некст символа
checkNextSymbol:
    call    setIsEndl
    mov     bl, [part + si + 1]
    xor     bh,bh
    cmp     bl, 0ah  ;если newline - завершаем
    jne     exitFromCheck
    inc     si
    exitFromCheck:
        inc     si
ret

;флаг конца строки
setIsEndl proc
    mov     isEndl, 1
    ret
endp

;memset
memset proc
    pusha
    xor     si, si
    lea     si, part
    mov     cx, partSize
    setEndCycle:    ;"зануление"
        mov     byte ptr [si], '$'
        inc     si
        loop    setEndCycle
        popa
        ret
endp

;неправильные аргументы строки
badArgumentsCall:
    lea     dx, badArguments  ;вывод ошибки
    call    puts
    call    exit
ret

;start
start:
   ; call    allocateMemory    ;выделяем память
    mov     ax, @data        
    mov     ds, ax
    mov     bl, es:[80h]     ;размер кмд
    add     bx, 80h             
    mov     si, 82h           ;параметры командной строки
    mov     di, offset path   ;передаем введеную строку
    cmp     si, bx
    ja      badArgumentsCall 
    getPath:
        mov     al, es:[si]
        mov     [di], al
        cmp     BYTE PTR es:[si], byte ptr ' ' ;проверка на первый пробел в начале
        jne     getNextCharacter  ;устновка флага если символ
        cmp     wasPreviousLetter, 0
        je      skipCurrentSymbol   ;иначе скип
        mov     wasPreviousLetter, 0
        cmp     parsingStep, 1
        jne     stepTwo
        call    getIterations ;сколько раз запустить программу
        jmp     skipCurrentSymbol
        stepTwo:
            call    getStringNumber   ;получаем номер строки
            jmp     skipCurrentSymbol   ;переходим к файлу
        stepThree:
            call    getFilename   ;получаем имя файла
            jmp     main
        getNextCharacter:
            mov     wasPreviousLetter, 1
        skipCurrentSymbol:
            inc     di
            inc     si
            cmp     si, bx
            jg      stepThree    ;если больше
    jbe getPath      ;если меньше или равно
    
    main:
        lea     dx, startMessage ;вывод сообщения
        call    puts
        lea     ax, path  ;строка ввода
        push    ax
        call    printString  
        pop     ax
        dec     stringNumber
        call    getApplicationName ;получаем имя программы
        xor cx, cx
        mov cx, iterations ;счетчик = количеству запусков проги
        startApps:        
        ;освобождаем всю память после конца программы и стека
            mov sp,csize + 100h+200h ;перемещение стека на 200h после конца проги
            mov ah,4ah    ;сокращаем память до минимума
            stack_shift = csize + 100h + 200h
            mov bx,stack_shift shr 4 + 1  ;размер в параграфах + 1
            int 21h        ;изменяем размер выделеного блока памяти
            ;заполнение полей epb
            mov ax,cs
            mov word ptr EPB+4,ax  ;сегмент командной строки
            mov word ptr EPB+8,ax   ;сегмент превого  fcb
            mov word ptr EPB+0Ch,ax ;сегмент второго fcb
            call    loadAndRun  ;запускаем и выводим работу
            loop    startApps
            call exit
endp

csize = $ - start  ;размер сегмента кода

end start      



