#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Sideload Transition Helper
# Cleanly tears down USB gadget and stops adbd so minadbd has exclusive FunctionFS access

export PATH=/system/bin:/sbin

# Ensure /sideload mountpoint exists
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
rm -f /sideload/exit 2>/dev/null

# 1. Unbind UDC first (MANDATORY in Linux FunctionFS to set ffs->gadget = NULL before closing fds)
echo "none" > /config/usb_gadget/g1/UDC 2>/dev/null

# 2. Remove configuration function symlinks
rm -f /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
rm -f /config/usb_gadget/g1/configs/b.1/f2 2>/dev/null

# 3. Stop regular adbd completely
stop adbd 2>/dev/null
killall -9 adbd 2>/dev/null
pkill -9 -x adbd 2>/dev/null

CNT=0
while pgrep -x adbd >/dev/null 2>&1 && [ "$CNT" -lt 15 ]; do
    killall -9 adbd 2>/dev/null
    pkill -9 -x adbd 2>/dev/null
    usleep 10000 2>/dev/null || sleep 0.01 2>/dev/null
    CNT=$((CNT + 1))
done

# 4. Set USB IDs and Configuration for Sideload
echo 0x18d1 > /config/usb_gadget/g1/idVendor 2>/dev/null
echo 0xd001 > /config/usb_gadget/g1/idProduct 2>/dev/null
echo "adb" > /config/usb_gadget/g1/configs/b.1/strings/0x409/configuration 2>/dev/null

# 5. Pre-create the ffs.adb symlink so it is ready the moment minadbd enables FunctionFS
ln -sf /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null

# 6. Reset sys.usb.ffs.ready to 0 (will be set to 1 by minadbd once descriptors are written)
setprop sys.usb.ffs.ready 0

# 7. Pre-set sys.usb.state so TWRP recovery never times out
setprop sys.usb.state sideload

exit 0
