# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Platform
TARGET_BOARD_PLATFORM := jr510

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := $(PRODUCT_DEVICE)

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic

# A/B device flags
TARGET_NO_RECOVERY := false
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += system system_ext product vbmeta_system boot vendor_boot

# Configuração Vendor Boot (OBRIGATÓRIA PARA HEADER V3 E RAMDISK 0)
BOARD_USES_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_VENDOR_RAMDISK_RECOVERY_EXCLUDE_RECOVERY_FROM_BOOT := true

# bootimg configuration
BOARD_BOOT_HEADER_VERSION := 3
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel

BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RAMDISK_USE_LZ4 := true
BOARD_KERNEL_PAGESIZE := 4096


# Define que vamos gerar o recovery e que ele deve ir para o vendor_boot
BOARD_USES_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true

# Esta linha é vital para o TWRP moderno:
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/etc/recovery.fstab

# Tamanho (usando o valor que você passou)
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 105906176



# Desativar Android Verified Boot (AVB)
BOARD_AVB_ENABLE := false
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Configurar chaves de teste para que o bootloader aceite a imagem
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1


# Forçar inclusão do ramdisk do TWRP
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true

# Tamanho exato da partição (101MB) - importante não deixar vazio
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 105906176

# Isso força o build a não descartar o ramdisk
BOARD_BUILD_VENDOR_BOOT_IMAGE := true





# includes make_f2fs to support userdata partition in f2fs
TARGET_USERIMAGES_USE_F2FS := true

# Creates metadata partition mount point under root for
# the devices with metadata partition
BOARD_USES_METADATA_PARTITION := true

# Workaround for error copying vendor files to recovery ramdisk
TARGET_COPY_OUT_VENDOR := vendor

BOARD_ROOT_EXTRA_FOLDERS := cust

# Adjusted flags for decryption
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)

# Define o caminho do DTB (certifique-se de que o nome do arquivo seja exatamente 'dtb')
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb

# Força o sistema a injetar o DTB na imagem
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)



# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# Fix for copying *.ko
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Properties
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop

##### TWRP Flags #####
TW_HAS_EDL_MODE := true
TW_BACKUP_EXCLUSIONS := /data/fonts
TW_DEFAULT_LANGUAGE := ru

# Include more languages than English
TW_EXTRA_LANGUAGES := true

# Version
TW_DEVICE_VERSION := frost_V13.0.25 - Weslley

# Brightness
TW_BRIGHTNESS_PATH := /sys/class/backlight/panel0-backlight/brightness
TW_DEFAULT_BRIGHTNESS := 1800
TW_MAX_BRIGHTNESS := 3514

# Add support of able to wake with touch after sleep
TW_NO_SCREEN_BLANK := true

# Remove vibration support
TW_NO_HAPTICS := true

# Battery
# https://gerrit.twrp.me/c/android_bootable_recovery/+/6945
TW_USE_LEGACY_BATTERY_SERVICES := true

# Time
TARGET_RECOVERY_QCOM_RTC_FIX := true

# Display
TARGET_SCREEN_DENSITY := 320
TW_THEME := portrait_hdpi
# Statusbar icons flags
TW_STATUS_ICONS_ALIGN := center
TW_CUSTOM_CLOCK_POS := 610

# Use our own USB config
TW_EXCLUDE_DEFAULT_USB_INIT := true

# For mounting NTFS
TW_INCLUDE_NTFS_3G := true

# Use mke2fs for formatting ext4 partitions
TARGET_USES_MKE2FS := true

# Kernel module loading for touch, battery etc
TW_LOAD_VENDOR_MODULES := $(shell echo \"$(shell ls $(DEVICE_PATH)/recovery/root/vendor/lib/modules/1.1)\")
TW_LOAD_VENDOR_BOOT_MODULES := true

# Include decryption support
TW_INCLUDE_CRYPTO := true
RECOVERY_SDCARD_ON_DATA := true
# include below when enabling decryption
# without these it may stuck on TWRP splash
TARGET_RECOVERY_DEVICE_MODULES += libion
RECOVERY_LIBRARY_SOURCE_FILES += $(TARGET_OUT_SHARED_LIBRARIES)/libion.so

# Don't mount apex files (no need for now)
TW_EXCLUDE_APEX := true

# Debuging flags
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_INCLUDE_RESETPROP := true

# OrangeFox Recovery Specific Flags
FOX_VERSION := R11.1
OF_MAINTAINER := Fakezay
OF_AB_DEVICE := 1
OF_USE_MAGISKBOOT := 1
OF_USE_MAGISKBOOT_FOR_ALL_PATCHES := 1
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_NO_MIUI_PATCH_WARNING := 1
OF_SCREEN_H := 1650
OF_STATUS_H := 80
OF_STATUS_INDENT_LEFT := 40
OF_STATUS_INDENT_RIGHT := 40
OF_CLOCK_POS := 1
OF_USE_GREEN_LED := 0
OF_FLASHLIGHT_ENABLE := 0

