code_seg segment
        ASSUME  CS:code_seg,DS:code_seg,ES:code_seg

	org 100h
begin:	
	jmp start
	
print_hex	proc	near
	and	DL,0Fh
	add	DL,30h
	cmp	DL,3Ah
	jl	$print
	add	DL,07h
$print:	
	mov ah, 02h
	int 21h
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
	
start:
   	mov 	CL,ES:[80h]   	; addres of length parameter in psp						;is it 0 in buffer?
   	cmp 	CL,0
	xor	BH,	BH
	;mov	BL,  tail[0]
	;mov	tail[BX+1],	0
	mov	BL, ES:[80h]	
	mov FileName[1], BL
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
	
	mov AH, 41h
	mov DX, offset FileName + 2
	int 21h
	
	;dec DX
	;mov BX, DX
	;mov AL, [BX]
	;xor AH, AH
	;call print_reg_AX
	
	int 20h
	FileName	DB		30,0,30 dup (0)
	code_seg ends
end begin