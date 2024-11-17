.org 0 ; address from which to start placing instructions

.equ SREG, 0x3f
.equ DDRB, 0x04
.equ PORTB, 0x05 ; PORTB hosts the lower 4 bits of our byte (our leds)
.equ PORTD, 0x0b ; PORTD hosts the higher 4 bits of our byte (our leds)
.equ DDRD, 0x0a
.equ DELAY_VAR, 0x12 ; register 18
.equ NUMBER_ONE, 0x13 ; register 19
.equ MORSE_COUNTER, 0x17 ; register 23
.equ DIV_BY_FIVE_COUNTER, 0x16 ; register 22
.equ FLIP_BIT, 0x11 ; register 17

main:
  ldi NUMBER_ONE, 0x01 ; the constant 0x01

  ldi r16, 0
  out SREG, r16 ; clear SREG
  ldi r16, 0x0f
  out DDRB, r16 ; set first 4 pins of PORTB as output
  ldi r16, 0xf0
  out DDRD, r16 ; set last 4 pins of PORTD as output

  ; set Z index to the first address of the k-number data
  ldi	ZL, lo8(k_number_data)
	ldi	ZH, hi8(k_number_data)
  rcall display_memory_index_z ; display the digits of the k-number, that is 23162628

  ; set Z index to the first address of the initials data
  ldi	ZL, lo8(initials_data)
	ldi	ZH, hi8(initials_data)
  rcall display_memory_index_z ; display initials, that is M.K.B

  ldi DIV_BY_FIVE_COUNTER, 1
  ldi MORSE_COUNTER, 1
  rcall morse_loop ; call the loop for displaying the morse code

  ldi r16, 0x80 ; set the highest bit 1, and the rest 0
  rjmp ping_pong

  rjmp main

morse_loop: ; do it 50 times, that is until MORSE_COUNTER is 51
  ldi FLIP_BIT, 0x01
  
  ; if MORSE_COUNTER is odd, then its first bit is 1; if it's even, then its first bit is 0
  ; r21 will hold the isolated bit
  mov r21, MORSE_COUNTER
  andi r21, 0x01 ; isolate the first bit of r21

  cpi r21, 0x01 ; essentially checks if MORSE_COUNTER is odd
  brne not_odd ; branches if r21 is 0x00

  ; set Z index to the first address of the normal order of the morse code
  ldi ZL, lo8(morse_normal_order)
  ldi ZH, hi8(morse_normal_order)

  not_odd:
  cpi r21, 0x00 ; essentially checks if MORSE_COUNTER is even
  brne not_even ; branches if r21 is 0x01

  ; set Z index to the first address of the reverse order of the morse code
  ldi ZL, lo8(morse_reverse_order)
  ldi ZH, hi8(morse_reverse_order)

  not_even:
  rcall morse ; display the morse code according to what Z is pointing to

  cpi DIV_BY_FIVE_COUNTER, 5 ; checks if the morse counter is divisible by 5
  brne not_div_by_5 ; branches if the morse counter is not divisible by 5

  ldi DIV_BY_FIVE_COUNTER, 0 ; reset the divisibility by 5 counter
  ldi FLIP_BIT, 0x01
  ldi ZL, lo8(morse_five) ; set Z index to the first address of morse code of five
  ldi ZH, hi8(morse_five)
  rcall morse ; display morse code using Z index

  not_div_by_5:
  inc DIV_BY_FIVE_COUNTER
  inc MORSE_COUNTER

  cpi MORSE_COUNTER, 51 ; check if we have reached the maximum loop counter, that is 51
  brne morse_loop ; continues with the loop if counter <= 50
  ret

morse: ; display morse code from index Z
  lpm r16, Z+ ; load data from memory that was pointed by Z, and increment Z
  cpi r16, 0 ; checks if we have reached the end of the data
  breq morse_return ; if yes, return

  ; as the morse code will display on and off continuously, we can hold that value as a bit and flip it
  out PORTB, FLIP_BIT
  eor FLIP_BIT, NUMBER_ONE ; xor the first bit of FLIP_BIT with 1 (i.e. flip it)

  mov DELAY_VAR, r16
  rcall delay ; delay as read from memory

  rjmp morse
  morse_return:
  ret

ping_pong_going_right: ; displays from 10000000 to 000000010
  out PORTB, r16
  out PORTD, r16

  ldi DELAY_VAR, 50
  rcall delay ; delay for half a second

  lsr r16 ; shift the bits of r16 to the right

  cpi r16, 0x01
  brne ping_pong_going_right ; branches if the high bit is NOT at the most right position
  ret

ping_pong_going_left: ; displays from 0000001 to 010000000
  out PORTB, r16
  out PORTD, r16

  ldi DELAY_VAR, 50
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
  lpm r16, Z+ ; read from memory and increment Z
  cpi r16, 0
  breq return_display_memory_index_z ; branch and return if we have reached the end of the data

  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 100
  rcall delay ; delay for a second

  rjmp display_memory_index_z
  return_display_memory_index_z:
  ret

; a part of the following code was generated using the following tool: http://darcy.rsgc.on.ca/ACES/TEI4M/AVRdelay.html
; 2 + 202*3-1 + 207*(3 + 256*3 - 1)-1 + 4 = 160000 cycles are run for DELAY_VAR times
delay:
  ldi r24, 208
  ldi r25, 202
inner_delay:
  dec r25 ; 1 instruction
  brne inner_delay ; 2 instructions if branch, 1 otherwise
  dec r24
  brne inner_delay
  nop
  dec DELAY_VAR
  brne delay
  ret

; we can hold our data values in memory, and by adding a zero at the end, we 
; can easily find if we have reached the end of our data, noting that
; adding a zero at the end is similar to how strings are held in memory in C.
k_number_data: .byte 0x02, 0x03, 0x01, 0x06, 0x02, 0x06, 0x02, 0x08, 0 ; 23162628
initials_data: .byte 0x0d, 0x1b, 0x0b, 0x1b, 0x02, 0 ; M.K.B
morse_normal_order: .byte 60, 20, 60, 60, 20, 60, 20, 20, 20, 20, 20, 20, 20, 140, 0 ; MEH with the interim parts
morse_reverse_order: .byte 20, 20, 20, 20, 20, 20, 20, 60, 20, 60, 60, 20, 60, 140, 0 ; HEM with the interim parts
morse_five: .byte 20, 20, 20, 20, 20, 20, 20, 20, 20, 140, 0 ; number 5 with interim parts
