# Inherit from common AOSP config
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)


# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := frost
PRODUCT_NAME := twrp_$(PRODUCT_DEVICE)
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := frost
PRODUCT_MANUFACTURER := Xiaomi

# Default device path for tree
DEVICE_PATH := device/xiaomi/frost

# Inherit from device
$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

#PRODUCT_BUILD_PROP_OVERRIDES += \
#    PRIVATE_BUILD_DESC="frost-user 11 RD2A.211001.002 V13.0.20.0.RGFMIXM release-keys"

#BUILD_FINGERPRINT := Redmi/frost/frost:11/RD2A.211001.002/V13.0.20.0.RGFMIXM:user/release-keys
