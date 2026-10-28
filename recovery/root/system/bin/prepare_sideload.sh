#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Sideload Transition Helper
# Cleanly terminates adbd and resets FunctionFS before minadbd starts

# 1. Forcefully kill adbd and any stale minadbd
stop adbd 2>/dev/null
pkill -9 minadbd 2>/dev/null
pkill -9 adbd 2>/dev/null

CNT=0
while pgrep adbd >/dev/null 2>&1 && [ "$CNT" -lt 15 ]; do
    pkill -9 adbd 2>/dev/null
    sleep 0.05
    CNT=$((CNT + 1))
done

# 2. Unbind UDC and reset USB configfs
echo "none" > /config/usb_gadget/g1/UDC 2>/dev/null
rm -f /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
rm -f /config/usb_gadget/g1/configs/b.1/f2 2>/dev/null
setprop sys.usb.ffs.ready 0

# 3. Cleanly unmount and remount FunctionFS for ADB
# This guarantees that ffs->state in kernel resets to FFS_READ_DESCRIPTORS
umount -f /dev/usb-ffs/adb 2>/dev/null
umount -l /dev/usb-ffs/adb 2>/dev/null
mount -t functionfs adb /dev/usb-ffs/adb -o uid=2000,gid=2000 2>/dev/null || mount functionfs adb /dev/usb-ffs/adb uid=2000,gid=2000 2>/dev/null

# 4. Prepare /sideload mountpoint and permissions
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
rm -f /sideload/exit 2>/dev/null

# Brief settle pause
sleep 0.05
exit 0
