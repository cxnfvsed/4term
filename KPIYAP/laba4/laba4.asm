.model small
.stack 100h
.data
messageWelcome db "Tetris",0Dh ,0Ah   
               db "Controls:",0Dh ,0Ah
               db "Left/Right arrow - move",0Dh ,0Ah
               db "Up arrow - rotate:",0Dh ,0Ah
               db "Esc - exit:",0Dh ,0Ah
               db "Enter - start:",0Dh ,0Ah,'$'
              
playField db 276 dup(00h)  ;размер поля
;задаем тетрамины
figureShape db 00h, 00h, 00h, 00h  ;L 10 синий цвет
            db 00h, 00h, 10h, 00h 
            db 10h, 10h, 10h, 00h           
            db 00h, 00h, 00h, 00h
           
            db 00h, 00h, 00h, 00h ;T 20 зеленый цвет
            db 00h, 20h, 00h, 00h 
            db 20h, 20h, 20h, 00h
            db 00h, 00h, 00h, 00h
            
            db 00h, 00h, 30h, 00h ;Z 30 светло-голубой цвет
            db 00h, 30h, 30h, 00h
            db 00h, 30h, 00h, 00h
            db 00h, 00h, 00h, 00h
            
            db 00h, 00h, 00h, 00h ;S 40 красный цвет
            db 00h, 00h, 40h, 40h
            db 00h, 40h, 40h, 00h
            db 00h, 00h, 00h, 00h
            
            db 00h, 00h, 00h, 00h ;O 50 розовый цвет
            db 00h, 50h, 50h, 00h
            db 00h, 50h, 50h, 00h
            db 00h, 00h, 00h, 00h           
            
            db 00h, 0E0h, 0E0h, 00h ;J E0  коричневый цвет
            db 00h, 0E0h, 00h, 00h
            db 00h, 0E0h, 00h, 00h
            db 00h, 00h,  00h, 00h
            
            db 00h, 00h, 60h, 00h ;I 60
            db 00h, 00h, 60h, 00h
            db 00h, 00h, 60h, 00h
            db 00h, 00h, 60h, 00h  
                 ;текущая фигура
currentFigureShape db 00h, 00h, 00h, 00h
                   db 00h, 00h, 00h, 00h
                   db 00h, 00h, 00h, 00h
                   db 00h, 00h, 00h, 00h  

currentFigure dw 0     ;положение фигуры на поле
currentFigureX dw 0   ;положение фигуры на поле по х
currentFigureY dw 0   ;положение фигуры на поле по у
previousTime dw 0  ;время  
score dw 0         ;счет
.code
jmp main
  
printScore proc near    ;вывод счета
    pusha  ;сохраняем регистры в стек
    xor cx, cx    
    mov ax, score    ;помещяем счет
    xor dx, dx 
    mov si, 10
loadStack:   
    div si 		;перевод числа в строку для вывода	  		
    add dl, '0'  ;добавляем 30h
    push dx    
    xor dx, dx 
    inc cx        
    cmp ax, 0
    jne loadStack   
    mov bx, 202 ;место на экране для вывода счета     
printStack:
    pop dx 
    push ds
    mov ax, 0b800h ;сегментный адресс видеопамяти
    mov ds, ax
    mov [bx], dl
    inc bx
    mov [bx], 07h ;управляющий символ BEL
    inc bx
    pop ds           
    loop printStack          
    popa  ;извлекаем все регистры из стека
    ret   
endp    
  
initScreen proc near  ;загрузка игрового экрана
    push cx
    push ax
    push si
    push ds       
    mov ax, 0b800h ;сегментный адрес видеопамяти
    mov ds, ax 
        
    xor bx, bx
    mov cx, 1000  
    ;очистка экрана
    loopScreen:     
    mov [bx], ' '
    inc bx
    mov [bx], 07h
    inc bx
    loop loopScreen
    
    xor si, si
    mov ax, 40  
    ;окраска границ в красный цвет
    firstLine:
    mov [si], ' '
    inc si
    mov [si], 40h ;проходим по верхней границе
    inc si   ;и красим ее в красный цвет
    dec ax
    cmp ax, 0
    je firstLineEnd ;конец верхней линни поля
    jmp firstLine
    firstLineEnd:
    mov ax, 23
    columns:  ;отрисовка боковых границ
    mov [si], ' '
    inc si
    mov [si], 40h ;красим первыый блок столбца в красный
    inc si
    add si, 76 ;сдвигаемся на 76 и становимся на противоположный блок 
    inc si
    mov [si], 40h ;красим в красный
    inc si
    dec ax
    cmp ax, 0
    je columnsEnd
    jmp columns
    columnsEnd:
    mov ax, 40 ;ах выступает как счетчик по нижней линии
    secondLine:  ;инициализация нижней линии(сейчас стоим на последнем блоке столбца)
    mov [si], ' '
    inc si
    mov [si], 40h ;красим в красный цвет
    inc si
    dec ax    ;уменьшаем кол-во проходов
    cmp ax, 0
    je secondLineEnd  ;закончили - начинаем заполнение стакана(игрового поля)
    jmp secondLine
    secondLineEnd:
    mov cx, 2  ;чтобы получить координаты начала отрисовки стакана
    glass:
    mov al, 80 ;место отрисовки стакана
    mul cl
    add ax, 4  ; 3 строка 3 элемент
    mov si, ax
    mov [si], ' '
    inc si
    mov [si], 70h ;закрашиваем в серый
    add si, 21  ;смещаемся на ширину поля
    mov [si], ' '
    inc si
    mov [si], 70h ;красим противоположный левому элемент
    inc cx     ;некст строка
    cmp cx, 23    ;сравниваем с высотой игрового поля
    je glassEnd
    jmp glass
    glassEnd:    ;если конец становимся на верхнюю строку
    mov cx, 2
    glassBottom:
    mov al, 2
    mul cl
    add ax, 1760  ;находимся на ласт элементе левой границы стакана
    mov si, ax
    mov [si], ' ' ;установка символа для окраски
    inc si
    mov [si], 70h  ;красим символ в серый
    inc cx           ;некст
    cmp cx, 14         ;сравниваем с шириной стакана на конец
    je glassBottomEnd   ;продолжаем покраску границ поля
    jmp glassBottom
    glassBottomEnd: ;если конец 
    ;вывод "окна" счета справа от поля полем
    mov [190], 'S'  ;190-200 : SCORE:
    mov [192], 'c'
    mov [194], 'o'
    mov [196], 'r'
    mov [198], 'e'
    mov [200], ':'
    
    pop ds
    pop si
    pop ax
    pop cx
    ret
endp

initPlayField proc near ;инициализация игровго поля и границ
    push cx
    push bx
    push ax  
    xor ax, ax
    mov cx, 276   ;счетчик = размер поля
    mov bx, offset playField    ;адрес поля
    loopInit:         
    mov [bx], ah  ;инициализация поля(в данный момент на нем пусто:нет никаких границ)
    inc bx
    loop loopInit    ;икл по стакану
    mov cx, 0  ;обнуляем счетчик по размеру
    borders:    ;отрисовка физических боковых границ
    mov al, 12 ;верхний левый угол стакана
    mul cl
    mov bx, offset playField  ;адрес поля
    add bx, ax
    mov [bx], 60  ;элемент левого столбца
    add bx, 11  ;смещаемся на ширину на противоположный
    mov [bx], 60   ;элемент правого столбца
    inc cx         ; увеличиваем счетчик
    cmp cx, 23      ; пока не дойдем до самого низа по столбцам
    je bordersEnd    ;если конец - обнуляем
    jmp borders
    bordersEnd:
    mov cx, 0
    bottom:
    mov bx, offset playField ;адрес поля
    add bx, cx
    add bx, 264 ;последний элемент левого столбца
    mov [bx], 10
    inc cx    ;проход по низу
    cmp cx, 12 ;пока не вышли за пределы ширины стакана
    je bottomEnd  ;если конец - завершаем формирование границ стакана
    jmp bottom   ;иначе - идем дальше
    bottomEnd:
    pop ax
    pop bx
    pop cx
    ret
endp

displayPlayField proc near   ;отображение поля
    push ax
    push es
    push cx
    push di
    push si
    mov ax, 0B800h ;сегментный адрес видеопамяти
    mov es, ax
    mov cx, 20 ;счетчик по столбцам
    mov di, 167   ;первый элемент внутри поля после границы
    mov si, offset playField  ;помещаем поле заполненное нулями
    add si, 25
    loop1:
    push cx
    mov cx, 10 ;цикл по строке
    loop2:
    movsb  ;пересылаем из си в ди
    inc di ;тем самым заполняя пространство внутри стакана пустотой(нулями)
    loop loop2   ;используется дальше для обнаружения коллизи
    add di, 60  ;переход на новую строку
    add si, 2
    pop cx
    loop loop1  ;продолжаем заполнение
    pop si
    pop di
    pop cx
    pop es
    pop ax
    ret
endp

newFigure proc near ;процедура появления новой фигуры
    push ax
    push bx
    push cx
    push es
    push si
    push di  
    ;рандомная генераци фигур            
    mov ah, 2Ch  ;считываем время 
    int 21h
    mov bh, 7   ;7 фигур 
    xor ax, ax
    mov al, dl
    div bh ;делим на 7 для получения рандом фигуры
    mov bx, offset currentFigure
    mov [bx], ah
    ;задаем место спавна кента на фигуре    
    mov currentFigureX, 5  ;по иску
    mov currentFigureY, 2   ;по игрику
    mov ax, ds
    mov es, ax
    mov bx, offset currentFigure   ;сохраняем положение
    mov cx, [bx]
    mov al, 16 
    mul cl
    mov bx, offset figureShape  ;массив фигур для персылки
    mov si, bx
    add si, ax
    mov di, offset currentFigureShape ;массив для записи
    mov cx, 16  ;счетчик по размеру поля фигуры
    loop11:
    movsb    ;побайтно переносим зарондомленную фигуру в текущую фигуру
    loop loop11   ;продолжаем 
    pop di
    pop si
    pop es
    pop cx
    pop bx
    pop ax
    ret
endp

displayCurrentFigure proc near   ;вывод фигуры
    push ax
    push es
    push cx
    push di
    push si
    mov ax, 0B800h ;сегментный адрес видеопамяти
    mov es, ax 
    ;меняем положение фигуры
    mov bx, offset currentFigureY
    mov cx, [bx]
    mov al, 80
    mul cl  ;смещение на кол-во строк 
    mov di, ax
    mov bx, offset currentFigureX
    mov ax, [bx]
    add ax, ax
    add ax, 5   ;смещение по иксу
    add di, ax
    mov si, offset currentFigureShape
    mov cx, 4 ;два счтчика для отображения фигуры
    loop21:
    push cx
    mov cx, 4
    loop22:
    cmp di, 160
    jl opaque
    cmp [si], 00h  ;если пустота, а не блок - идем дальше
    je opaque
    movsb  ;побайтная персылка(отображение) фигуры на поле
    jmp notOpaque
    opaque:
    inc si    ;смотрим дальше
    inc di
    notOpaque:
    inc di
    loop loop22
    add di, 72
    pop cx
    loop loop21
    pop si
    pop di
    pop cx
    pop es
    pop ax
    ret
endp

checkCollision proc near  ;проверка на коллизиию
    push di
    push si
    push bx
    push cx  
    mov di, offset currentFigureShape ;храним адрес формы фигуры
    mov si, offset playField          ;адрес поля
    mov bx, offset currentFigureY     ;и положение фигуры по игрику
    mov ax, [bx]     
    mov bl, 12
    mul bl
    add si, ax
    mov bx, offset currentFigureX
    mov ax, [bx]
    cmp ax, 0FFh     ;если не 255 
    jne startCollisionCheck  ;проверка на объекты рядом
        mov ax, 01h 
        pop cx
        pop bx
        pop si
        pop di
        ret
    startCollisionCheck:  
    add si, ax   ;адрес положения фигуры по иксу
    xor bx, bx
    mov cx, 4  
    loop31:
        push cx
        mov cx, 4   ;счетчик по размеру(длине) фигуры
    loop32:
        cmp [bx + di], 00h  ;если рядом с фигурой
        je  notCollision    ;нет других объектов
        cmp [bx + si], 00h  ;тогда переходим на метку
        je  notCollision    ;notCollision
        mov ax, 01h  
        pop cx
        pop cx
        pop bx
        pop si
        pop di
        ret 
    notCollision:    
        inc di   ;сравниваем некст элемент тетрамино
        inc si   ;на объекты рядом
        loop loop32 ;сравнение 
        pop cx     
        add si, 8  ;адрес некст фигуры
        loop loop31  ;продолжаем проверку
    xor ax, ax
    pop cx
    pop bx
    pop si
    pop di
    ret
endp
 
placeFigure proc near    ;помещение фигуры на поле 
    push ax
    push bx
    push cx
    push es
    push si
    push di  
    mov ax, ds
    mov es, ax    
    ;передаем параметры фигуры и поле
    mov si, offset currentFigureShape 
    mov di, offset playField
    mov bx, offset currentFigureY 
    ;получение координат фигуры на поле
    mov ax, [bx]
    mov bl, 12
    mul bl
    add di, ax
    mov bx, offset currentFigureX
    mov ax, [bx]
    add di, ax
   
    mov cx, 4
    loop41:
    push cx
    mov cx, 4
    loop42:
    cmp [ds + si], 00h ;если не элдемент фигуры
    je opaque1  ;идем дальше
    movsb   ;иначе устанавливаем, побайтно передавая си в ди   
    jmp notOpaque1  ;повторяем
    opaque1:
    inc di
    inc si
    notOpaque1:
    loop loop42
    pop cx
    add di, 8 ;некст строка поля
    loop loop41  
    
    pop di
    pop si
    pop es
    pop cx
    pop bx
    pop ax    
    ret 
endp 
    
rotateFigure proc near   ;вращение фигуры   
    push ax
    push bx
    push cx
    
    mov bx, offset currentFigureShape  ;записываем текущую фигуру
     ;поворачиваем через перестройку фигуры
     ;
    mov ah, [bx]  
    mov ch, ah
    mov ah, [bx + 3]
    mov [bx], ah
    mov ah, [bx + 15]
    mov [bx + 3], ah
    mov ah, [bx + 12]
    mov [bx + 15], ah
    mov [bx + 12], ch
    
    mov ah, [bx + 1]
    mov ch, ah
    mov ah, [bx + 7]
    mov [bx + 1], ah
    mov ah, [bx + 14]
    mov [bx + 7], ah
    mov ah, [bx + 8]
    mov [bx + 14], ah
    mov [bx + 8], ch
    
    mov ah, [bx + 2]
    mov ch, ah
    mov ah, [bx + 11]
    mov [bx + 2], ah
    mov ah, [bx + 13]
    mov [bx + 11], ah
    mov ah, [bx + 4]
    mov [bx + 13], ah
    mov [bx + 4], ch
    
    mov ah, [bx + 5]
    mov ch, ah
    mov ah, [bx + 6]
    mov [bx + 5], ah
    mov ah, [bx + 10]
    mov [bx + 6], ah
    mov ah, [bx + 9]
    mov [bx + 10], ah
    mov [bx + 9], ch
    
    pop cx
    pop bx
    pop ax
    
    ret    
endp        
        
checkLines proc near   ;проверка линни на заполненость    
    push ax
    push bx
    push cx
    push es
    push si
    push di
    
    mov bx, offset playField   ;адрес поля
    add bx, 25
    mov cx, 20
    loop51:
    push cx 
    xor dx, dx
    mov cx, 10  ;счетчик по строке
    loop52:     
    cmp [bx], 00h  ;проверяем пуста ли строка
    je opaqueCheck
    inc dx 
    opaqueCheck: 
    inc bx       ;проходим дальше и сравниваем с 00h
    loop loop52
    add bx, 2
    cmp dx, 10
    jl notFull
    add score, 10  ;если есть линиия - очки +10
    call printScore    ;обновляем количество очков
    pop cx
    push cx
    push bx 
    mov ax, 22
    sub ax, cx
    push ax
    mov cl, 12
    mul cl
    mov bx, offset playField
    add bx, ax
    inc bx
    pop ax
    loop53:
    mov cx, 10  ;счетчик по строке
    loop54:     
    push ax
    mov ah, [bx - 12] ;начало линии
    mov [bx], ah 
    pop ax
    inc bx
    loop loop54 ;поэлементно удаляем линию
    sub bx, 22
    dec ax
    cmp ax, 1
    jg loop53
    
    pop bx
    notFull: ;если не полная
    pop cx     
    loop loop51 ;продолжаем поиск
    pop di
    pop si
    pop es
    pop cx
    pop bx
    pop ax
    ret 
endp        

printLose proc near ;вывод сообщения о проигрыше   
    push ds
    mov ax, 0b800h  ;сегментный адрес видеопамяти
    mov ds, ax  ;
    mov bx, 808 ;цент колодца    
    ;выводим сообщение
    mov [bx], 'Y'
    inc bx
    mov [bx], 07h ;помещаем по адресу управляющий символ BEL
    inc bx
    mov [bx], 'o'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'u'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], ' '
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'l'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'o'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 's'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'e'
    inc bx
    mov [bx], 07h
    inc bx
    mov bx, 884  ;центр колодца(игрового поля) 
    mov [bx], 'P'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'r'
    inc bx
    mov [bx], 07h
    inc bx        
    mov [bx], 'e'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 's'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 's'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], ' '
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'E'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'n'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 't'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'e'
    inc bx
    mov [bx], 07h
    inc bx
    mov [bx], 'r'
    inc bx
    mov [bx], 07h
    inc bx 
    mov [bx], ' '
    inc bx
    mov [bx], 07h
    inc bx
    pop ds
    ret
endp

welcomeScreen proc near  ;вывод сообщения при запуске
    push ax
    push bx 
    push dx
    push ds    
    mov ax, 0B800h  ;сегментный адрес
    mov ds, ax    ;видеопамяти
    xor bx, bx
    mov cx, 1000
    loopScreenWelcome:  ;цикл вывода "меню" c предварительным очищением экрана   
    mov [bx], ' '
    inc bx
    mov [bx], 07h
    inc bx
    loop loopScreenWelcome
    pop ds
    mov ah, 9h                   ;непосредственно вывод "меню"
    mov dx, offset messageWelcome
    int 21h          
    ;запуск из меню по нажатию ентера
    waitEnterWelcome: 
    mov ah, 1 ;нажата ли клавиша
    int 16h  
    jz waitEnterWelcome ;если не нажата - ждем дальше - терпим
    xor ah, ah  ;принимаем ввод
    int 16h
    cmp ah, 1Ch     ;если ентер
    je EnterWelcome
    cmp ah, 01h ;проверка на esc, если да - выход
    jne waitEnterWelcome
    mov ah, 00  ;видеорежим
    mov al, 03  ;40х25
    int 10h
    mov ah, 4Ch   ;непосредственно выход
    int 21h
    EnterWelcome:
    pop dx
    pop bx
    pop ax      
    ret
endp
        
main:
    mov ax, @data
    mov ds, ax
    
    mov ah, 00  ;установить видеорежим
    mov al, 01   ;40х25 16-цветный текстовый режим
    int 10h    ;BIOS прерывание
    call welcomeScreen    ;выводим меню
restart:    
    mov score, 0    ;обнуляем счет
    mov previousTime, 0    ;и время
    call initScreen      ; инициализация экрана
    call initPlayField    ;и отрисовка игрового поля
    call newFigure         ; создаем фигуры
    call displayPlayField   ; отображаем поле
    call displayCurrentFigure; и фигуру
    call printScore           ; выводим информацию с текущим счетом
    mov ah, 01h
    xor cx, cx
    xor dx, dx
   int 1ah
    start:
    mov ah, 1     ;функция проверки клавиатуры (ожидание нажатие на любую клавишу)
    int 16h
    jz noKeyPressed     ;ничего не было нажато
    xor ah, ah           ;ожидание ввода
    int 16h
    cmp ah, 4Dh           ;если стрелка вправо
    jne notD
    mov bx, offset currentFigureX ;смещение вправо
    inc [bx]
    push ax
    call checkCollision   ;проверка на фигуру или край поля справа
    cmp ax, 00h     ;если справа пусто
    je notColD 
    mov bx, offset currentFigureX
    dec [bx]  
    notColD: 
    pop ax       ;освобождаем ах
    call displayPlayField       ; и продолжаем отрисовку поля
    call displayCurrentFigure    ; и фигур
    notD:     ;проверка оставшихся клавиш
    cmp ah, 4Bh  ;стрелка влево
    jne notA
    mov bx, offset currentFigureX  ;передвигаем влево
    dec [bx]
    push ax
    call checkCollision ;проверка на объекты слева
    cmp ax, 00h
    je notColA 
    mov bx, offset currentFigureX
    inc [bx]
    notColA: 
    pop ax
    call displayPlayField
    call displayCurrentFigure
    notA:
    cmp ah, 50h    ;стрелка вниз
    jne notS
    mov bx, offset currentFigureY  ;передвигаем по у вниз
    inc [bx]
    push ax
    call checkCollision  ;проверка коллизии
    cmp ax, 00h
    je notColS 
    mov bx, offset currentFigureY
    dec [bx]
    call placeFigure   ;установка фигуры 
    call checkLines    ;  проверяем линию
    call newFigure     ;  спавним нового кента
    call checkCollision ; проверяем есть ли свободное место
    cmp ax, 00h          ; в стакане
    jne youLose             ;если нет - то гг :(
    notColS: 
    pop ax
    call displayPlayField
    call displayCurrentFigure
    notS:
    cmp ah, 48h   ;стрелка вверх
    jne notW
    call rotateFigure  ;при нажатии - вращаем
    push ax               
    call checkCollision   ;проверяем чтобы ниче не мешало вращать
    cmp ax, 00h
    je notColW       
    call rotateFigure     ;вращение до исходного состояния
    call rotateFigure
    call rotateFigure
    notColW:
    pop ax
    call displayPlayField
    call displayCurrentFigure
    notW:
    cmp ah, 01h     ;если esc
    jne notEscape
    jmp exit        ;выход
    notEscape:     ;никакая из нужных клавиш не нажата
    noKeyPressed: 
    ;если ничего не нажато, то фигура будет сама падать
    ;время падения через таймер
    mov ah, 00h   ;узнаем текущее значение счетчика времени
    int 1ah
    push dx  ;сохраняем это значение
    mov ax, previousTime   ;записываем старое время в начальной позиции
    sub dx, ax
    mov ax, dx   ;записываем разницу и получаем время падения фигуры(1 тик)
    pop dx
    cmp ax, 9 ;падает каждые 9 тиков 
    jl notDrop
    mov previousTime, dx  ;и сохраняем его
    mov bx, offset currentFigureY
    inc [bx]
    push ax
    call checkCollision ;проверка на объекты рядом
    cmp ax, 00h
    je notColDrop ;если ничего нет то not collision drop
    mov bx, offset currentFigureY
    dec [bx]     ;если нет, то ретурним фигуру на ее позицию до проверка
    call placeFigure  ;ставим
    call checkLines    ;проверяем
    call newFigure       ;запускаем нового кента
    call checkCollision    ;проверяем есть ли место в стакане
    cmp ax, 00h           ;если не "пустота"
    jne youLose             ;выводим сообщение о проигрыше
    notColDrop:  ;все ок - плывем дальше
    pop ax
    call displayPlayField
    call displayCurrentFigure
    notDrop:
    notUpdate:
    jmp start
youLose:
    call printLose  ;сообщение о проигрыше
waitEnter: 
    mov ah, 1     ;функция проверки клавиатуры
    int 16h
    jz waitEnter  ;ожидание энтера
    xor ah, ah      ;ждем ввод
    int 16h
    cmp ah, 1Ch      ;сравниваем символ с enter'ом
    jne notEnter   ;если нет, то ожидаем ввод
    jmp restart    ;если ентер - начинай заново
    notEnter:
    cmp ah, 01
    jne waitEnter:      
exit:      
;выход из программы
mov ah, 00 
mov al, 03
int 10h
mov ah, 4Ch  ;непосредственно выход
int 21h
end main