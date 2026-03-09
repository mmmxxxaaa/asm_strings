.model tiny
.code
org 100h

locals @@

VIDEOMEMORY		 equ 0b800h

BOX_TOP_LEFT     equ 0C9h   ; ╔
BOX_TOP_RIGHT    equ 0BBh   ; ╗
BOX_BOTTOM_LEFT  equ 0C8h   ; ╚
BOX_BOTTOM_RIGHT equ 0BCh   ; ╝
BOX_HORIZ        equ 0CDh   ; ═
BOX_VERT         equ 0BAh   ; ║

COMMAND_STRING_LEN_ADDR         equ 80h
COMMAND_STRING_TEXT_ADDR        equ 81h
SCREEN_WIDTH					equ 80
SCREEN_HEIGHT       			equ 25
SCREEN_SIZE        				equ SCREEN_WIDTH * SCREEN_HEIGHT

COLOR_ATTR_GREEN   equ 02h
COLOR_ATTR_CLEAR   equ 07h

TEXT_ROW           equ 12
TOP_BORDER_ROW     equ TEXT_ROW - 1
BOTTOM_BORDER_ROW  equ TEXT_ROW + 1

SYM_SPACE		   equ ' '

Start:
			call GetCommandLine
			jc Exit								;CF = 1 => empty string

			push cx
			push si

			mov al, '/'
			call StrChr

			pop si
			pop bx

			cmp cx, bx
			jne @@found_user_frame_char

			mov byte ptr [user_frame_char], 0
			mov cx, bx
			jmp @@continue

@@found_user_frame_char:
            mov di, si          		; копируем адрес начала строки
            add di, cx          		; теперь DI указывает на символ после разделителя
            mov al, [di]        		; читаем символ рамки
            mov [user_frame_char], al
            dec cx              		; уменьшаем длину строки (убираем разделитель и символ)

@@continue:
			push cx
			mov ax, VIDEOMEMORY
			mov es, ax
			call ClearScreen
			pop cx
			mov ah, COLOR_ATTR_GREEN			; giving attribute
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
			mov si, COMMAND_STRING_LEN_ADDR
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
; Поиск символа в строке (аргументы через регистры)
; Вход: DS:SI – строка, CX – длина, AL – искомый символ
; Выход: CX = позиция+1 (если найден) или исходная длина (если не найден)
; Испорчено: DI, BX
;-------------------------------------------------------------------------------
StrChr proc
            push bx
            mov bx, cx          ; сохраняем исходную длину
            mov di, si
            cld
            repne scasb
            jnz @@not_found		; найден: CX = остаток, позиция+1 = исходная длина - остаток
            sub bx, cx
            mov cx, bx
            pop bx
            ret
@@not_found:
            mov cx, bx
            pop bx
            ret
StrChr endp

;-------------------------------------------------------------------------------
; Description: Fills with spaces all videomemory in text mode, cleaning screens
; Entry: 	   ES - videomemory segment
; Exit:        screen is clean
; Expected:    DF = 0 (addr increments)
; Destr:	   AX, CX, DI
;--------------------------------------------------------------------------------
ClearScreen proc
			xor di, di
			mov ax, (ATTR_CLEAR shl 8) or SYM_SPACE
			mov cx, SCREEN_SIZE
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
			mov ax, SCREEN_WIDTH					;AX = 80
        	sub ax, cx                				;AX = 80 - length
        	shr ax, 1                				;AX = (80 - length)/2
			mov dx, ax               				; dx = number of the first symbol's column
			push dx

			mov ax, TEXT_ROW
			mov bx, SCREEN_WIDTH
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
			cmp dx, SCREEN_WIDTH - 1
			jle @@right_ok
			mov dx, SCREEN_WIDTH - 1
@@right_ok:			;BX = left, DX = right

			mov al, TOP_BORDER_ROW					; номер строки
			mov ch, 0
			call DrawHorizontalBorder   ; верхняя граница

			mov al, BOTTOM_BORDER_ROW
			mov ch, 1
			call DrawHorizontalBorder   ; нижняя граница

			mov al, TEXT_ROW
			call DrawVertBorder

			mov al, TEXT_ROW
			mov bx, dx
			call DrawVertBorder

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
			mov ax, SCREEN_WIDTH
			mul di			; AX = row * 80
			add ax, [bp+8]
			shl ax, 1
			mov di, ax		; DI = offset in video memory

@@loop:
			cmp [user_frame_char], 0
			jne @@use_user_char

			mov al, BOX_HORIZ
			cmp si, [bp+8]
			je @@top_left_corner
			cmp si, [bp+6]
			je @@top_right_corner
			jmp @@write

@@top_left_corner:
			cmp bh, 0
			;cmp byte ptr [bp+3], 0
			jne @@bottom_left_corner
			mov al, BOX_TOP_LEFT
			jmp @@write
@@bottom_left_corner:
			mov al, BOX_BOTTOM_LEFT
			jmp @@write

@@top_right_corner:
			cmp byte ptr [bp+3], 0
			jne @@bottom_right_corner
			mov al, BOX_TOP_RIGHT
			jmp @@write
@@bottom_right_corner:
			mov al, BOX_BOTTOM_RIGHT
			jmp @@write
@@use_user_char:
			mov al, [user_frame_char]

@@write:
			mov ah, COLOR_ATTR_GREEN
			stosw
			inc si
			loop @@loop

			pop bp
			pop cx
			pop ax
			pop dx
			pop bx
			ret
			endp

;-------------------------------------------------------------------------------
; Description: Draws a vertical marker (single symbol) at given row and column
; Entry: 	   AL = row number, BX = column,
;			   ES = videosegment, AH = attribute (not used)
; Exit:        marker drawn
; Destr:	   AX, DI
;-------------------------------------------------------------------------------
DrawVertBorder proc
			push bx
			push dx
			push ax

			mov ah, 0
			mov di, ax
			mov ax, SCREEN_WIDTH
			mul di			; AX = row * 80
			add ax, bx
			shl ax, 1
			mov di, ax

			cmp [user_frame_char], 0
			jne @@use_user
			mov al, BOX_VERT
			jmp @@write
@@use_user:
			mov al, [user_frame_char]
@@write:
			mov ah, COLOR_ATTR_GREEN
			stosw

			pop ax
			pop dx
			pop bx
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

user_frame_char db 0

end 			Start


