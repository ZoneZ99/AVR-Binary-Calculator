;=====================================================
; DEFINITIONS
;=====================================================
.include "m8515def.inc"
.def temp = r16
.def EW = r23	; PORTA
.def PB	= r24	; PORTB
.def A = r25
.def BUTTON0 = r17
.def BUTTON1 = r18
.def OPERAND1 = r19
.def OPERAND2 = r20
.def OPERATOR = r21
.equ operation_number = 30


;=====================================================
; RESET and INTERRUPT VECTORS
;=====================================================
.org $00
rjmp MAIN
.org $01
rjmp EXT_INT0
.org $02
rjmp EXT_INT1


;=====================================================
; DELAYS
;=====================================================
DELAY_00:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 4 000 cycles
	; 500us at 8.0 MHz

	    ldi  r18, 6
	    ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
	ret

DELAY_01:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; DELAY_CONTROL 40 000 cycles
	; 5ms at 8.0 MHz

	    ldi  r18, 52
	    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret

DELAY_02:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 160 000 cycles
; 20ms at 8.0 MHz

	    ldi  r18, 208
	    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
		ret

;=====================================================
; CODE SEGMENT
;=====================================================
MAIN:
	cbi PORTA,	1	; Reg. Select Pin = 0
	ldi PB, $01
	out PORTB, PB
	sbi	PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0

INIT_STACK:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

INIT_INTERRUPT:
	ldi r17, 0b11000000
	out GICR, r17
	ldi r17, 0b00001010
	out MCUCR, r17

INIT_LCD_MAIN:
	rcall INIT_LCD

	ser temp
	out DDRA, temp	; Set port A as output
	out DDRB, temp	; Set port B as output
	
	rjmp INPUT_WELCOME

INIT_LCD:
	cbi PORTA, 1	; Reg. Select Pin = 0
	ldi PB, 0b00011100
	out PORTB, PB
	ldi PB, 0x38	; 8 bit, 2 line, 5x8 dots
	out PORTB,	PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall DELAY_01
	cbi PORTA, 1	; Reg. Select Pin = 0
	ldi PB, 0x0E	; Display ON, cursor ON, blink OFF
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall DELAY_01
	rcall CLEAR_LCD
	cbi PORTA, 1	; Reg. Select Pin = 0
	ldi PB, 0x06	; Increase cursor, display scroll OFF
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall DELAY_01
	ret


INPUT_WELCOME:	; Write opening text to LCD
	ldi ZH, high(2*opening)
	ldi ZL, low(2*opening)

	rjmp LOADBYTE_OPENING

LOADBYTE_OPENING:
	lpm 	; Load byte from program memory to r0
	
	tst	r0	; Check if we've reached the end of the message
	breq DELAY_CALL

	mov A, r0	; Put the character into Port B
	rcall WRITE_TEXT
	adiw ZL, 1	; Increment Z registers
	rjmp LOADBYTE_OPENING

WRITE_TEXT:	; Output text
	sbi PORTA, 1	; Reg. Select Pin = 1
	out PORTB, A	
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall DELAY_01
	ret

CLEAR_LCD:
	cbi PORTA, 1	; Reg. Select Pin = 0
	ldi PB, 0x01
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall DELAY_01
	ret

DELAY_CALL:
	rcall DELAY_02
	rcall CLEAR_LCD
	rcall CURSOR_SHIFT_LEFT
	rcall DELAY_02
	rjmp ACTIVATE_SEI

ACTIVATE_SEI:
	sei

EXIT:
	rjmp EXIT

EXT_INT0:
	sbi PORTA, 1	; Reg. Select Pin = 1
	cbi PORTA, 2	; Read/Write Pin = 0
	ldi PB, 0x30	; Write 0
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall CURSOR_SHIFT_LEFT
	reti
	
EXT_INT1:
	sbi PORTA, 1	; Reg. Select Pin = 1
	cbi PORTA, 2	; Read/Write Pin = 0
	ldi PB, 0x31	; Write 1
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	rcall CURSOR_SHIFT_LEFT
	reti

CURSOR_SHIFT_LEFT:
	cbi PORTA, 1	; Reg. Select Pin = 0
	cbi PORTA, 2	; Read/Write Pin = 0
	ldi PB, 0b00010000 	; Shift cursor to the left
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	;rcall DELAY_01

	cbi PORTA, 1
	cbi PORTA, 2
	ldi PB, 0b00011100	; Shift the entire display to the right
	out PORTB, PB
	sbi PORTA, 0
	cbi PORTA, 0
	;rcall DELAY_01

	cbi PORTA, 1	; Reg. Select Pin = 0
	cbi PORTA, 2	; Read/Write Pin = 0
	ldi PB, 0b00010000 	; Shift cursor to the left
	out PORTB, PB
	sbi PORTA, 0	; Enable Pin = 1
	cbi PORTA, 0	; Enable Pin = 0
	;rcall DELAY_01

	ret	

;=====================================================
; DATA
;=====================================================
opening:
.db "BinCalc!", 0
