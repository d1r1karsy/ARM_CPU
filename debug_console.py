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

### Just demonstrate how to write stuff back, if you want
            try:
                port.write([wch])
                wch=wch+1
                if (wch > 10):
                    wch = 0
            except:
                errors = errors + 1

            try:
                ch=port.read(1)
                while int(ch[0]) != 255:
                    ch=port.read(1)
                i = 1;
                while i < debugbytes:
                    ch=port.read(1) 
                    if int(ch[0]) != 255:
                        break
                    i = i + 1;
                if int(ch[0]) == 255:
                    ch=port.read(1)

                thiscycle = ch[0]
                if thiscycle != lastcycle:
                    sys.stdout.write(hex(ch[0]))
                    sys.stdout.write(" ")
                i = 1
                while i < debugbytes:
                    ch=port.read(1)
                    if thiscycle != lastcycle:
                        sys.stdout.write(hex(ch[0]))
                        sys.stdout.write(" ")
                    i = i + 1
                if thiscycle != lastcycle:
                    sys.stdout.write("\n")
                lastcycle = thiscycle
            except:
                errors = errors + 1



