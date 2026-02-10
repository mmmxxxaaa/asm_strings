.model tiny
.code
org 100h

command_string_len_addr         equ 80h
command_string_text_addr        equ 81h
symbol			        equ 0C03h
max_number_of_symbols_in_string equ 80
max_number_of_symbols_in_column equ 26


Start:			mov si, command_string_len_addr
			mov cl, [si]
			mov ch, 0
			cmp cl, 0
			je Exit

			inc si
			
			cmp byte ptr [si], ' '
			jne no_space
			inc si
			dec cx

no_space:   		;saving length and ptr
			push cx
			push si

			;cleaning videomemory
			mov ax, 0b800h
			mov es, ax
			xor di, di

			mov ax, 0720h		; 20h - space
			mov cx, 2000
			rep stosw

			;calculating position
			pop si
			pop cx
			
			mov ax, max_number_of_symbols_in_string
			sub ax, cx  		; 80 minus length
			shr ax, 1		; /2

			mov dx, ax		;saving otstup

			;calculating address=(string * 80 + column)*2
			mov ax, 12
			mov bx, max_number_of_symbols_in_string

			mul bx
			add ax, dx
			shl ax, 1
			
			mov di, ax

			mov ah, 6Ch 	;ATRIBUT ANOTHER EPTA

write_loop:		mov al, [si]
			stosw            ;ES:[DI+=2] = AX 
			inc si
			loop write_loop

Exit:			mov ax, 4C00h
			int 21h

end 			Start