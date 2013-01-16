LOCAL_PATH := $(call my-dir)

############################
# libpari.so
############################

include $(CLEAR_VARS)

LOCAL_MODULE := pari

LOCAL_SRC_FILES := pari/lib/libpari.so

include $(PREBUILT_SHARED_LIBRARY)

############################
# libparidroid.so
############################

include $(CLEAR_VARS)

LOCAL_MODULE := paridroid

LOCAL_C_INCLUDES := pari/include

LOCAL_LDLIBS := -llog

LOCAL_CFLAGS := -g

LOCAL_SRC_FILES := \
	paridroid/paridroid.c \
	paridroid/org_freemonad_paridroid_PariNative.c

LOCAL_SHARED_LIBRARIES := libpari

include $(BUILD_SHARED_LIBRARY)

# EOF
