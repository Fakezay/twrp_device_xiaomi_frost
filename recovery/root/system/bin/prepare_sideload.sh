#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Sideload Transition Helper
# Prepares USB configfs for minadbd without killing minadbd or blocking TWRP

export PATH=/system/bin:/sbin

# Lock / debounce to prevent rapid re-entry
NOW=$(date +%s 2>/dev/null || echo 0)
LAST_PREP=$(cat /tmp/sideload_prep_time 2>/dev/null || echo 0)
if [ "$NOW" -gt 0 ] && [ "$LAST_PREP" -gt 0 ]; then
    DIFF=$((NOW - LAST_PREP))
    if [ "$DIFF" -lt 2 ] && [ "$DIFF" -ge 0 ]; then
        exit 0
    fi
fi
echo "$NOW" > /tmp/sideload_prep_time 2>/dev/null

# 1. Stop regular adbd only (NEVER touch minadbd!)
stop adbd 2>/dev/null
killall -9 adbd 2>/dev/null
pkill -9 -x adbd 2>/dev/null

CNT=0
while pgrep -x adbd >/dev/null 2>&1 && [ "$CNT" -lt 10 ]; do
    killall -9 adbd 2>/dev/null
    pkill -9 -x adbd 2>/dev/null
    sleep 0.02 2>/dev/null || usleep 20000 2>/dev/null
    CNT=$((CNT + 1))
done

# 2. Unbind UDC and remove current function links
echo "none" > /config/usb_gadget/g1/UDC 2>/dev/null
rm -f /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
rm -f /config/usb_gadget/g1/configs/b.1/f2 2>/dev/null
setprop sys.usb.ffs.ready 0

# 3. Ensure FunctionFS endpoint permissions (DO NOT unmount /dev/usb-ffs/adb!)
chmod 0770 /dev/usb-ffs/adb 2>/dev/null

# 4. Prepare /sideload mountpoint and clear exit flag
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
rm -f /sideload/exit 2>/dev/null

# Brief 50ms pause to ensure UDC unbind settles in kernel
sleep 0.05
exit 0
