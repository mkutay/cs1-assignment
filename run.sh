avrdude -p atmega328p -c arduino -P /dev/tty.usbserial-A10LSO85 -D -U flash:w:temp.hex:i
rm temp.*
