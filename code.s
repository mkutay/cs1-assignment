.org 0 ; Address from which to start placing instructions.

.equ SREG, 0x3f
.equ DDRB, 0x04
.equ DDRD, 0x0a
.equ PORTB, 0x05 ; The lower 4 bits of our byte (leds).
.equ PORTD, 0x0b ; The higher 4 bits of our byte (leds).
.equ DELAY_VAR, 0x12 ; register 18 - The delay variable. It is used to delay for a certain amount of time.
.equ NUMBER_ONE, 0x13 ; register 19 - Holds the constant 0x01 (which is used to flip a bit with XOR).
.equ MORSE_COUNTER, 0x17 ; register 23 - The counter for displaying the morse code, up until 50.
.equ DIV_BY_FIVE_COUNTER, 0x16 ; register 22 - The counter used for finding the indexes that are divisible by 5 (will go from 1 to 5 and repeat)
.equ FLIP_BIT, 0x11 ; register 17 - To cycle through the morse code data to make the led ON or OFF (see the bottom of the code)

main:
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

  ; Set Z index to the first address of the k-number data. 
  ; NOTE: We only want single bytes from the memory, but the program memory can hold
  ; up to two bytes (a word) at a time, so we only set the LOWER byte of the Z index as the address.
  ldi	ZL, k_number_data
  ; Here, the Z index is pointing to the first address of the k-number data, and the instruction
  ; reads the byte at that address (and puts it into r16) and then increments the Z index to
  ; point to the next address. Similar to how "r16 = Memory[Z]; Z++;" would work in Java.
  lpm r16, Z+
  rcall display_memory_index_z ; Display the digits of the K-number (that is 23162628) by reading from memory.

  ; Similar to what was done above, set the Z index to the first address of the initials data.
  ldi	ZL, initials_data
  lpm r16, Z+ ; Load from program memory and then increment Z.
  rcall display_memory_index_z ; Display initials, that is "M.K.B"

  rcall morse_loop

  ldi r16, 0x80 ; Set the highest bit 1, and the rest 0, which is the initial state of the leds for the ping pong part.
  rjmp ping_pong

; Display the ping pong section continously.
ping_pong:
  ; For there not to be duplicates at the ends, each subroutine displays only 7 positions.
  rcall ping_pong_going_right
  rcall ping_pong_going_left
  rjmp ping_pong ; Repeat the ping pong indefinitely.

; Displays the ping pong sequence from 10000000 to 00000010, going right.
ping_pong_going_right:
  ; Display r16 on the leds.
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 25
  rcall delay ; Delay for quarter of a second.

  lsr r16 ; Shift the bit on r16 to the right.
  cpi r16, 0x01
  ; Branches if the high bit is NOT at the most right position. If it is at the most
  ; right position, then we want to go left this time, so we return.
  brne ping_pong_going_right
  ret

; Displays the ping pong from 00000001 to 01000000, going left.
ping_pong_going_left:
  ; Display the register r16 on the leds.
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 25
  rcall delay ; delay for quarter of a second

  lsl r16 ; Shift the bit on r16 to the left.
  cpi r16, 0x80
  ; Branches if the high bit is NOT at the most left position, if it is we want to go right from now on, so we return.
  brne ping_pong_going_left
  ret

; This loop is for displaying the morse sequence 50 times, that is until MORSE_COUNTER is 51
morse_loop:
  ; If MORSE_COUNTER is odd, then its lowest bit is 1; if it's even, then its lowest bit is 0.
  ; We can use this to determine if we should display the morse code in the normal order or the reverse order.
  mov r21, MORSE_COUNTER ; r21 will hold the isolated bit (which is just a temporary variable).
  andi r21, 0x01 ; Isolate the first bit of r21.

  ; Essentially checks if MORSE_COUNTER is odd or even (that is, if the lowest bit is 1 or 0).
  ; We have two different branches as we don't want the Z pointer to be overwritten.
  cpi r21, 0x01
  brne not_odd ; Branches if r21 != 0x01, so branches if r21 == 0x00.
  ldi ZL, morse_normal_order ; Set Z index to the first address of the "normal" order of the morse code.

not_odd:
  cpi r21, 0x00 ; Essentially checks if MORSE_COUNTER is even.
  brne not_even ; Branches if r21 != 0x00, so branches if r21 == 0x01.
  ldi ZL, morse_reverse_order ; Set Z index to the first address of the reverse order of the morse code.

not_even:
  ldi FLIP_BIT, 0x01
  lpm r16, Z+ ; Load data from Program Memory that was pointed by Z, and then increment Z.
  rcall morse ; Display the morse code according to what Z is pointing to (either the normal or the reverse order).

  cpi DIV_BY_FIVE_COUNTER, 5 ; Checks if the morse counter is equal to 5, (it checks if the iteration is divisible by 5).
  brne not_div_by_5 ; Branches if the morse counter is not divisible by 5.

  ldi DIV_BY_FIVE_COUNTER, 0 ; Reset the divisibility by 5 counter to 0, as it will be incremented later to a one.
  ldi FLIP_BIT, 0x01 ; Reset the flip bit.

  ; Wait for 600 ms, which indicates the end of the letter, as we still have to display the number 5.
  ldi r16, 0
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 60
  rcall delay

  ldi ZL, morse_five ; Set Z index to the first address of morse code of 5.
  lpm r16, Z+ ; Load data from Program Memory that was pointed by Z, and increment Z afterwards.
  rcall morse ; Display morse code using Z index; here, it will display the morse code for the number 5.

not_div_by_5:
  ; Increment the counters
  inc DIV_BY_FIVE_COUNTER
  inc MORSE_COUNTER

  ; Wait for 1400 ms, which indicates the end of the word.
  ldi r16, 0
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 140
  rcall delay

  cpi MORSE_COUNTER, 51 ; Check if we have reached the maximum loop counter, which is 51.
  brne morse_loop ; Continues with the loop if MORSE_COUNTER <= 50.
  ret

; Display morse code from index Z until we reach the end of the data, that is the value 0.
; The values read from memory determine the delay for the led to be ON or OFF.
; As the morse code will display on and off repeatedly, we can hold that value as a bit and flip it continuously.
; The data is also formatted in a way that the first byte is the delay for the led to be ON,
; the second byte is the delay for the led to be OFF, and so on.
morse:
  out PORTB, FLIP_BIT ; FLIP_BIT is used to determine if the led should be ON or OFF.
  eor FLIP_BIT, NUMBER_ONE ; XOR the first bit of FLIP_BIT with 1 (i.e. flip it).

  mov DELAY_VAR, r16
  rcall delay ; Delay the amount as loaded from memory.

  lpm r16, Z+ ; Load from program memory and increment Z.
  cpi r16, 0 ; Checks if we have reached the end of the data, as the value 0 determines the end.
  brne morse ; If we have not reached the end, continue displaying values.
  ret ; If we have reached the end, return.

; Displays what was read from memory by using the Z index on the leds, delaying one
; second for each byte of information. The data is read from the memory until the value 0 is reached.
display_memory_index_z:
  ; Display what was read from memory (which is in r16).
  out PORTB, r16
  out PORTD, r16
  ldi DELAY_VAR, 100
  rcall delay ; Delay for a second.

  lpm r16, Z+ ; Load from program memory and increment the Z index afterwards.
  cpi r16, 0
  brne display_memory_index_z ; Branch if we still have to display more data
  ret ; Returns if we have reached the end of the data (that is we read the value 0).

; A part of the following code was generated using the following tool: http://darcy.rsgc.on.ca/ACES/TEI4M/AVRdelay.html
; 2 + 202*3-1 + 207*(3 + 256*3 - 1)-1 + 1 + 1 + 2 = 160000 cycles are run for each DELAY_VAR
; So, for instance, if DELAY_VAR is 100, 16 million cycles will be gone through, so there will be a delay of a single second.
delay:
  ldi r24, 208
  ldi r25, 202
inner_delay:
  dec r25 ; 1 instruction, note that if r25 equals to 0, the register underflows to 255
  brne inner_delay ; 2 instructions if branches, 1 otherwise
  dec r24 ; 1 instruction
  brne inner_delay ; 2 instructions if branches, 1 otherwise
  nop ; do nothing
  dec DELAY_VAR
  brne delay
  ret

; We can hold our data values in memory as single bytes, each memory space would
; hold a byte that we will read from, and by adding a zero at the end,
; we can easily find if we have reached the end of our data. Note that
; adding a zero at the end is similar to how strings are held in memory in C.
; Finally, the instructions that were used was informed by these pages:
; http://www.rjhcoding.com/avr-asm-sram.php and http://www.rjhcoding.com/avr-asm-pm.php.
k_number_data: .byte 0x02, 0x03, 0x01, 0x06, 0x02, 0x06, 0x02, 0x08, 0 ; hex values of the digits of "23162628"
initials_data: .byte 0x0d, 0x1b, 0x0b, 0x1b, 0x02, 0 ; hex values of each character of "M.K.B"

; Morse data - the value in the first byte will be used as a DELAY to display the led ON,
; the second byte will be used as a delay to display the led OFF, and so on by alternating... until we reach the end.
morse_normal_order: .byte 60, 20, 60, 60, 20, 60, 20, 20, 20, 20, 20, 20, 20, 0 ; "MEH" in morse code with the interim parts.
morse_reverse_order: .byte 20, 20, 20, 20, 20, 20, 20, 60, 20, 60, 60, 20, 60, 0 ; "HEM" in morse code with the interim parts.
morse_five: .byte 20, 20, 20, 20, 20, 20, 20, 20, 20, 0 ; Number 5 in morse code with interim parts.
