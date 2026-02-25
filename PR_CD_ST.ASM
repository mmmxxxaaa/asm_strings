Почему прога выводит только верхнюю часть рамки
.model tiny
.code
org 100h

command_string_len_addr         equ 80h
command_string_text_addr        equ 81h
max_number_of_symbols_in_string equ 80
max_number_of_symbols_in_column equ 26
color_attr_green				equ 02h
n_of_layers						equ 3

Start:
			call GetCommandLine
			jc Exit				;CF = 1 => empty string

			push cx
			mov ax, 0b800h
			mov es, ax
			call ClearScreen
			pop cx

			mov ah, color_attr_green			; giving attribute
			push ax
			call CalculateCenteredPosition
			pop ax

			push di				; needed after drawing box
			push si
			; ~~~ cdecl style ~~~~~~~~~~~~~~~~~
			push es			; 4th arg
			push ax			; 3rd arg
			push dx			; 2nd arg
			push cx			; 1st arg
			call DrawBox_cdecl
			add sp, 8		; cleaning stack
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			pop si
			pop di
			mov ah, color_attr_green

			; ~~~ pascal style ~~~~~~~~~~~~~~~~
			push si
			push cx
			push di
			push ax
			call PrintString_pascal
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			mov ah, 00h
			int 16h
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
			sub ax, cx
			shr ax, 1
			mov dx, ax  		;dx = number of the first symbol's column
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
; Entry: 	    [bp+4]	length
				[bp+6]	column
				[bp+8]	attribute
				[bp+10] videosegment
; Exit:        Box drown
; Expected:    DF = 0 (address increments)
; Destr:	   AX, BX, DX, DI, SI
;--------------------------------------------------------------------------------
DrawBox_cdecl proc
			push bp
			mov bp, sp
			push cx
			push si
			push bx
			push di

			mov cx, [bp+4]	;length
			mov dx, [bp+6]	;column
			mov ax, [bp+8]	; attribute
			mov es, [bp+10] ; videosegment

			mov bh, ah   		;saving attribute

			mov bx, dx			; left = given column
			add dx, cx
			dec dx				; right = left + length - 1

			cmp bx, 0
			jge @@left_ok
			xor bx, bx
@@left_ok:
			cmp dx, 79
			jle @@right_ok
			mov dx, 79
@@right_ok:						; BX = left, DX = right

			mov si, 11
			mov di, 13

			mov cx, n_of_layers ; cx = total number of layers
			xor bp, bp			; bp = counter of layers (0, 1, 2)
@@layer_loop:
			push cx
			push bx
			push dx
			push si
			push di

								; extending granitsi for now layer (bp)
			mov ax, bx			;
			sub ax, bp
			cmp ax, 0
			jge @@l_ok
			xor ax, ax
@@l_ok:
			mov bx, ax			; new left granitsa
			mov ax, dx
			add ax, bp
			cmp ax, 79
			jle @@r_ok
			mov ax, 79
@@r_ok:
			mov dx, ax			; new_right granitsa
			mov ax, si
			sub ax, bp
			cmp ax, 0
			jge @@t_ok
			xor ax, ax
@@t_ok:
			mov si, ax			; new up granitsa
			mov ax, di
			add ax, bp
			cmp ax, 24
			jle @@b_ok
			mov ax, 24
@@b_ok:
			mov di, ax			; new down granitsa
			push bx				; saving new granitsi on stack
			push dx
			push si
			push di

			; --- top line ---
			mov cx, dx			; calculating length of top line
			sub cx, bx
			inc cx
			push cx
			mov ax, si
			mov cx, 80
			mul cx
			add ax, bx
			shl ax, 1
			mov di, ax			; di = videomemory addres
			pop cx
			mov si, bx
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

			pop di			;removing saved granitsi from stack
			pop si
			pop dx
			pop bx

			; ---- bottom line ----
			push bx
			push dx
			push si
			push di

			mov cx, dx
			sub cx, bx
			inc cx
			push cx
			mov ax, di
			mov cx, 80
			mul cx
			add ax, bx
			shl ax, 1
			mov di, ax
			pop cx
			mov si, bx
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
			mov ah, bh
			stosw
			inc si
			loop @@bottom_loop

			pop di
			pop si
			pop dx
			pop bx

			; --- left vertical ---
			mov ax, si
			inc ax
			cmp ax, di
			jge @@skip_vertical

			push bx
			push dx
			push si
			push di
			mov si, ax
			mov cx, di
			sub cx, si

@@vert_loop:
			push cx				;saving counter of strings
			;--- left vertical ---
			mov ax, si
			mov cx, 80
			mul cx
			add ax, bx			; column = left granitsa
			shl ax, 1
			mov di, ax
			mov al, '|'
			mov ah, bh
			stosw
			;--- right vertical ---
			mov ax, si
			mov cx, 80
			mul cx
			add ax, dx			; column = right granitsa
			shl ax, 1
			mov di, ax
			mov al, '|'
			mov ah, bh
			stosw

			pop cx
			inc si
			loop @@vert_loop
			pop di
			pop si
			pop dx
			pop bx
@@skip_vertical:
			pop di
			pop si
			pop dx
			pop bx
			pop cx
			inc bp
			dec cx
			jz  @@end_layer_loop
			jmp @@layer_loop

@@end_layer_loop:
			pop di
			pop bx
			pop si
			pop cx
			pop bp
			ret
DrawBox_cdecl endp


;-------------------------------------------------------------------------------
; Description: Prints string with attribute
; Entry: 	   DS:SI = string address, CX = string length
;			   ES:DI = the first symbol's address in videomemory
;			   AH = symbol's attribute
; Exit:        NO
; Expected:    DF = 0 (address increments)
; Destr:	   AX, DI
;--------------------------------------------------------------------------------
PrintString_pascal proc
			push bp
			mov bp, sp

			mov si, [bp+10]
			mov cx, [bp+8]
			mov di, [bp+6]
			mov ax, [bp+4]

@@loop:
			mov al, [si]
			stosw            ;ES:[DI] = AX ; add DI, 2; и так кучу раз, пока cx !=0
			inc si
			loop @@loop

			pop bp
			ret 8
PrintString_pascal endp

end 			Start
