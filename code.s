.org 0 ; address from which to start placing instructions

.equ SREG, 0x3f
.equ DDRB, 0x04
.equ PORTB, 0x05 ; PORTB hosts the lower 4 bits of our byte (our leds)
.equ PORTD, 0x0b ; PORTD hosts the higher 4 bits of our byte (our leds)
.equ DDRD, 0x0a

main:
  ldi r16, 0
  out SREG, r16 ; clear SREG

  ldi r16, 0x0f
  out DDRB, r16 ; set first 4 pins of PORTB as output
  ldi r16, 0xf0
  out DDRD, r16 ; set last 4 pins of PORTD as output

  ; rcall k_number

  ; rcall initials

  ldi r19, 50
  ; rcall morse_loop

  rjmp ping_pong

  rjmp main

ping_pong_going_right:
  out PORTB, r16
  out PORTD, r16

  ldi r18, 50
  rcall delay

  lsr r16
  cpi r16, 0x01
  brne ping_pong_going_right
  ret

ping_pong_going_left:
  out PORTB, r16
  out PORTD, r16

  ldi r18, 50
  rcall delay

  lsl r16
  cpi r16, 0x80
  brne ping_pong_going_left
  ret

ping_pong:
  ldi r16, 0x80
  rcall ping_pong_going_right
  ldi r16, 0x01
  rcall ping_pong_going_left
  rjmp ping_pong

morse_loop: ; do it r19 times (that is 50)
  ; if a number is odd, then the bit in the first position would be 1
  ; if it is even, then the same bit would be 0
  mov r16, r19

  andi r16, 0x01 ; isolate the first bit

  cpi r16, 0x00
  brne continue1 
  rcall morse ; calls morse if r16's first bit is 0

  continue1:

  cpi r16, 0x01
  brne continue2
  rcall esrom ; brances if r16's first bit is 1

  continue2:

  mov r16, r19
  rjmp dec_5 ; continuously decrement 5 from r16

  good:
  ; going to display five

  rcall inter_letter
  rcall inter_letter
  rcall inter_letter
  rcall inter_letter

  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot

  bad:

  rcall inter_word

  dec r19
  brne morse_loop ; branches if r19 != 0
  ret

dec_5:
  dec r16
  breq good
  dec r16
  breq bad
  dec r16
  breq bad
  dec r16
  breq bad
  dec r16
  breq bad
  rjmp dec_5

morse:
  ; display morse code: MEH, dash dash, dot, dot dot dot dot
  ldi r16, 0x01 ; only going to turn on the first led
  ldi r17, 0x00 ; display nothing

  ; dash dash
  rcall morse_dash
  rcall inter_part
  rcall morse_dash

  rcall inter_letter

  ; dot
  rcall morse_dot

  rcall inter_letter

  ; dot dot dot dot
  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot

  ret

esrom:
  ; display morse code: MEH, dash dash, dot, dot dot dot dot
  ldi r16, 0x01 ; only going to turn on the first led
  ldi r17, 0x00 ; display nothing

  ; dot dot dot dot
  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot
  rcall inter_part
  rcall morse_dot

  rcall inter_letter

  ; dot
  rcall morse_dot

  rcall inter_letter

  ; dash dash
  rcall morse_dash
  rcall inter_part
  rcall morse_dash

  ret

morse_dash:
  ldi r16, 0x01 ; only going to turn on the first led
  out PORTB, r16
  ldi r18, 60
  rcall delay
  ret

morse_dot:
  ldi r16, 0x01 ; only going to turn on the first led
  out PORTB, r16
  ldi r18, 20
  rcall delay
  ret

inter_part:
  ldi r17, 0x00 ; display nothing
  out PORTB, r17
  ldi r18, 20
  rcall delay
  ret

inter_letter:
  ldi r17, 0x00 ; display nothing
  out PORTB, r17
  ldi r18, 60
  rcall delay
  ret

inter_word:
  ldi r17, 0x00 ; display nothing
  out PORTB, r17
  ldi r18, 140
  rcall delay
  ret

k_number: ; display the k-number: K23162628
  ldi r16, 0x02
  rcall display_register
  ldi r16, 0x03
  rcall display_register
  ldi r16, 0x01
  rcall display_register
  ldi r16, 0x06
  rcall display_register
  ldi r16, 0x02
  rcall display_register
  ldi r16, 0x06
  rcall display_register
  ldi r16, 0x02
  rcall display_register
  ldi r16, 0x08

  ldi r16, 0x00
  rcall display_register ; display 0 and delay for a second
  ret

initials: ; display initials: M.K.B
  ldi r16, 0x0d
  rcall display_register
  ldi r16, 0x1b
  rcall display_register
  ldi r16, 0x0b
  rcall display_register
  ldi r16, 0x1b
  rcall display_register
  ldi r16, 0x02
  rcall display_register
  ret

display_register: ; display a digit on the leds from r16 and DELAY 1 second
  out PORTB, r16 ; display the lower 4 bits, since a digit < 10
  out PORTD, r16 ; display the higher 4 bits

  ldi r18, 100 ; set the delay for a second
  rcall delay
  ret

delay: ; delay 10ms * r18
  rcall delay_10ms ; 1
  dec r18 ; 1
  brne delay ; 1 if false, 2 if true
  ret

delay_10ms:
  ldi r20, 79 ; 1
  delay12:
    ldi r21, 2 ; 1
    delay22:
      ldi r22, 252 ; 1
      delay32:
        nop ; 1
        dec r22 ; 1
        brne delay32 ; 1 if false, 2 if true
      dec r21 ; 1
      brne delay22 ; 1 if false, 2 if true
    dec r20 ; 1
    brne delay12 ; 1 if false, 2 if true
  ret

; ((4*79 - 1 + 4) * 2 - 1 + 4) * 252 - 1 cycles = 161531 cycles