code_seg segment
        ASSUME  CS:code_seg,DS:code_seg,ES:code_seg

	org 100h
start:
   	mov 	CL,ES:[80h]   	; addres of length parameter in psp						;is it 0 in buffer?
   	cmp 	CL,0
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
	
	mov AH, 41h
	mov DX, offset FileName + 2
	int 21h
	
	int 20h
	FileName	DB		30,0,30 dup (0)
	code_seg ends
end start
