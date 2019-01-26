import tinyprog
import usb
import sys

ports = tinyprog.get_ports("1d50:6130")

errors = 0
lastcycle = 0

## Adjust this number to be the number of debug bytes
debugbytes = 4

print(ports)
for port in ports:
    with port:
        wch=0
        while True:

            try:
                i = 0
                while i < 8:
                    ch=port.read(1)
                    sys.stdout.write(hex(ch[0]))
                    sys.stdout.write(" ")
                    i = i + 1
                sys.stdout.write("\n")
            except:
                errors = errors + 1



