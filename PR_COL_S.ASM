.model tiny
.code
org 100h

symbol		  equ 0C03h
symbols_in_string equ 80
row_count         equ 25
bytes_in_string   equ 160
row_coord	  equ 5
column_coord      equ 64

Start:			mov ax, 0b800h
			mov es, ax

			;string output
			mov ax, row_coord
			mov bx, bytes_in_string
			mul bx
			mov di, ax
			
			mov ax, symbol
			mov cx, symbols_in_string
			rep stosw
			
			mov di, column_coord
			shl di, 1

			mov ax, symbol
			mov cx, bytes_in_string

PrintColumn:		mov es:[di], ax
			add di, bytes_in_string
			loop PrintColumn
			
			mov ax, 4C00h
			int 21h

end			Start		