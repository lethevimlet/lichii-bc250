#!/usr/bin/env python3
# fakepad.py <script>: a uinput gamepad named like a Bluetooth 8BitDo (bus 0x05, 2dc8:6012) that plays a
# button script: "wait 30; tap START; wait 5; tap EAST ..." (BTN names), then exits (device removed).
import fcntl, os, struct, sys, time
UI_SET_EVBIT, UI_SET_KEYBIT, UI_SET_ABSBIT = 0x40045564, 0x40045565, 0x40045567
UI_DEV_CREATE, UI_DEV_DESTROY = 0x5501, 0x5502
EV_SYN, EV_KEY, EV_ABS = 0, 1, 3
BTN = dict(SOUTH=0x130, EAST=0x131, NORTH=0x133, WEST=0x134, TL=0x136, TR=0x137, SELECT=0x13a,
           START=0x13b, MODE=0x13c, THUMBL=0x13d, THUMBR=0x13e)
ABS = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x10, 0x11]  # X Y Z RX RY RZ HAT0X HAT0Y
fd = os.open('/dev/uinput', os.O_WRONLY | os.O_NONBLOCK)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY); fcntl.ioctl(fd, UI_SET_EVBIT, EV_ABS)
for code in BTN.values(): fcntl.ioctl(fd, UI_SET_KEYBIT, code)
for code in ABS: fcntl.ioctl(fd, UI_SET_ABSBIT, code)
absmax = [0] * 64; absmin = [0] * 64
for code in ABS:
    absmin[code], absmax[code] = (-1, 1) if code >= 0x10 else ((0, 255) if code in (2, 5) else (-32768, 32767))
dev = struct.pack('80sHHHHi', b'8BitDo Ultimate 2 Wireless (test)', 0x05, int(os.environ.get('PADVID','0x2dc8'),16), int(os.environ.get('PADPID','0x6012'),16), 1, 0)
dev += struct.pack('64i', *absmax) + struct.pack('64i', *absmin) + struct.pack('64i', *([0] * 64)) + struct.pack('64i', *([0] * 64))
os.write(fd, dev); fcntl.ioctl(fd, UI_DEV_CREATE)
def emit(t, c, v): os.write(fd, struct.pack('llHHi', 0, 0, t, c, v))
def syn(): emit(EV_SYN, 0, 0)
print('created', flush=True)
for step in ' '.join(sys.argv[1:]).split(';'):
    w = step.split()
    if not w: continue
    if w[0] == 'wait': time.sleep(float(w[1]))
    elif w[0] == 'tap':
        emit(EV_KEY, BTN[w[1]], 1); syn(); time.sleep(0.15); emit(EV_KEY, BTN[w[1]], 0); syn(); print('tap', w[1], time.strftime('%T'), flush=True)
    elif w[0] == 'stick':  # stick <secs>: left stick up for <secs>
        emit(EV_ABS, 1, -32767); syn(); time.sleep(float(w[1])); emit(EV_ABS, 1, 0); syn(); print('stick', flush=True)
time.sleep(1)
fcntl.ioctl(fd, UI_DEV_DESTROY); os.close(fd)
