.286
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
start:
    jmp begin
;----------------------------------------------------------------------------
int_2Fh_vector  DD  ?
old_21h         DD  ?

CR	EQU 13
LF	EQU 10
SPACE	EQU 20h
ext DB 'txt,lst,map$'

ext_name DB ?
delete_msg DB 'can not delete file with such extension$'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	pushf
	call dword ptr cs:old_21h
	pop	DX
	pop	AX
endm

print_hex	proc	far
	and	DL,0Fh
	add	DL,30h
	cmp	DL,3Ah
	jl	$print
	add	DL,07h
$print:	
	mov ah, 02h
	pushf
	call dword ptr cs:old_21h
   ret	
print_hex	endp

print_reg_AX	proc	near
	push	AX
	push	BX
	push	CX
	push	DX
;
	mov	BX,AX
	mov 	AH,02
   	mov     DL,BH
	rcr	DL,4
	call 	print_hex
   	mov DL,BH
	call	print_hex
;
	mov 	DL,BL
	rcr	DL,4
	call 	print_hex
	mov	DL,BL
	call	print_hex
;
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret
print_reg_AX	endp

;----------------------------------------------------------------------------
;============================================================================
new_21h proc far
;		
		jmp start_proc
		filename DW ?
		ext_index DB ?
		start_proc:
	                      
        cmp        ah,41h           ; Если вызвали функцию 41h (удалить
        je         its_41h           ; файл)
        cmp        ax,7141h         ; или 7141h (удалить файл с длинным именем),
        je         its_41h            ; начать наш обработчик,
        jmp        short itsnot_41h  ; иначе - передать управление
	its_41h:
	
		
		push ds
		push cs
		pop ds
		mov [filename], dx
		pop ds
		
		
		
		mov al, '.'
		mov di, dx
		mov cx, 20
		repne scasb
		
		
		
		push ds
		push cs
		pop ds
		mov si, offset ext
		pop ds
	
		mov cx,3
cycle1:
		mov bx, di
		mov dl, byte ptr [bx]
		push di

		push ds
		push cs
		pop ds
	
		mov bx, si
		mov al, byte ptr [bx]
		pop ds
		
		;mov ah, 09h
		;pushf
		;call dword ptr cs:old_21h
		;push dx
		;mov dl, al
		;pushf
		;call dword ptr cs:old_21h
		;pop dx
		cmp al, '$'
		je need_to_delete
		cmp al, dl
		jne next_ext
		pop di
		inc di
		push ds
		push cs
		pop ds
		inc si
		pop ds
		dec cx
		cmp cx, 0
		je equal_extensions
		jmp cycle1
		next_ext:
		pop di
		push ds
		push cs
		pop ds
		inc si
		pop ds
		mov cx, 3
jmp cycle1
		
		
	equal_extensions:
		jmp cnt2
		cnt2:
		
		push ds
		push cs
		pop ds
		mov dx, offset delete_msg   
		mov ah, 09h
		int 21h
		pop ds
		;pushf
		;call dword ptr cs:old_21h
		
		jmp endproc
	

	itsnot_41h:
		
		pushf
        call dword ptr cs:old_21h ; и передать управление
		
                                    ; предыдущему обработчику INT 21h
		endproc:
        iret
	need_to_delete:
		pop di
		
		; push ds
		; push cs
		; pop ds
		; mov dx, filename
		; mov di, dx
		; mov cx, 100
		; mov al, ' '
		; repe scasb
		; dec di
		; mov ah, 09h
		; mov dx, di
		; pop ds
		; pushf
        ; call dword ptr cs:old_21h
		
		push ds
		push cs
		pop ds
		mov dx, filename
		mov di, dx
		mov cx, 100
		mov al, ' '
		repe scasb
		dec di
		mov ah, 41h
		mov dx, di
		pop ds
		pushf
        call dword ptr cs:old_21h ; и передать управление
                                    ; предыдущему обработчику INT 21h
									
		
		
        iret
	
new_21h     endp
;===========================================================================
;============================================================================
int_2Fh proc far
    cmp     AH,09Ch         ; Наш номер?
    jne     Pass_2Fh        ; Нет, на выход
    cmp     AL,00h          ; Подфункция проверки на повторную установку?
    je      inst            ; Программа уже установлена
    cmp     AL,01h          ; Подфункция выгрузки?
    je      unins           ; Да, на выгрузку
    jmp     short Pass_2Fh  ; Неизвестная подфункция - на выход
inst:
    mov     AL,0FFh         ; Сообщим о невозможности повторной установки
    iret
Pass_2Fh:
    jmp dword PTR CS:[int_2Fh_vector]
;
; -------------- Проверка - возможна ли выгрузка программы из памяти ? ------
unins:
    push    BX
    push    CX
    push    DX
    push    ES
;
    mov     CX,CS   ; Пригодится для сравнения, т.к. с CS сравнивать нельзя
    mov     AX,3521h    ; Проверить вектор 1C
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:new_21h
    jne     Not_remove
;
    mov     AX,352Fh    ; Проверить вектор 2Fh
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:int_2Fh
    jne     Not_remove
; ---------------------- Выгрузка программы из памяти ---------------------
;
    push    DS
;
    lds     DX, CS:old_21h   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr old_1C
;    mov     DS, word ptr old_1C+2
    mov     AX,2521h        ; Заполнение вектора старым содержимым
    int     21h
;
    lds     DX, CS:int_2Fh_vector   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr int_2Fh_vector
;    mov     DS, word ptr int_2Fh_vector+2
    mov     AX,252Fh
    int     21h
;
    pop     DS
;
    mov     ES,CS:2Ch       ; ES -> окружение
    mov     AH, 49h         ; Функция освобождения блока памяти
    int     21h
;
    mov     AX, CS
    mov     ES, AX          ; ES -> PSP выгрузим саму программу
    mov     AH, 49h         ; Функция освобождения блока памяти
    int     21h
;
    mov     AL,0Fh          ; Признак успешной выгрузки
    jmp     short pop_ret
Not_remove:
    mov     AL,0F0h          ; Признак - выгружать нельзя
pop_ret:
    pop     ES
    pop     DX
    pop     CX
    pop     BX
;
    iret
int_2Fh endp
;============================================================================
begin:
        mov CL,ES:80h       ; Длина хвоста в PSP
        cmp CL,0            ; Длина хвоста=0?
        je  check_install   ; Да, программа запущена без параметров,
                            ; попробуем установить
        xor CH,CH       ; CX=CL= длина хвоста
        cld             ; DF=0 - флаг направления вперед
        mov DI, 81h     ; ES:DI-> начало хвоста в PSP
        mov SI,offset key   ; DS:SI-> поле key
        mov AL,' '          ; Уберем пробелы из начала хвоста
repe    scasb   ; Сканируем хвост пока пробелы
                ; AL - (ES:DI) -> флаги процессора
                ; повторять пока элементы равны
        dec DI          ; DI-> на первый символ после пробелов
        mov CX, 4       ; ожидаемая длина команды
repe    cmpsb   ; Сравниваем введенный хвост с ожидаемым
                ; (DS:DI)-(ES:DI) -> флаги процессора
        jne check_install ; Неизвестная команда - попробуем установить
        inc flag_off
; Проверим, не установлена ли уже эта программа
check_install:
        mov AX,09C00h   ; AH=09Ch номер процесса 9Ch
                        ; AL=00h -дать статус установки процесса
        int 2Fh         ; мультиплексное прерывание
        cmp AL,0FFh
        je  already_ins ; возвращает AL=0FFh если установлена
;----------------------------------------------------------------------------
    cmp flag_off,1
    je  xm_stranno
;----------------------------------------------------------------------------
    mov AX,352Fh                      ;   получить
                                      ;   вектор
    int 21h                           ;   прерывания  2Fh
    mov word ptr int_2Fh_vector,BX    ;   ES:BX - вектор
    mov word ptr int_2Fh_vector+2,ES  ;
;
    mov DX,offset int_2Fh           ;   получить смещение точки входа в новый
                                    ;   обработчик на DX
    mov AX,252Fh                    ;   функция установки прерывания
                                    ;   изменить вектор 2Fh
    int 21h  ; AL - номер прерыв. DS:DX - указатель программы обработки прер.
;============================================================================
    mov AX,3521h                        ;   получить
                                        ;   вектор
    int 21h                             ;   прерывания  1C
    mov word ptr old_21h,BX    ;   ES:BX - вектор
    mov word ptr old_21h+2,ES
	
	
    mov DX,offset new_21h           ;   получить смещение точки входа в новый
	
   
                                ;   обработчик на DX
    mov AX,2521h                        ;   функция установки прерывания
                                        ;   изменить вектор 1C
    int 21h;   AL - номер прерыв. DS:DX - указатель программы обработки прер.
	
    mov DX,offset msg1  ; Сообщение об установке
    call    print
;----------------------------------------------------------------------------
    mov DX,offset   begin           ;   оставить программу ...
    int 27h                         ;   ... резидентной и выйти
;============================================================================
already_ins:
        cmp flag_off,1      ; Запрос на выгрузку установлен?
        je  uninstall       ; Да, на выгрузку
        lea DX,msg          ; Вывод на экран сообщения: already installed!
        call    print
        int 20h
; ------------------ Выгрузка -----------------------------------------------
 uninstall:
        mov AX,09C01h  ; AH=09Ch номер процесса 9Ch, подфункция 01h-выгрузка
        int 2Fh             ; мультиплексное прерывание
        cmp AL,0F0h
        je  not_sucsess
        cmp AL,0Fh
        jne not_sucsess
        mov DX,offset msg2  ; Сообщение о выгрузке
        call    print
        int 20h
not_sucsess:
        mov DX,offset msg3  ; Сообщение, что выгрузка невозможна
        call    print
        int 20h
xm_stranno:
        mov DX,offset msg4  ; Сообщение, программы нет, а пользователь
        call    print       ; дает команду выгрузки
        int 20h
;----------------------------------------------------------------------------
key         DB  '/off'
flag_off    DB  0
msg         DB  'already '
msg1        DB  'installed',13,10,'$'
msg4        DB  'just '
msg3        DB  'not '
msg2        DB  'uninstalled',13,10,'$'
counter DW 0
;============================================================================
PRINT       PROC NEAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP

old_print proc near
	MOV AH,09H
    call dword ptr CS:[old_21h]
    RET
old_print endp
;;============================================================================
code_seg ends
         end start