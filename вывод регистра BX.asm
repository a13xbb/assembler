org 100h

mov cx, 0
begin:
mov ah, 1
int 21h 
cmp al,030h       ;checks if input is correct
jl error:          
cmp al, 039h
jg comp:   
continue:
cmp al, 046h
jg error:


cmp al, 03Ah
jl read_num:         ;checks if it is 1-9 or A-F
sub al, 07h


read_num:
sub al, 030h
add bl, al  
add cx, 1
cmp cx,4
je print:           ;put the input into BX register
shl bx, 4
cmp cx, 4
jne begin:



print:
 
 
mov dl, 0Ah
mov ah, 2
int 21h
mov dl, 0Dh    
int 21h  
mov ah, 09h
mov dx, offset beginmsg
int 21h

mov cx, 12

call shift_and_print
call shift_and_print
call shift_and_print
call shift_and_print    

mov ah, 09h
mov dx, offset endmsg
int 21h

mov ah, 9
int 20h
int 21h

shift_and_print proc
; shift
mov dx, bx
shr dx, cl
and dl, 0Fh
sub cx, 4

; print
add dl,030h
cmp dl,03Ah
jl print_num:
add dl, 07h

print_num:
mov ah, 02h
int 21h
ret
shift_and_print endp

ret

error: 
mov dl, 0Ah
mov ah, 2
int 21h                   ;error message
mov dl, 0Dh    
int 21h                      
mov ah, 09h
mov dx, offset msg
int 21h

ret

msg db "wrong input$" 
beginmsg db "input number is $" 
endmsg db "h$"



comp:
cmp al, 041h 
jl error: 
jmp continue:
ret
