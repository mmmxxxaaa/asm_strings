.model tiny
.code
org 100h

symbols_in_string equ 80
coord_x           equ 5
coord_y           equ 19

Start:			mov ax, 0b800h
			mov es, ax
			
			mov ax, coord_y
			mov cx, symbols_in_string
			mul cx
			add ax, coord_x
			shl ax, 1		 ;in videopamat 1 symbol eto 2 bytes
			mov bx, ax			

			mov byte ptr es:[bx], 03h
			mov byte ptr es:[bx+1], 4eh
			
			mov ax, 4c00h
			int 21h

end                     Start