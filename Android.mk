LOCAL_PATH := $(call my-dir)

# Forçar a inclusão da pasta recovery/root
ifneq ($(wildcard $(LOCAL_PATH)/recovery/root),)
    # Aqui estamos declarando que o conteúdo de recovery/root faz parte do target 'recovery'
    include $(CLEAR_VARS)
    LOCAL_MODULE := recovery_ramdisk_files
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE_CLASS := RECOVERY_RESOURCES
    include $(BUILD_PHONY_PACKAGE)
endif

include $(call all-subdir-makefiles,$(LOCAL_PATH))
