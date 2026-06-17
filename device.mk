# Inherit from common AOSP config
#$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
# Inherit virtual_ab_ota product
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch.mk)

# Installs gsi keys into ramdisk, to boot a GSI with verified boot.
$(call inherit-product, $(SRC_TARGET_DIR)/product/gsi_keys.mk)

# Dynamic partitions
PRODUCT_SHIPPING_API_LEVEL := 30
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Boot control hal for A/B
PRODUCT_PACKAGES += android.hardware.boot@1.1-impl-jlq.recovery

# Blacklist
PRODUCT_SYSTEM_PROPERTY_BLACKLIST += ro.bootimage.build.date.utc ro.build.date.utc

# Copy modules for depmod
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*.ko,$(DEVICE_PATH)/recovery/root/vendor/lib/modules/1.1,$(TARGET_COPY_OUT_RECOVERY)/lib/modules)
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/etc/recovery.fstab
