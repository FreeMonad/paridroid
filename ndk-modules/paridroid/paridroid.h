#include <string.h>
#include <strings.h>
#include <android/log.h>

#ifndef _PARIDROID_H
#define _PARIDROID_H

#define LOGV(...) __android_log_print(ANDROID_LOG_VERBOSE, "libparidroid", __VA_ARGS__)

#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "libparidroid", __VA_ARGS__)

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "libparidroid",  __VA_ARGS__)

#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, "libparidroid", __VA_ARGS__)

#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "libparidroid", __VA_ARGS__)

void paridroid_init(void);

char *paridroid_eval(const char *in);

void paridroid_close(void);

#endif /*_PARIDROID_H */
