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
   	;mov 	CL,ES:[80h]   	; addres of length parameter in psp
								; is it 0 in buffer?
   	;cmp 	CL,0
   	;jne 	cont4        		; yes
;----------------------------------------------------------------------------
	print_mes 'Please, enter file name' ;если имя файла не введено параметром, запрашиваю его
	print_letter CR
	print_letter LF
	
    input_str FileName
	
    get_first_symbol FileName

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
	print_letter CR
	print_letter LF
	
	
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
	input_str string1

	print_letter CR
	print_letter LF
	input_str string2

	mov DI, offset Buffer
	call Len
	mov CX, DI
	mov DI, offset Buffer
	;call print_reg_CX
	print_letter CR
	print_letter LF
	

cycle1:
	mov SI, DI
	push DI
	mov DI, SI
	mov SI, offset string1 + 2
	push CX
	xor CX, CX
	mov CL, string1[1]
	xor AX, AX
	xor BX, BX
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
	je end_cycle
	pop CX
	pop DI
	cmp CX, 0
	je not_found
	inc DI
loop cycle1

not_found:
	print_mes 'string not found'
	mov	AX, 4C00h
	int 	21h


end_cycle:
	sub DI, offset Buffer
	mov CX, DI
	sub CL, string1[1]
	mov Index, CX
	
	print_letter CR
	print_letter LF
	call print_reg_CX


	
	
	mov	AX, 4C00h
	int 	21h

									
 int 20h
;----------------------------------------------------------------------------








cont4:	
									;if there is a filename in psp
	xor	BH,	BH
	;mov	BL,  tail[0]
	;mov	tail[BX+1],	0
	mov	BL, ES:[80h]		 
	mov	byte ptr [BX+81h],	0
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   	mov 	CL,ES:80h    	
   	xor 	CH,CH       	
   	cld             		
  	mov 	DI, 81h     	
   	mov 	AL, ' '        
	repe    scasb   			
							
							
        dec DI        	
;-------------------------------------------------------------------------
	mov	AX,3D02h		; Open file for read/write
	mov	DX,DI
	int	21h
	jnc	openOK
print_mes	'openERR'
	int	20h
;===========================================================================
openOK:
print_mes	'openOK'
	mov	AX,4C00h
	int 	21h
;
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
    mov al,'$'    ;искать 0
    mov bx,di   ;сохранить начальный адрес строки
    mov cx,-1   ;максимально возможная длина строки 0FFFFh
    repne scasb ;искать
    sub di,bx   ;разница адресов между началом строки и
            ;найденым 0 = длина строки + 1
    dec di      ;DI=DI-1=длина строки
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
	code_seg ends
         end start