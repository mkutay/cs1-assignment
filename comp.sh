avr-as -g -mmcu=atmega328p -o temp.o $1.s
avr-ld -o temp.elf temp.o
avr-objcopy -O ihex -R .eeprom temp.elf temp.hex
