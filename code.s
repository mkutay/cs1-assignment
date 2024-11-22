.org 0 ; address from which to start placing instructions

.equ SREG, 0x3f
.equ DDRB, 0x04
.equ DDRD, 0x0a
.equ PORTB, 0x05 ; the lower 4 bits of our byte (leds)
.equ PORTD, 0x0b ; the higher 4 bits of our byte (leds)
.equ DELAY_VAR, 0x12 ; register 18 - the delay variable, used in delaying for a certain amount of time
.equ NUMBER_ONE, 0x13 ; register 19 - holds the constant 0x01
.equ MORSE_COUNTER, 0x17 ; register 23 - the counter for displaying the morse code, up until 50
.equ DIV_BY_FIVE_COUNTER, 0x16 ; register 22 - the counter used for finding the indexes that are divisible by 5 (will go from 1 to 5 and repeat)
.equ FLIP_BIT, 0x11 ; register 17 - to cycle through the morse code data to make the led ON or OFF

main: ; the main subroutine
  ; initialise register variables
  ldi NUMBER_ONE, 0x01
  ldi DIV_BY_FIVE_COUNTER, 1
  ldi MORSE_COUNTER, 1

  ldi r16, 0
  out SREG, r16 ; clear SREG
  ldi r16, 0x0f
  out DDRB, r16 ; set first 4 pins of PORTB as output
  ldi r16, 0xf0
  out DDRD, r16 ; set last 4 pins of PORTD as output

  ; set Z index to the first address of the k-number data
  ; NOTE: we only want single bytes from the memory, but the program memory can hold
  ; up to two bytes (a word), so we only set the LOWER byte of the Z index as read from memory
  ldi	ZL, k_number_data
  rcall display_memory_index_z ; display the digits of the k-number, that is 23162628

  ; set Z index to the first address of the initials data
  ldi	ZL, initials_data
  rcall display_memory_index_z ; display initials, that is M.K.B

  rcall morse_loop

  ldi r16, 0x80 ; set the highest bit 1, and the rest 0, which is the initial state of the leds
ping_pong: ; display the ping pong section continously
  ; for there not to be duplicates at the ends, each subroutine displays only 7 positions
  rcall ping_pong_going_right
  rcall ping_pong_going_left
  rjmp ping_pong ; repeat the ping pong indefinitely

ping_pong_going_right: ; displays from 10000000 to 00000010
  ; display the register r16 on the leds
  out PORTB, r16
  out PORTD, r16

  ldi DELAY_VAR, 50
  rcall delay ; delay for half a second

  lsr r16 ; shift the bits of r16 to the right
  cpi r16, 0x01
  brne ping_pong_going_right ; branches if the high bit is NOT at the most right position, if yes we want to go left this time, so we return
  ret

ping_pong_going_left: ; displays from 00000001 to 01000000
  ; display the register r16 on the leds
  out PORTB, r16
  out PORTD, r16

  ldi DELAY_VAR, 50
  rcall delay ; delay for half a second

  lsl r16 ; shift the bits of r16 to the left
  cpi r16, 0x80
  brne ping_pong_going_left ; branches if the high bit is NOT at the most left position, if yes we want to go right from now on
  ret

morse_loop: ; loop through it 50 times, that is until MORSE_COUNTER is 51
  ; if MORSE_COUNTER is odd, then its lowest bit is 1; if it's even, then its lowest bit is 0
  mov r21, MORSE_COUNTER ; r21 will hold the isolated bit (which is just a temporary variable)
  andi r21, 0x01 ; isolate the first bit of r21

  ; essentially checks if MORSE_COUNTER is odd or even
  ; we have two branches as we don't want the Z pointer to be overwritten
  cpi r21, 0x01
  brne not_odd ; branches if r21 != 0x01, so branches if r21 == 0x00
  ldi ZL, morse_normal_order ; set Z index to the first address of the "normal" order of the morse code

not_odd:
  cpi r21, 0x00 ; essentially checks if MORSE_COUNTER is even
  brne not_even ; branches if r21 != 0x00, so branches if r21 == 0x01
  ldi ZL, morse_reverse_order ; set Z index to the first address of the reverse order of the morse code

not_even:
  ldi FLIP_BIT, 0x01
  rcall morse ; display the morse code according to what Z is pointing to, that is either the normal or the reverse order

  cpi DIV_BY_FIVE_COUNTER, 5 ; checks if the morse counter is equal to 5, (that is it checks if the iteration is divisible by 5)
  brne not_div_by_5 ; branches if the morse counter is not divisible by 5

  ldi DIV_BY_FIVE_COUNTER, 0 ; reset the divisibility by 5 counter to 0, as it will be incremented later
  ldi FLIP_BIT, 0x01
  ldi ZL, morse_five ; set Z index to the first address of morse code for 5
  rcall morse ; display morse code using Z index

not_div_by_5:
  ; increment the counters
  inc DIV_BY_FIVE_COUNTER
  inc MORSE_COUNTER

  ; wait for 1400 ms to indicate the end of the word
  ldi r16, 0
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 140
  rcall delay

  cpi MORSE_COUNTER, 51 ; check if we have reached the maximum loop counter, that is 51
  brne morse_loop ; continues with the loop if counter <= 50
  ret

morse: ; display morse code from index Z until we reach the end of the data, that is the value 0
  lpm r16, Z+ ; Load data from Program Memory that was pointed by Z, and increment Z
  cpi r16, 0 ; checks if we have reached the end of the data, as the value 0 determines the end
  breq morse_return ; if yes, return

  ; as the morse code will display on and off continuously, we can hold that value as a bit and flip it continuously
  out PORTB, FLIP_BIT
  eor FLIP_BIT, NUMBER_ONE ; xor the first bit of FLIP_BIT with 1 (i.e. flip it)

  mov DELAY_VAR, r16
  rcall delay ; delay the amount as loaded from memory
  rjmp morse
morse_return:
  ret

display_memory_index_z:
  ; display what is written in memory by using the Z index, delaying one second for each byte
  lpm r16, Z+ ; load from program memory and then increment Z (similar to how "r16 = Z++" would work in Java)
  cpi r16, 0
  breq return_display_memory_index_z ; branch and return if we have reached the end of the data

  ; display what was read from memory
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 100
  rcall delay ; delay for a second

  rjmp display_memory_index_z
return_display_memory_index_z:
  ret

; a part of the following code was generated using the following tool: http://darcy.rsgc.on.ca/ACES/TEI4M/AVRdelay.html
; 2 + 202*3-1 + 207*(3 + 256*3 - 1)-1 + 1 + 1 + 2 = 160000 cycles are run for each DELAY_VAR
; so, for instance, if DELAY_VAR is 100, 16 million cycles will be gone through, so there will be a delay of a single second 
delay:
  ldi r24, 208
  ldi r25, 202
inner_delay:
  dec r25 ; 1 instruction, note that if r25 equals to 0, the register underflows to 255
  brne inner_delay ; 2 instructions if branch, 1 otherwise
  dec r24 ; 1 instruction
  brne inner_delay ; 2 instructions if branches, 1 otherwise
  nop ; do nothing
  dec DELAY_VAR
  brne delay
  ret

; we can hold our data values in memory as single bytes, each memory space would
; hold a byte that we will read from, and by adding a zero at the end,
; we can easily find if we have reached the end of our data, noting that
; adding a zero at the end is similar to how strings are held in memory in C.
; finally, the instructions that were used was informed by these pages:
; http://www.rjhcoding.com/avr-asm-sram.php and http://www.rjhcoding.com/avr-asm-pm.php
k_number_data: .byte 0x02, 0x03, 0x01, 0x06, 0x02, 0x06, 0x02, 0x08, 0 ; hex values of the digits of "23162628"
initials_data: .byte 0x0d, 0x1b, 0x0b, 0x1b, 0x02, 0 ; hex values of each character of "M.K.B"

; morse data - the value in the first byte will be used as a DELAY to display the led ON,
; the second byte will be used as a delay to display the led OFF, and so on by alternating... until we reach the end
morse_normal_order: .byte 60, 20, 60, 60, 20, 60, 20, 20, 20, 20, 20, 20, 20, 0 ; "MEH" in morse code with the interim parts and the word-end
morse_reverse_order: .byte 20, 20, 20, 20, 20, 20, 20, 60, 20, 60, 60, 20, 60, 0 ; "HEM" in morse code with the interim parts and the word-end
morse_five: .byte 20, 20, 20, 20, 20, 20, 20, 20, 20, 0 ; number 5 in morse code with interim parts and the word-end
