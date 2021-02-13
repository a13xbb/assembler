
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
;
CR		EQU		13
LF		EQU		10
Space	EQU		20h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_letter	macro	letter    ;macross to print letter
	push	AX
	push	DX
	mov	DL, letter         
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_mes	macro	message        ;macross to print message
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,	09h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg	DB message,'$'
	nxt:
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;========================================================================
start:
print_letter	CR                  ;print cret
print_letter	LF                  ;print new line
print_mes	'Input File Name > '	
	mov		AH,	0Ah                 
	mov		DX,	offset	FileName
	int		21h                     ;input interruption
print_letter	CR
print_letter	LF
;===========================================================================
	xor	BH,	BH                      ;clearing BH
	mov	BL,  FileName[1]            ;move real size of file name to BL
	mov	FileName[BX+2],	0           ;moving NULL after the end of file name
;===========================================================================
	mov	AX,	3D02h		; Open file for read/write
	mov	DX, offset FileName+2        
	int	21h                         ;printing name of file
	jnc	openOK                      ;if CF flag==0, jump to print OK
print_letter	CR
print_letter	LF
print_mes	'can not open '
    mov	FileName[BX+2],	'$'         ;moving '$' after the end of file name to print it with int21h/09h
    mov		AH,	09h
	mov		DX,	offset	FileName+2  ;moving pointer of the first letter of file name
	int		21h
	int	20h
;===========================================================================
openOK:
print_letter	CR
print_letter	LF 
    mov	FileName[BX+2],	'$'   
    mov		AH,	09h
	mov		DX,	offset	FileName+2
	int		21h
print_mes	' is opened successfully'
	mov		AX,	4C00h               ;stops programm and closes all files 
	int 	21h
;
FileName	DB		14,0,14 dup (0) ;14 is max size, 0 is real size of written name(changes while input), 14 dup(0) pastes all 0 14 times
	code_seg ends
         end start
	
	