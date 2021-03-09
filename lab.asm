code_seg segment
        ASSUME  CS:code_seg,DS:code_seg,ES:code_seg
;	org	80h
;tail	DB	128 dup(0)
	org 100h
;
CR	EQU 13
LF	EQU 10
SPACE	EQU 20h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_mes	macro	message
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,09h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg DB message,'$'
	nxt:
endm

print_name	macro	name
	push	AX
	push	DX
	mov	DX, offset name + 2
	mov	AH,09h
	int	21h
	pop	DX
	pop	AX
endm

print_buf macro name
push	AX
	push	DX
	mov	DX, offset name
	mov	AH,09h
	int	21h
	pop	DX
	pop	AX
endm

get_first_symbol 	macro  filename             ;первый символ отличный от пробела перемещается в DI
    xor 	CX,CX
	mov 	CL, filename[1]   	
   	xor 	CH,CH       	
   	cld
	mov 	DI, offset filename + 2     		;перехожу на первый символ отличный от пробела
   	mov 	AL, ' '        
	repe    scasb
	dec DI
	;mov SI, DI
	;xor CX, CX
	;mov CL, filename[1]
	;add CX, 2
	;sub CX, SI
	;mov DI, offset filename + 2
	;rep movsb
endm

input_str	macro  filename
    xor AX,AX
	mov	AH,	0Ah               ;читаю имя файла с ввода
	mov	DX,	offset	filename
	int	21h
	xor BX,BX
	mov BL, filename[1]
	mov filename[BX+2], '$'
endm

open_file macro filename
	mov AH, 3Dh
	mov AL, 2
	mov DX, offset filename + 2
	int 21h
	jnc ok
	mov AH,09h
	mov DX, offset open_err
	int 21h
	int 20h
	ok:
	mov Handler, AX
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;========================================================================

start:
	;mov	SI,80h
	;mov 	AH,02	
	;mov 	CX,16

;------- check string of parameters -------------------------
   	mov 	CL,ES:[80h]   	; addres of length parameter in psp
								;is it 0 in buffer?
   	cmp 	CL,0
	je continue_with_no_parameter
   	jmp continue_with_parameter        	
;----------------------------------------------------------------------------

continue_with_no_parameter:
	print_mes 'Please, enter file name: ' ;если имя файла не введено параметром, запрашиваю его
	
    input_str FileName
	print_letter CR
	print_letter LF
	
    get_first_symbol FileName


continue_with_FileName_as_parameter:
	mov	AX,	3D02h		; открываю файл чтобы проверить, существует ли он
	mov	DX, DI    
	int	21h                         
	jnc      file_exists                ;if CF flag==0, it exists
	print_letter	CR
	print_letter	LF
	print_mes	'file does not exist '
	int 20h


file_exists:
	mov 	Handler, AX
	mov	AH,	3Eh		; закрываю файл
	mov	BX, Handler        
	int	21h        
	
	print_mes 'If you want to rename file, enter new file name: '
    input_str FileName2
	
	cmp FileName2[1], 0h 		    ;если нового имени файла нет, то продолжить без переименовывания
	je continue_without_renaming

	get_first_symbol FileName
    mov DX, DI
    get_first_symbol FileName2
	mov AH, 56h ;для переименования
    int 21h ; прерывание

	mov SI, offset FileName2   ;FileName = FileName2
	mov DI, offset FileName
	mov CL, FileName2[1]
	add CX, 2
	rep movsb
	

continue_without_renaming:
	
	open_file FileName         ;открываю файл
	mov AH, 3Fh
	mov BX, Handler
	mov CX, 65535
	mov DX, offset Buffer	   
	int 21h					   ;читаю текст файла в Buffer
	xor BX, BX
	mov BX, AX 
	add BX, offset Buffer
	mov byte ptr[BX], '$'

	;print_letter CR
	;print_letter LF
	;mov	DX, offset Buffer
	;mov	AH,09h
	;int	21h

	print_letter CR
	print_letter LF
	print_mes 'Enter substring you want to change: '
	input_str string1
	mov DI, offset string1 + 2			;проверяю 1 подстроку на пустоту
	call Len
	cmp DI, 0
	jne continue1
	print_letter CR
	print_letter LF
	print_mes 'Empty substring input'   ;error
	mov	AX, 4C00h
	int 	21h
	int 20h

continue1:

	print_letter CR
	print_letter LF
	print_mes 'Enter new substring: '
	input_str string2					;проверяю 2 подстроку на пустоту
	mov DI, offset string2 + 2
	call Len
	cmp DI, 0
	jne continue2
	print_letter CR
	print_letter LF
	print_mes 'Empty substring input'   ;error
	mov	AX, 4C00h
	int 	21h
	int 20h

continue2:

	xor AX, AX
	xor BX, BX
	mov AL, string1[1]
	mov BL, string2[1]
	cmp AL, BL
	jne continue3
substrings_have_same_length:		
	mov CL, string1[1] 	
	xor CH, CH		
	mov DI, offset string1 + 2
	mov SI, offset string2 + 2
	comparing_substrings:
	mov AX, ES:[DI]
	mov BX, ES:[SI]
	cmp AX, BX
	jne continue3
	inc DI
	inc SI
	dec CX 
	cmp CX, 0
	je substrings_are_equal
	jmp comparing_substrings
	
	substrings_are_equal:
	print_letter CR
	print_letter LF
	print_mes 'Substrings are equal'    ;error
	mov	AX, 4C00h
	int 	21h
	int 20h

continue3:

	print_letter CR
	print_letter LF

	mov Flag, 0
main:
	mov DI, offset Buffer
	call Len
	mov CX, DI
	mov DI, offset Buffer
	;call print_reg_CX
	; print_letter CR
	; print_letter LF
	

cycle1:							;finding first index of substring
	mov SI, DI
	push DI
	mov DI, SI
	mov SI, offset string1 + 2
	push CX
	xor CX, CX
	mov CL, string1[1]
	xor AX, AX
	xor BX, BX
	; print_letter '#'
	; print_letter CR
	; print_letter LF
	in_cycle:
		mov BL, ES:[DI]
		mov AL, ES:[SI]
		; call print_reg_BX
		; print_mes ' ?  '
		; call print_reg_AX
		; print_letter CR
		; print_letter LF
		cmp BL, AL
		jne next_iterration
		inc DI
		inc SI
	loop in_cycle
	next_iterration:
	cmp CX, 0
	jne continue4
	jmp end_cycle
	continue4:
	pop CX
	pop DI
	cmp CX, 0
	je ending
	inc DI
loop cycle1

ending:
	cmp Flag, 0
	je substring_not_found

	MOV AH, 3Eh        ;закрываю старый файл
	MOV BX, Handler
	INT 21h

	mov AH, 41h			;удаляю старый файл
	mov DX, offset FileName + 2
	int 21h

	MOV AH, 3Ch 		;создаю новый файл
	MOV CX, 0
	MOV DX, offset FileName + 2
	INT 21h

	MOV AH, 3Dh ; функция OPEN
	MOV AL, 2 ; Доступ для чтения/записи
	MOV DX, offset FileName + 2 ; Адрес имени файла
	INT 21h
	;Jc error1
	MOV Handler, AX

	xor CX, CX
	xor DX, DX
	mov AH, 42h
	mov AL, 0
	mov BX, Handler
	int 21h
	jc seek_err

	
	MOV AH, 40h ; Функция записи
	MOV BX, Handler ; Дескриптор
	MOV CX, BufLen ; Число записываемых байтов
	;call print_reg_CX
	MOV DX, offset Buffer ; Адрес буфера
	INT 21h

	
	print_buf Buffer

	mov	AX, 4C00h
	int 	21h
	int 20h
	; write_error:
	; print_mes 'Write error'
	; mov	AX, 4C00h
	; int 21h
	; int 20h
	substring_not_found:
	print_mes 'Substring is not found'     ;error
	mov	AX, 4C00h
	int 	21h

	seek_err:
	print_mes 'seek err'
	mov	AX, 4C00h
	int 21h


end_cycle:
	mov Flag, 1
	sub DI, offset Buffer
	mov CX, DI
	sub CL, string1[1]
	mov Index, CX
	; print_letter CR
	; print_letter LF
	; call print_reg_CX
	mov DI, offset newstring
	mov SI, offset Buffer
	cld
	rep movsb

	mov SI, offset string2 + 2
	mov CL, string2[1]
	cld
	rep movsb

	mov SI, offset Buffer
	add SI, Index
	mov BL, string1[1]
	xor BH, BH
	add SI, BX
	push DI
	mov DI, offset Buffer
	call Len
	mov CX, DI
	pop DI
	sub CL, string1[1]
	sub CX, Index
	add CX, 1
	cld
	rep movsb
	
	mov DI, offset newstring
	call Len
	mov CX, DI
	mov SI, offset newstring 
	mov DI, offset Buffer
	cld
	rep movsb
	mov byte ptr[DI], '$'
	sub DI, offset Buffer
	mov BufLen, DI
	
	jmp main
	
	mov	AX, 4C00h
	int 	21h

									
 int 20h
;----------------------------------------------------------------------------








continue_with_parameter:	
									;if there is a filename in psp
	xor	BH,	BH
	;mov	BL,  tail[0]
	;mov	tail[BX+1],	0
	mov	BL, ES:[80h]		 
	mov	byte ptr [BX+81h],	'$'
	
	mov CX, ES:[80h]				;пропускаю все пробелы в параметре
	mov DI, 81h
	mov AL, ' '
	cld
	rep scasb

	mov CX, BX
	add CX, 81h
	dec DI
	sub CX, DI
	mov SI, DI
	mov DI, offset FileName + 2
	rep movsb
	mov DI, offset FileName + 2
	jmp continue_with_FileName_as_parameter
	; print_name FileName


	mov	AX, 4C00h
	int 	21h

									
 int 20h





print_hex	proc	near
	and	DL,0Fh
	add	DL,30h
	cmp	DL,3Ah
	jl	$print
	add	DL,07h
$print:	
	int	21H
   ret	
print_hex	endp	
;
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
;
print_reg_BX	proc near
push	AX
mov	AX,BX
call	print_reg_AX
pop		AX
ret
print_reg_BX	endp
;
print_reg_CX	proc near
push	AX
mov	AX, CX
call	print_reg_AX
pop		AX
ret
print_reg_CX	endp
;
Len proc    near
	push AX
	push BX
	push CX
    mov al,'$'    ;искать 0
    mov bx,di   ;сохранить начальный адрес строки
    mov cx,-1   ;максимально возможная длина строки 0FFFFh
    repne scasb ;искать
    sub di,bx   ;разница адресов между началом строки и
            ;найденым 0 = длина строки + 1
    dec di      ;DI=DI-1=длина строки
	pop CX
	pop BX
	pop AX
    ret
Len endp
;
FileName	DB		30,0,30 dup (0)
FileName2	DB		30,0,30 dup (0)
open_err DB 13,10, 'open error','$'
Handler DW ?
Index DW ?
Buffer DB 256 dup (' ')
string1 DB 200, 0, 200 dup (' ')
string2 DB 200, 0, 200 dup (' ')
BufLen DW ?
Flag DW ?
newstring DB 256 dup (' ')
	code_seg ends
         end start


