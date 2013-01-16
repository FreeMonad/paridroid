package org.freemonad.paridroid;

import android.util.Log;

class PariNative {

    public static final String MSG_TAG = "PariDroid::PariNative";

    static {
        try {
            Log.i(MSG_TAG, "Loading libpari.so");
            System.loadLibrary("pari");
        } catch (Exception ex) {
            Log.e(MSG_TAG, "Error: " + ex.getMessage());
        }
    }

    static {
        try {
            Log.i(MSG_TAG,"Loading libparidroid.so");
            System.loadLibrary("paridroid");
        } catch (Exception ex) {
            Log.e(MSG_TAG, "Error: " + ex.getMessage());
        }
    }

    /* JNI CALLBACK DECLARATIONS */

    /**
     * Declaration of JNI callback to paridroid_init().
     */
    public static native void paridroidInit();

    /**
     * Declaration of JNI callback to paridroid_eval().
     * @param cmd: The GP command to run.
     * @return Output from GP interpreter.
     */
    public static native String paridroidEval(String cmd);

    public static native int getHistSize();
}

