.model tiny
.code
org 100h

locals @@

BOX_TOP_LEFT     equ 0C9h   ; ╔
BOX_TOP_RIGHT    equ 0BBh   ; ╗
BOX_BOTTOM_LEFT  equ 0C8h   ; ╚
BOX_BOTTOM_RIGHT equ 0BCh   ; ╝
BOX_HORIZ        equ 0CDh   ; ═
BOX_VERT         equ 0BAh   ; ║

command_string_len_addr         equ 80h
command_string_text_addr        equ 81h
max_number_of_symbols_in_string equ 80
max_number_of_symbols_in_column equ 26
color_attr_green				equ 02h

Start:
			call GetCommandLine
			jc Exit								;CF = 1 => empty string

			push cx
			mov ax, 0b800h
			mov es, ax

			call ClearScreen
			pop cx
			mov ah, color_attr_green			; giving attribute
			push ax

			call CalculateCenteredPosition

			push di				; needed after drawing box

			; ~~~ cdecl style ~~~~~~~~~~~~~~~~~
			push es			; 4th arg
			push ax			; 3rd arg
			push dx			; 2nd arg
			push cx			; 1st arg
			call DrawBox_cdecl
			add sp, 8		; cleaning stack
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			pop di

			pop ax
			; ~~~ pascal style ~~~~~~~~~~~~~~~~
			push si
			push cx
			push di
			push ax
			call PrintString_pascal
			; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
;			   AH = symbol attribute, ES = videomemory segment
; Exit:        Box drown
; Expected:    DF = 0 (address increments)
; Destr:	   AX, BX, DX, DI, SI
;--------------------------------------------------------------------------------
DrawBox_cdecl proc
			push bp
			mov bp, sp
			push cx
			push si

			mov cx, [bp+4]	; length
			mov dx, [bp+6]	; column
			mov ax, [bp+8]	; attribute
			mov es, [bp+10] ; videosegment

			mov bh, ah      ;saving attribute

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

			mov al, 11					; номер строки
			mov ch, 0
			call DrawHorizontalBorder   ; верхняя граница

			mov al, 13
			mov ch, 1
			call DrawHorizontalBorder   ; нижняя граница

			mov al, 12
			call DrawLeftColumn

			mov al, 12
			call DrawRightColumn

			pop si
			pop cx
			pop bp
			ret
DrawBox_cdecl endp

;-------------------------------------------------------------------------------
; Description: Draws horizontal border (top or bottom) of the box
; Entry: 	   AL = row number, BX = left column, DX = right column,
;			   CH = 0 for top border, 1 for bottom border,
;			   ES = videosegment, AH = attribute
; Exit:        border drawn
; Destr:	   AX, CX, DI, SI
;-------------------------------------------------------------------------------
DrawHorizontalBorder proc
			push bx
			push dx
			push ax
			push cx
			push bp
			mov bp, sp		; теперь [bp] = старое bp, [bp+2] = cx, [bp+4] = ax, [bp+6] = dx, [bp+8] = bx

			mov bh, ch       ; сохраняем флаг (top/bottom) в BH, так как CH будет испорчен

			mov cx, [bp+6]	; правая граница (DX)
			sub cx, [bp+8]	; вычитаем левую границу (BX)
			inc cx			; CX = количество символов в линии
			mov si, [bp+8]

			mov ax, [bp+4]
			mov ah, 0
			mov di, ax
			mov ax, 80
			mul di			; AX = row * 80
			add ax, [bp+8]
			shl ax, 1
			mov di, ax		; DI = offset in video memory

@@loop:
			mov al, BOX_HORIZ
			cmp si, [bp+8]
			je @@corner_left
			cmp si, [bp+6]
			je @@corner_right
			jmp @@write

@@corner_left:
			cmp byte ptr [bp+3], 0
			jne @@bottom_left
			mov al, BOX_TOP_LEFT
			jmp @@write
@@bottom_left:
			mov al, BOX_BOTTOM_LEFT
			jmp @@write

@@corner_right:
			cmp byte ptr [bp+3], 0
			jne @@bottom_right
			mov al, BOX_TOP_RIGHT
			jmp @@write
@@bottom_right:
			mov al, BOX_BOTTOM_RIGHT

@@write:
			mov ah, color_attr_green
			stosw
			inc si
			loop @@loop

			pop bp
			pop cx
			pop ax
			pop dx
			pop bx
			ret
DrawHorizontalBorder endp

;-------------------------------------------------------------------------------
; Description: Draws left vertical column (single symbol) at row AL, column BX
; Entry: 	   AL = row number (12), BX = left column,
;			   ES = videosegment, AH = attribute (not used)
; Exit:        left column drawn
; Destr:	   AX, DI
;--------------------------------------------------------------------------------
DrawLeftColumn proc
			push bx
			push dx
			push ax

			mov ah, 0
			mov di, ax
			mov ax, 80
			mul di			; AX = row * 80
			add ax, bx
			shl ax, 1
			mov di, ax

			mov al, BOX_VERT
			mov ah, color_attr_green
			stosw

			pop ax
			pop dx
			pop bx
			ret
			endp

;-------------------------------------------------------------------------------
; Description: Draws right vertical marker (single symbol) at row AL, column DX
; Entry: 	   AL = row number (12), DX = right column,
;			   ES = videosegment, AH = attribute (not used)
; Exit:        right marker drawn
; Destr:	   AX, DI
;--------------------------------------------------------------------------------
DrawRightColumn proc
			push dx
			push ax
			mov bx, dx

			mov ah, 0
			mov di, ax
			mov ax, 80
			mul di
			add ax, bx
			shl ax, 1
			mov di, ax

			mov al, BOX_VERT
			mov ah, color_attr_green
			stosw

			pop ax
			pop dx
			ret
			endp

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
