#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Sideload USB Preparation Helper
# Executed synchronously by init during `on property:sys.usb.config=none`
# BEFORE recovery calls fork() + execv(/system/bin/minadbd).

# 1. Ensure sideload mountpoint and FUSE device are ready
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
chmod 0666 /dev/fuse 2>/dev/null
rm -f /sideload/exit 2>/dev/null

# 2. Terminate ONLY exact process `adbd` (NEVER use `pkill adbd` without `-x`,
#    because substring matching would kill `minadbd`!).
killall -9 adbd 2>/dev/null
pkill -9 -x adbd 2>/dev/null

# 3. Wait synchronously until `adbd` has completely exited and closed /dev/usb-ffs/adb/ep0
CNT=0
while pgrep -x adbd >/dev/null 2>&1 && [ "$CNT" -lt 15 ]; do
    killall -9 adbd 2>/dev/null
    pkill -9 -x adbd 2>/dev/null
    sleep 0.05 2>/dev/null || usleep 50000 2>/dev/null
    CNT=$((CNT + 1))
done

exit 0
