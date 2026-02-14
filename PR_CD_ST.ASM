.model tiny
.code
org 100h

command_string_len_addr         equ 80h
command_string_text_addr        equ 81h
max_number_of_symbols_in_string equ 80
max_number_of_symbols_in_column equ 26


Start:
			call GetCommandLine
			jc Exit				;CF = 1 => empty string

			mov ax, 0b800h
			mov es, ax

			call ClearScreen

			mov ah, 6Ch			; giving attribute

			call CalculateCenteredPosition

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
			cmp byte ptr [si], ' '
			jne @@no_space
			inc si
			dec cx

@@no_space:
			cmp cx, 0
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

			mov dx, ax               ; dx = number of the first symbol's column
			mov ax, 24 / 2
			mov bx, max_number_of_symbols_in_string
			mul bx
			add ax, dx 				; AX = 12*80 + number of column
			shl ax, 1
			mov di, ax
			ret
CalculateCenteredPosition endp

;-------------------------------------------------------------------------------
; Description: Prints string with attribute
; Entry: 	   DS:SI = string address, CX = string length
			   ES:DI = the first symbol's address in videomemory
			   AH = symbol's attribute
; Exit:        NO
; Expected:    DF = 0 (address increments)
; Destr:	   AX, DI
;--------------------------------------------------------------------------------
PrintString proc
@@loop:
			mov al, [si]
			stosw            ;ES:[DI+=2] = AX
			inc si
			loop @@loop
			ret
PrintString endp

end 			Start
