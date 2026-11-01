#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Sideload Transition Helper
# Cleanly tears down USB gadget and stops adbd so minadbd has exclusive FunctionFS access

export PATH=/system/bin:/sbin

# Ensure /sideload mountpoint and /dev/fuse exist with proper permissions
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
chmod 0666 /dev/fuse 2>/dev/null
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

# 6. Wait for minadbd to write FunctionFS descriptors (creating ep1 or setting sys.usb.ffs.ready=1)
# Note: Never set sys.usb.ffs.ready to 0 here to prevent race conditions with minadbd!
WAIT_CNT=0
while [ ! -e /dev/usb-ffs/adb/ep1 ] && [ "$(getprop sys.usb.ffs.ready)" != "1" ] && [ "$WAIT_CNT" -lt 30 ]; do
    usleep 50000 2>/dev/null || sleep 0.05
    WAIT_CNT=$((WAIT_CNT + 1))
done

# 7. Bind UDC to dwc2 controller now that FunctionFS is active!
echo "30740000.usb" > /config/usb_gadget/g1/UDC 2>/dev/null

# 8. Set sys.usb.state sideload so TWRP recovery confirms USB is ready
setprop sys.usb.state sideload

exit 0
