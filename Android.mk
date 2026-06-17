LOCAL_PATH := $(call my-dir)

# Apenas inclua subdiretórios se eles tiverem arquivos Android.mk próprios
# Não tente copiar arquivos manualmente com BUILD_PREBUILT aqui
ifeq ($(TARGET_DEVICE),frost)
  include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
