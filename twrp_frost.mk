# Inherit from common AOSP config
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)


# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := frost
PRODUCT_NAME := twrp_$(PRODUCT_DEVICE)
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := frost
PRODUCT_MANUFACTURER := Xiaomi

# Default device path for tree
DEVICE_PATH := device/xiaomi/frost

# Inherit from device
$(call inherit-product, $(DEVICE_PATH)/device.mk)
