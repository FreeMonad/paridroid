LOCAL_PATH := $(call my-dir)
NDK_MODULE_PATH := $(NDK_MODULE_PATH):$(LOCAL_PATH)/../../ndk-modules

include $(CLEAR_VARS)
LOCAL_MODULE := paridroid
LOCAL_SRC_FILES := $(LOCAL_PATH)/paridroid.c $(LOCAL_PATH)/org_freemonad_paridroid_PariNative.c
LOCAL_LDLIBS := -llog
LOCAL_CFLAGS := -g
$(call import-module, prebuilt/pari)
LOCAL_SHARED_LIBRARIES := pari_shared
include $(BUILD_SHARED_LIBRARY)
