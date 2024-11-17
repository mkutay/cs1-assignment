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

  ldi	ZL, lo8(k_number_data)
	ldi	ZH, hi8(k_number_data)
  rcall display_memory_index_z ; display the digits of the k-number, that is 23162628

  ldi r16, 0x00
  out PORTB, r16
  out PORTD, r16
  ldi r18, 100
  rcall delay

  ldi	ZL, lo8(initials_data)
	ldi	ZH, hi8(initials_data)
  rcall display_memory_index_z ; display initials, that is M.K.B

  ldi r23, 1 ; the loop counter register
  rcall morse_loop ; call the loop for displaying the morse code

  ldi r16, 0x80 ; set the highest bit 1, and the rest 0
  rjmp ping_pong

  rjmp main

morse_loop: ; do it 50 times, until r23 is 51
  cpi r23, 51
  breq return_morse_loop

  ldi r17, 0x01
  ldi r19, 0x01 ; the constant 0x01

  mov r22, r23
  andi r22, 0x01 ; isolate the first bit of r22

  cpi r22, 0x01
  brne dont_do_normal ; branches if r22 is 0x00

  ldi ZL, lo8(morse_normal_order)
  ldi ZH, hi8(morse_normal_order)

  dont_do_normal:
  cpi r22, 0x00
  brne dont_do_reverse  ; branches if r22 is 0x01

  ldi ZL, lo8(morse_reverse_order)
  ldi ZH, hi8(morse_reverse_order)

  dont_do_reverse:
  rcall morse

  rcall dec_5

  good:
  ldi ZL, lo8(morse_five)
  ldi ZH, hi8(morse_five)
  rcall morse

  bad:

  inc r23
  rjmp morse_loop

  return_morse_loop:
  ret

morse:
  ; display morse code from index Z
  lpm r16, Z+

  cpi r16, 0
  breq morse_return

  out PORTB, r17
  eor r17, r19 ; xor the first bit of r17 with 1 (i.e. flip it)

  mov r18, r16
  rcall delay

  rjmp morse
  morse_return:
  ret

dec_5:
  dec r16
  breq bad
  dec r16
  breq bad
  dec r16
  breq bad
  dec r16
  breq bad
  dec r16
  breq good
  rjmp dec_5

ping_pong_going_right:
  ; displays from 10000000 to 000000010
  out PORTB, r16
  out PORTD, r16

  ldi r18, 50
  rcall delay ; delay for half a second

  lsr r16 ; shift the bits of r16 to the right

  cpi r16, 0x01
  brne ping_pong_going_right ; branches if the high bit is NOT at the most right position
  ret

ping_pong_going_left:
  ; displays from 0000001 to 010000000
  out PORTB, r16
  out PORTD, r16

  ldi r18, 50
  rcall delay ; delay for half a second

  lsl r16 ; shift the bits of r16 to the left

  cpi r16, 0x80
  brne ping_pong_going_left ; branches if the high bit is NOT at the most left position
  ret

ping_pong:
  ; for there not to be duplicates at the ends, each subroutine displays only 7 positions
  rcall ping_pong_going_right
  rcall ping_pong_going_left
  rjmp ping_pong

display_memory_index_z:
  ; display what is written in memory by using the Z index, delaying one second for each byte
  lpm r16, Z+
  cpi r16, 0
  breq return

  out PORTB, r16
  out PORTD, r16
  ldi r18, 100
  rcall delay

  rjmp display_memory_index_z
  return:
  ret

; code generated using the following tool: http://darcy.rsgc.on.ca/ACES/TEI4M/AVRdelay.html
delay:
  ldi r24, 208
  ldi r25, 201
L1:
  dec r25
  brne L1
  dec r24
  brne L1
  nop
  dec r18
  brne L1
  ret

k_number_data: .byte 0x02, 0x03, 0x01, 0x06, 0x02, 0x06, 0x02, 0x08, 0 ; 23162628
initials_data: .byte 0x0d, 0x1b, 0x0b, 0x1b, 0x02, 0 ; M.K.B
morse_normal_order: .byte 60, 20, 60, 60, 20, 60, 20, 20, 20, 20, 20, 20, 20, 140, 0 ; MEH with the interim parts
morse_reverse_order: .byte 20, 20, 20, 20, 20, 20, 20, 60, 20, 60, 60, 20, 60, 140, 0 ; HEM with the interim parts
morse_five: .byte 20, 20, 20, 20, 20, 20, 20, 20, 20, 140, 0 ; number 5 with interim parts