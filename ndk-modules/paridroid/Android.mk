LOCAL_PATH := $(call my-dir)
NDK_MODULE_PATH := $(NDK_MODULE_PATH):$(LOCAL_PATH)/..

include $(CLEAR_VARS)
LOCAL_MODULE := paridroid
LOCAL_LDLIBS := -llog
LOCAL_CFLAGS := -g
$(call import-module, pari)
LOCAL_SHARED_LIBRARIES := pari
include $(BUILD_SHARED_LIBRARY)
