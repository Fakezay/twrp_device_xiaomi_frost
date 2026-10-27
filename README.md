# TWRP Device Tree for Xiaomi POCO C40 (`frost` / `c3q`)

Custom Team Win Recovery Project (TWRP 3.7.x) device tree for Xiaomi POCO C40 (JLQ JR510 SoC, Android 11).

[![GPLv3+](https://img.shields.io/badge/license-GPLv3+-red.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

---

## Device Specifications

| Feature | Specification |
| :--- | :--- |
| **Device** | Xiaomi POCO C40 (`frost` / `c3q`) |
| **SoC** | JLQ JR510 (4x Cortex-A55 @ 2.0GHz + 4x Cortex-A55 @ 1.5GHz) |
| **GPU** | ARM Mali-G52 |
| **Shipped Android Version** | Android 11 (MIUI V13.0.13 - V13.0.25) |
| **Display** | 6.71" IPS LCD, 720 x 1650 pixels |
| **Recovery Architecture** | A/B Recovery-as-Boot (`boot.img`, 96MB) |

---

## Credits & Acknowledgments

* **[TeamWin](https://github.com/TeamWin)** for the TWRP project and recovery source code.
* **[Carlos Lopes (lopestom)](https://github.com/lopestom/twrp_device_xiaomi_frost)** for the initial TWRP device tree base and hardware groundwork.
* **[Meau 🐾](https://4pda.to)** for research and contributions on 4PDA.
* **[Fakezay](https://github.com/Fakezay)** for maintenance, kernel driver fixes (CPU temperature, battery metrics, ADB Sideload & AVB signing).

---

## Flashing Instructions

```bash
# 1. Boot temporarily to test:
fastboot boot boot.img

# 2. Permanent installation:
fastboot flash boot boot.img
fastboot reboot
```

---

## Compiling via Minimal Manifest (AOSP twrp-11)

```bash
# 1. Initialize repo
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp -b twrp-11 --depth=1
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

# 2. Clone device tree
git clone https://github.com/Fakezay/twrp_device_xiaomi_frost.git device/xiaomi/frost -b twrp-11

# 3. Compile boot image
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
source build/envsetup.sh
lunch twrp_frost-eng
mka bootimage -j$(nproc)
```

Automated cloud compilation is also available via **GitHub Actions** in `.github/workflows/New2_twrp.yml`.
