 ;----------------------------------------------------;
 ; Made By                : Saulin Tuhin              ;
 ; Roll                   : 011151351                 ;
 ; For Assembly Lab under : S.M. Farabi Mahmud        ;
 ;----------------------------------------------------;
 ;In FASM
 
use16
org 100h

 ;----------------------------------------------------;
 ; constants                                          ;
 ;----------------------------------------------------;

SCREEN_WIDTH =		320
SCREEN_HEIGHT = 	200
SCREEN_X_MID =		SCREEN_WIDTH / 2
SCREEN_Y_MID =		SCREEN_HEIGHT / 2

PADDLE_SIZE =		25
PADDLE_LEFT_COLOUR =	2
PADDLE_RIGHT_COLOUR =	2
BALL_COLOUR =		2
SCORE_COLOUR =		2
TOP_ROW_COLOUR =	0

PADDLE_LEFT_X = 	1
PADDLE_RIGHT_X =	SCREEN_WIDTH - 2
PADDLE_TOP =		2
PADDLE_MID =		SCREEN_Y_MID - (PADDLE_SIZE/2)
PADDLE_BOTTOM = 	(SCREEN_HEIGHT-1) - PADDLE_SIZE

BALL_LEFT =		PADDLE_LEFT_X + 1
BALL_RIGHT =		PADDLE_RIGHT_X - 1
BALL_SCORE_LEFT =	0
BALL_SCORE_RIGHT =	SCREEN_WIDTH - 1
BALL_MID_X =		SCREEN_X_MID
BALL_MID_Y =		SCREEN_Y_MID
BALL_TOP =		PADDLE_TOP
BALL_BOTTOM =		(PADDLE_BOTTOM + PADDLE_SIZE) - 1
BALL_DELAY =		30 ; frames (assume 60Hz)

AI_THRESHOLD =		SCREEN_WIDTH - 90
MAX_SCORE =		7
RANDOM_PRIME   =	14033

 ;----------------------------------------------------;
 ; main parogram                                      ;
 ;----------------------------------------------------;
start:
        mov	[LoadAddress],0
	; set up VGA mode 13h
		mov	ax, 0013h
		int	10h
		; store video memory in es (will stay constant from here on)
		push	word 0A000h
		pop	es

	; draw background
		mov ax, image
        mov [ImageBase], ax
        call DisplayBmp
        jc exit
        jmp game_loop
    ; if score is maxed, game will pause          
    score_maxed:
	    mov word [score_left], 1
	    mov word [score_right], 1
    	; add image for game over
    	mov ax, image
    	mov [ImageBase],ax
    	call DisplayBmp
    	jc exit
    	
    	mov ah, 9
    	mov dx, game_over
    	int 21h
    	
    	mov ah, 9
    	mov dx, pagain
    	int 21h
    	
    	mov ah, 9
    	mov dx, quit
    	int 21h
    	
    	mov ah, 1
    	int 21h
    	
    	cmp al, 'y'
    	je start
    	jmp exit      
 ;----------------------------------------------------;
 ; constantly updates                                 ;
 ;----------------------------------------------------;              
    game_loop:
	; check input
		; reset movement
		mov    word [player_move], 0
		mov    word [player2_move], 0
		; get shift registers
		mov	ah, 1
		int	16h
		jz no_q
		;take input
		mov ah, 0
		int 16h
		; test for s
		cmp	al, 's'
		jne	no_s
		inc    word [player_move]
	    no_s:
		; test for w
		cmp	al, 'w'
		jne	no_w
		dec    word [player_move]
	    no_w:
	    cmp al, 'q'
	    jne no_q
	    jmp score_maxed
	    no_q:
	    cmp byte [player_count], 2
	    je right_player 

	; update game state
	    right_ai:
		; right paddle AI if selected
			cmp	word [ball_x], AI_THRESHOLD
			mov	bx, [paddle_right_y]
			jl	end_ai
			mov	ax, [ball_y]
			sub	ax, (PADDLE_SIZE / 2)
			cmp	ax, bx
			jl	ai_up
			jg	ai_dn
			jmp	end_ai
		    ai_up:
			dec	bx
			jmp	end_ai
		    ai_dn:
			inc	bx
			jmp	end_ai
		    end_ai:
			call	clamp_paddle
			mov	[paddle_right_y], bx
			jmp left_player
			
		right_player:
		; if right paddle moved by 2nd player
		    ; test for k
    	    cmp al, 'k'
    	    jne no_k
    	    inc     word [player2_move]
    	    no_k:
    	    ; test for i
    	    cmp al, 'i'
    	    jne no_i
    	    dec     word [player2_move]
    	    no_i:
    	    
    	    mov bx, [paddle_right_y]
    	    add bx, [player2_move]
    	    call    clamp_paddle
    	    mov [paddle_right_y], bx
    	    
		left_player:
		; left paddle moved by player
			mov	bx, [paddle_left_y]
			add	bx, [player_move]
			call	clamp_paddle
			mov	[paddle_left_y], bx
		; skip ball move if delay is set
			cmp	word [ball_delay], 0
			jz	no_ball_delay
			dec	word [ball_delay]
			jmp	end_update
		    no_ball_delay:
		; move ball vertical
			mov	ax, [ball_y]
			add	ax, [ball_dy]
			mov	[ball_y], ax
		; bounce vertical
			cmp	ax, BALL_TOP
			jne	ball_not_top
			mov	word [ball_dy], 1
		    ball_not_top:
			cmp	ax, BALL_BOTTOM
			jne	ball_not_bottom
			mov	word [ball_dy], -1
		    ball_not_bottom:
		; move ball horizontal
			mov	cx, [ball_x]
			add	cx, [ball_dx]
			mov	[ball_x], cx
		; check for paddle collision
			; ax = ball_y
			; bx = paddle_left
			mov	dx, PADDLE_LEFT_X
			call	collide_paddle
			; ax = ball_y
			mov	bx, [paddle_right_y]
			mov	dx, PADDLE_RIGHT_X
			call	collide_paddle
		; check for goal
			; cx = ball_x
			cmp	cx, BALL_SCORE_LEFT
			jne	ball_not_goal_left
			mov	bx, score_right
			call	new_ball ; ax = ball_y
			jmp	end_update
		    ball_not_goal_left:
			cmp	cx, BALL_SCORE_RIGHT
			jne	ball_not_goal_right
			mov	bx, score_left
			call	new_ball ; ax = ball_y
		    ball_not_goal_right:
		;
	    end_update:
	; end update game state

	; wait for vsync
	    vsync_active:
		mov	dx, 03DAh	; input status port for checking retrace
		in	al, dx
		test	al, 8
		jnz	vsync_active	; Bit 3 on signifies activity
	    vsync_retrace:
		in	al, dx
		test	al, 8
		jz	vsync_retrace	; Bit 3 off signifies retrace

	; draw game (does the actual renders on the screen)
		; clear old ball
		mov	ax, [ball_last_y]
		mov	bx, [ball_last_x]
		mov	dl, [clear_color]
		call	put_pixel
		; draw ball
		mov	ax, [ball_y]
		mov	[ball_last_y], ax
		mov	bx, [ball_x]
		mov	[ball_last_x], bx
		mov	dl, BALL_COLOUR
		call	put_pixel
		; draw left paddle
		mov	ax, [paddle_left_y]
		mov	bx, PADDLE_LEFT_X
		mov	dl, PADDLE_LEFT_COLOUR
		call	draw_paddle
		; draw right paddle
		mov	ax, [paddle_right_y]
		mov	bx, PADDLE_RIGHT_X
		mov	dl, PADDLE_RIGHT_COLOUR
		call	draw_paddle
		; draw scores
		mov	dl, SCORE_COLOUR
		xor	ax, ax ; ax = 0
		xor	bx, bx ; bx = 0
		mov	cx, [score_left]
		draw_score_left_loop:
		    xor ax, ax
			call	put_pixel
			inc ax
			call put_pixel
			inc ax
			call put_pixel
			inc	bx
			inc	bx
			loop	draw_score_left_loop
		mov	bx, SCREEN_WIDTH-1
		mov	cx, [score_right]
		draw_score_right_loop:
		    xor ax, ax
			call	put_pixel
			inc ax
			call put_pixel
			inc ax
			call put_pixel
			dec	bx
			dec	bx
			loop	draw_score_right_loop
	; end draw game

	jmp game_loop

	; exit if a key has been pressed other then y in score maxed
	exit:
	int	20h

 ;----------------------------------------------------;
 ;  subroutine                                        ;
 ;----------------------------------------------------;
;start of bmp subroutine
DisplayBmp:
	pusha				   ; save the regs
	push	ds
	push	es
	mov	si,[ImageBase]		   ; make sure si as the image address
	cmp	word [si+00h],4D42h	   ; test for 'BM' to make sure its a BMP file.
	jnz	BmpError		   ; if jump to exit with error
	mov	bx,[si+12h]		   ; start of header + 18 = width
	mov	bp,[si+16h]		   ; start of header + 22 = depth
	cmp	bx,320
	ja	BmpError
	cmp	bp,200
	ja	BmpError
	cmp	word [si+1Ch],8 	   ; start of header + 28 = bpp
	jnz	BmpError
	mov	si,0036h		   ;start of header + 54 = start of palette
	add	si,[ImageBase]
	mov	cx,256			   ;number of colors for patette
	mov	dx,03C8h
	mov	al,0
	out	dx,al
	inc	dx

SetPalete:
	mov	al,[si+2]		   ; red
	shr	al,2
	out	dx,al
	mov	al,[si+1]		   ; green
	shr	al,2
	out	dx,al
	mov	al,[si] 		   ; blue
	shr	al,2
	out	dx,al
	add	si,4
	loop	SetPalete

	push	0A000h
	pop	es
	lea	dx,[bx+3]		   ; round bmp width ;)
	and	dx,-4
	imul	di,bp,320
	add	di,[LoadAddress]	   ; this is the X Y offset of the screen
new_line:
	sub	di,320
	pusha
	mov	cx,bx
	rep	movsb
	popa
	add	si,dx
	dec	bp
	jnz	new_line
ExitOK:
	clc
	pop	es
	pop	ds
	popa
	ret

BmpError:
	stc
	pop	es
	pop	ds
	popa
	ret
; end of bmp subroutine

; put_pixel
; plots a pixel at bx,ax with color dl
; (registers preserved)
put_pixel:
	push	ax bx dx
	mul	word [screen_width]
	add	bx, ax
	pop	dx
	; save the previous color before drawing over it
	;mov al, [es:bx]
	;mov [clear_color], al
	mov	[es:bx], dl
	pop	bx ax
	ret

; draw_paddle
; draws a paddle (position: bx,ax colour: dl)
draw_paddle:
	mov	cx, PADDLE_SIZE
	draw_left_paddle_loop:
		call	put_pixel
		inc	ax
		loop	draw_left_paddle_loop
	mov	dl, [clear_color]
	call	put_pixel
	sub	ax, PADDLE_SIZE+1
	call	put_pixel
	ret

; new_ball
; increments score
; generates new starting ball position
new_ball:
	; increment score counter at [bx]
	mov cx, [bx]
	cmp cx, MAX_SCORE
	jge	score_maxed
	inc word [bx]
	; use ax (ball_y) + paddle_left_y to make a random number:
	add	ax, [paddle_left_y]
	mul	word [RANDOM_PRIME]
	; random number now in AX
	and	ax, 127
	add	ax, BALL_MID_Y - 64
	mov	[ball_y], ax
	mov	word [ball_x], BALL_MID_X
	; send ball to player who just lost
	mov	word [ball_delay], BALL_DELAY
	ret
	

; clamp_paddle
;   clamps bx to [PADDLE_TOP,PADDLE_BOTTOM]
clamp_paddle:
	cmp	bx, PADDLE_TOP
	jg	not_top
	mov	bx, PADDLE_TOP
    not_top:
	cmp	bx, PADDLE_BOTTOM
	jl	not_bottom
	mov	bx, PADDLE_BOTTOM
    not_bottom:
	ret

; collide_paddle
;   collides paddle with ball
;   ax = ball_y
;   bx = paddle_y
;   dx = PADDLE_X
collide_paddle:
	cmp	cx, dx
	jne	no_collide
	cmp	ax, bx
	jl	no_collide
	add	bx, PADDLE_SIZE
	cmp	ax, bx
	jge	no_collide
	neg	word [ball_dx]
    no_collide:
	ret

 ;----------------------------------------------------;
 ; global data                                        ;
 ;----------------------------------------------------;
game_over: db "Game Over", 0dh, 0ah,'$'
pagain: db "Press y to play again", 0dh, 0ah, '$'
quit: db "Press any key to quit", 0dh, 0ah, '$'
player_count: db 1
paddle_left_y:	dw	PADDLE_MID
paddle_right_y: dw	PADDLE_MID
player_move:	dw	0
player2_move: dw 0
ball_x: 	dw	BALL_MID_X
ball_y: 	dw	BALL_MID_Y
ball_dx:	dw	1
ball_dy:	dw	-1
ball_last_x:	dw	BALL_MID_X
ball_last_y:	dw	BALL_MID_Y
ball_delay:	dw	0
score_left:	dw	1
score_right:	dw	1
screen_width:	dw	SCREEN_WIDTH
clear_color: db 0
LoadAddress dw 0
ImageBase   dw 0
image: file 'pong.bmp'	; background
;image1: file 'gameover.bmp' ;gameover screen

 ;----------------------------------------------------;
 ; end of file                                        ;
 ;----------------------------------------------------;