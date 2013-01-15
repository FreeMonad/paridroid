LOCAL_PATH := $(call my-dir)	

include $(CLEAR_VARS)
LOCAL_MODULE := pari
LOCAL_SRC_FILES := pari/lib/libpari.so
LOCAL_EXPORT_C_INCLUDES := pari/include
include $(PREBUILT_SHARED_LIBRARY)
