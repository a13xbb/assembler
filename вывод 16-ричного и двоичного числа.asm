code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg, SS: code_seg
  org 100h
  
start:
  mov BX, 0F21Bh
  mov  AL,  BH
  mov  SI,  offset  OutHex
  call ascii_byte
  mov  AL,  BL
  call ascii_byte
  mov  AH,09h
  mov  DX,  offset  OutHex
  int  21h 
  mov ah, 02h
  mov dx, 0Ah
  int 21h
  mov dx, 0Dh
  int 21h 
  jmp print_bin:
  int 20h
ascii_byte  proc
  push  AX
  shr    AL,4
  call  ascii_tetr
  pop    AX
  call  ascii_tetr
  ret
  endp
ascii_tetr  proc
  push  BX
  and    AL,  0Fh
mov bx, offset lookupTable
  xlat
  mov    byte ptr [SI],  AL
  inc  SI
  pop  BX 
  ret
endp


print_bin: 
  mov CX, 7
  mov  AL,  BH
  mov  SI,  offset  OutBin 
  call ascii_byte_2  
  mov CX, 7
  mov  AL,  BL
  call ascii_byte_2
  mov  AH,09h
  mov  DX,  offset  OutBin
  int  21h 
  
  int 20h
ascii_byte_2  proc
  ascii_byte2:
  push AX
  shr AL,Cl
  sub CX, 1
  call  ascii_tetr_2
  pop    AX  
  cmp cx, -1
  jne ascii_byte2
  ret
endp
ascii_tetr_2  proc
  push  BX
  and    AL,  01h
mov bx, offset lookupTable
  xlat
  mov    byte ptr [SI],  AL
  inc  SI
  pop  BX 
  ret
endp



lookupTable db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h ;0-9
db 41h, 42h,43h,44h,45h,46h ;A-F
OutHex  DB  ?,?,?,?,'$' 
OutBin DB ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'$'
code_seg  ends
end start 





