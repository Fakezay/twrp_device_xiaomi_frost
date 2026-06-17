LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),frost)
  # Inclui todos os makefiles das subpastas (necessário para os componentes do TWRP)
  include $(call all-subdir-makefiles,$(LOCAL_PATH))

  # Define o dispositivo explicitamente para o sistema de build
  include $(CLEAR_VARS)
  LOCAL_MODULE := device_frost
  LOCAL_MODULE_TAGS := optional
  LOCAL_SRC_FILES := $(shell find $(LOCAL_PATH)/recovery/root -type f)
  include $(BUILD_PREBUILT)
endif
