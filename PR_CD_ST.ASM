.model tiny
.code
org 100h

command_string_len_addr         equ 80h
command_string_text_addr        equ 81h
max_number_of_symbols_in_string equ 80
max_number_of_symbols_in_column equ 26
color_attr_green				equ 02h

Start:
			call GetCommandLine
			jc Exit				;CF = 1 => empty string

			push cx
			mov ax, 0b800h
			mov es, ax

			call ClearScreen
			pop cx
			mov ah, color_attr_green			; giving attribute

			call CalculateCenteredPosition

			push di				; needed after drawing box

			call DrawBox
			pop di
			call PrintString

Exit:		mov ax, 4C00h
			int 21h

;-------------------------------------------------------------------------------
; Description: Takes length of command line and pointer
;			   to its text, skips heading space (if it exists)
; Entry: 	   NO
; Exit:        String NOT empty: CF = 0, CX = length, SI = the first symbol addr
;		       String IS  empty: CF = 1, CX and SI not stated
; Expected:    NO
; Destr:	   CX, SI
;--------------------------------------------------------------------------------
GetCommandLine proc

			mov si, command_string_len_addr
			mov cl, [si]
			mov ch, 0					;CX = length
			cmp cl, 0
			je @@empty

			inc si
@@skip_spaces:
			cmp byte ptr [si], ' '
			jne @@no_space
			inc si
			dec cx
			cmp cx, 0
			je @@empty
			jmp @@skip_spaces

@@no_space:
			cmp cx, 0 		; мб убрать проверку, она не нужна
			je @@empty

			clc 			;CF=0 - success
			ret

@@empty:
			stc				; CF=1 - empty string
			ret
GetCommandLine endp

;-------------------------------------------------------------------------------
; Description: Fills with spaces all videomemory in text mode, cleaning screens
; Entry: 	   ES - videomemory segment
; Exit:        screen is clean
; Expected:    DF = 0 (addr increments)
; Destr:	   AX, CX, DI
;--------------------------------------------------------------------------------
ClearScreen proc
			xor di, di
			mov ax, 0720h		; 20h - space
			mov cx, 2000
			rep stosw			; writing ax into es:[di+=2] CX times
			ret
ClearScreen endp

;-------------------------------------------------------------------------------
; Description: Calculates offset in videomemory offset in bytes
;			   to print string with length=CX in the center of screen
;			   Using 12-th string and (80-CX)/2 column
; Entry: 	   CX = string length
; Exit:        DI = videomemory offset (in bytes)
; Expected:    CX <= 80
; Destr:	   AX, BX, DX, DI
;--------------------------------------------------------------------------------
CalculateCenteredPosition proc
			mov ax, max_number_of_symbols_in_string ;AX = 80
        	sub ax, cx                				;AX = 80 - length
        	shr ax, 1                				;AX = (80 - length)/2
			mov dx, ax               				; dx = number of the first symbol's column
			push dx
			mov ax, 24 / 2
			mov bx, max_number_of_symbols_in_string
			mul bx
			pop dx
			add ax, dx 				; AX = 12*80 + number of column
			shl ax, 1
			mov di, ax
			ret
CalculateCenteredPosition endp


;-------------------------------------------------------------------------------
; Description: Drawing box around string
; Entry: 	   CX = string length, DX = starting column
;			   AH = symbol attribute, ES = vidememory segment
; Exit:        Box drown
; Expected:    DF = 0 (address increments)
; Destr:	   AX, BX, DX, DI, SI
;--------------------------------------------------------------------------------
DrawBox proc
			push cx
			push si

			mov bx, dx
			dec bx
			cmp bx, 0
			jge @@left_ok
			xor bx, bx
@@left_ok:
			add dx, cx
			cmp dx, 79
			jle @@right_ok
			mov dx, 79
@@right_ok:	;BX = left, DX = right

			push bx
			push dx

			mov ax, 11
			mov cx, bx

			mov bx, 80
			mul bx
			add ax, cx
			shl ax, 1
			mov di, ax 		; DI = top left address

			pop dx
			pop bx
			push bx
			push dx

			mov cx, dx
			sub cx, bx
			inc cx			; CX = number of symbols in string
			mov si, bx		; SI = current column
@@top_loop:
			mov al, '-'
			cmp si, bx
			je @@top_corner
			cmp si, dx
			je @@top_corner
			jmp @@top_write
@@top_corner:
			mov al, '+'
@@top_write:
			mov ah, color_attr_green
			stosw
			inc si
			loop @@top_loop

			; ---- Drawing bottom line ----
			pop dx
			pop bx
			push bx
			push dx

			mov ax, 13
			mov cx, bx
			mov bx, 80
			mul bx
			add ax, cx
			shl ax, 1
			mov di, ax

			pop dx
            pop bx
            push bx
            push dx

			mov cx, dx
			sub cx, bx
			inc cx
			mov si, bx		;SI = left

@@bottom_loop:
			mov al, '-'
			cmp si, bx
			je @@bottom_corner
			cmp si, dx
			je @@bottom_corner
			jmp @@bottom_write
@@bottom_corner:
			mov al, '+'
@@bottom_write:
			mov ah, color_attr_green
			stosw
			inc si
			loop @@bottom_loop

			; --- drawing left vertical ---
			pop dx
			pop bx
			push bx
			push dx

			mov ax, 12
			mov cx, bx
			mov bx, 80
			mul bx
			add ax, cx
			shl ax, 1
			mov di, ax
			mov al, '|'
			mov ah, 02
			stosw

			; --- drawing right vertical ---
			pop dx
			pop bx

			mov ax, 12
			mov cx, dx
			mov bx, 80
			mul bx
			add ax, cx
			shl ax, 1
			mov di, ax
			mov al, '|'
			mov ah, color_attr_green
			stosw

			pop si
			pop cx
			ret
DrawBox endp


;-------------------------------------------------------------------------------
; Description: Prints string with attribute
; Entry: 	   DS:SI = string address, CX = string length
;			   ES:DI = the first symbol's address in videomemory
;			   AH = symbol's attribute
; Exit:        NO
; Expected:    DF = 0 (address increments)
; Destr:	   AX, DI
;--------------------------------------------------------------------------------
PrintString proc
@@loop:
			mov al, [si]
			stosw            ;ES:[DI] = AX ; add DI, 2; и так кучу раз, пока cx !=0
			inc si
			loop @@loop
			ret
PrintString endp

end 			Start
