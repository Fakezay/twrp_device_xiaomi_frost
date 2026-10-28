#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Hardware Support Daemon
# Provides CPU Temp, Battery status & Persistent ADB / Sideload USB guardian

mkdir -p /tmp/battery 2>/dev/null
chmod 0777 /tmp/battery 2>/dev/null
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
chmod 0666 /dev/fuse 2>/dev/null

update_metrics() {
    # 1. Update CPU Temperature
    MAX_TEMP=0
    for tz in /sys/class/thermal/thermal_zone*; do
        if [ -f "$tz/temp" ]; then
            T=$(cat "$tz/temp" 2>/dev/null || echo 0)
            if [ -n "$T" ] && [ "$T" -gt 1000 ] && [ "$T" -lt 120000 ]; then
                if [ "$T" -gt "$MAX_TEMP" ]; then
                    MAX_TEMP="$T"
                fi
            fi
        fi
    done
    if [ "$MAX_TEMP" -gt 0 ]; then
        echo "$MAX_TEMP" > /tmp/cputemp.tmp
        mv -f /tmp/cputemp.tmp /tmp/cputemp 2>/dev/null
        chmod 0666 /tmp/cputemp 2>/dev/null
    fi

    # 2. Update Battery Capacity & Status
    for b in /sys/class/power_supply/jcmbattery /sys/class/power_supply/battery /sys/class/power_supply/*; do
        if [ -f "$b/capacity" ]; then
            CAP=$(cat "$b/capacity" 2>/dev/null)
            STAT=$(cat "$b/status" 2>/dev/null || echo "Discharging")
            if [ -n "$CAP" ]; then
                echo "$CAP" > /tmp/battery/capacity.tmp
                mv -f /tmp/battery/capacity.tmp /tmp/battery/capacity 2>/dev/null
                echo "$STAT" > /tmp/battery/status.tmp
                mv -f /tmp/battery/status.tmp /tmp/battery/status 2>/dev/null
                chmod 0666 /tmp/battery/* 2>/dev/null
                break
            fi
        fi
    done

    # 3. Sideload Cancel Guardian
    if [ -f "/sideload/exit" ]; then
        pkill -9 minadbd 2>/dev/null
        rm -f /sideload/exit 2>/dev/null
    fi

    # 4. USB Guardian: Keep ADB & Sideload alive without interfering with transitions
    CONF=$(getprop sys.usb.config)
    STATE=$(getprop sys.usb.state)
    FFS_READY=$(getprop sys.usb.ffs.ready)
    CONTROLLER="30740000.usb"

    if [ "$CONF" = "sideload" ] || [ "$CONF" = "adb,sideload" ]; then
        # Sideload mode: Ensure adbd is dead so minadbd has exclusive access to /dev/usb-ffs/adb
        if pgrep adbd >/dev/null 2>&1; then
            pkill -9 adbd 2>/dev/null
        fi
        if [ "$STATE" != "$CONF" ]; then
            setprop sys.usb.state "$CONF"
        fi
        # Only bind UDC once minadbd has written descriptors to ep0 (FFS_READY=1)
        if [ "$FFS_READY" = "1" ]; then
            CURRENT_UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)
            if [ "$CURRENT_UDC" != "$CONTROLLER" ]; then
                echo "$CONTROLLER" > /config/usb_gadget/g1/UDC 2>/dev/null
            fi
        fi
    elif [ "$CONF" = "none" ]; then
        # Transitioning state between modes - do not interfere!
        :
    else
        # Normal recovery mode
        # If sys.usb.config was set to mtp or mtp,adb, force to adb
        if [ "$CONF" = "mtp" ] || [ "$CONF" = "mtp,adb" ] || [ -z "$CONF" ]; then
            setprop sys.usb.config adb
            CONF="adb"
        fi

        # In normal mode, ensure adbd process is running
        if [ "$CONF" = "adb" ]; then
            if ! pgrep adbd >/dev/null 2>&1; then
                start adbd 2>/dev/null
            fi

            # Ensure ffs.adb link is present
            if [ ! -e "/config/usb_gadget/g1/configs/b.1/f1" ]; then
                rm -f /config/usb_gadget/g1/configs/b.1/f1 /config/usb_gadget/g1/configs/b.1/f2 2>/dev/null
                ln -sf /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
            fi

            if [ "$STATE" != "adb" ]; then
                setprop sys.usb.state adb
            fi

            # Ensure UDC is bound to USB controller only when FFS is ready
            if [ "$FFS_READY" = "1" ]; then
                CURRENT_UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)
                if [ "$CURRENT_UDC" != "$CONTROLLER" ]; then
                    echo "$CONTROLLER" > /config/usb_gadget/g1/UDC 2>/dev/null
                fi
            fi
        fi
    fi
}

# Run immediately once
update_metrics

if [ "$1" = "--once" ]; then
    exit 0
fi

# Loop in background every 1 second
while true; do
    sleep 1
    update_metrics
done
