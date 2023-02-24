//
//  Helpers.h
//
//
//  Created by Vlad Gorlov on 04.12.20.
//

#ifndef File_h
#define File_h

#include "jni.h"

typedef struct {
    const signed char * _Nonnull data;
   unsigned int count;
} CData;

#ifdef __cplusplus
extern "C" {
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

void GetJNIEnv(JavaVM * _Nonnull vm, JNIEnv *_Nonnull *_Nonnull p_env);
void AttachCurrentThread(JavaVM * _Nullable  vm, JNIEnv *_Nullable * _Nullable  p_env);
void DetachCurrentThread(JavaVM * _Nullable  vm);
void GetJVM(JNIEnv * _Nullable  env, JavaVM *_Nullable * _Nullable  vm);
void CallVoidMethod(JNIEnv * _Nonnull env, jobject _Nonnull thisClass, const char* _Nonnull name, const char* _Nonnull sig);

int GetArrayLength(JNIEnv * _Nonnull env, jclass _Nonnull thisClass, jbyteArray _Nonnull bArray);
jbyte* _Nonnull GetByteArrayElements(JNIEnv * _Nonnull env, jclass _Nonnull thisClass, jbyteArray _Nonnull bArray);

jbyteArray _Nullable data_SwiftToJava(JNIEnv * _Nonnull env, CData * _Nonnull data);

#pragma clang diagnostic pop

#ifdef __cplusplus
}
#endif

#endif /* File_h */
