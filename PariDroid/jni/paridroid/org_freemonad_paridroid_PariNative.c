/**
 *------------------------------------------------------
 * PariDroidActivity.c - JNI Callbacks from libparidroid.
 *------------------------------------------------------
 * Copyright (C) 2011, Charles Boyd
 *
 * This file is part of PariDroid.
 *
 * PariDroid is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * PariDroid is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdlib.h>
#include <string.h>
#include <jni.h>
#include "paridroid.h"
#include "org_freemonad_paridroid_PariNative.h"

void
Java_org_freemonad_paridroid_PariNative_paridroidInit(JNIEnv *jenv, jobject obj)
{
  paridroid_init();
}

jstring
Java_org_freemonad_paridroid_PariNative_paridroidEval(JNIEnv *jenv, jobject obj, jstring input)
{
  const jbyte *cmd;
  char *output;

  // Turn the jstring into a C string.
  cmd = (*jenv)->GetStringUTFChars(jenv, input, NULL);

  // Check if JVM has already thrown out of memory error.
  if (cmd == NULL) {
    LOGW("Returning NULL from Native:paridroidEval");
    return NULL;
  }
  
  // Evaluate the command.
  output = paridroid_eval(cmd);

  // Free the Java objects we no longer need.
  (*jenv)->ReleaseStringUTFChars(jenv, input, cmd);

  // We encode the native string into a jstring and return it.
  jstring result = (*jenv)->NewStringUTF(jenv,output);

  return result;
}

jint 
Java_org_freemonad_paridroid_PariNative_getHistSize (JNIEnv *env, jclass obj)
{
  return paridroid_nb_hist();
}
