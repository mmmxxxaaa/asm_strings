.model tiny
.code
org 100h

col_yellow_on_black equ 0Eh

Start:				mov ax, 0b800h
				mov es, ax
				xor di, di
				
				mov si, offset String_to_print
				mov ah, 0Eh

PrintIteration:			lodsb
				cmp al, '$'
				je Exit
				stosw
				jmp PrintIteration

Exit:				mov ax, 4C00h
				int 21h

String_to_print:		db 'MEOW MEOW MEOW', 0Dh, 0Ah, '$'

end				Start