#include <jni.h>
#include <string.h>
#include <stdlib.h>
#include "libpostal.h"

JNIEXPORT jboolean JNICALL
Java_com_libpostal_LibPostal_setup(JNIEnv *env, jclass cls) {
    return libpostal_setup() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_com_libpostal_LibPostal_setupDatadir(JNIEnv *env, jclass cls, jstring datadir) {
    const char *datadir_str = (*env)->GetStringUTFChars(env, datadir, NULL);
    if (datadir_str == NULL) {
        return JNI_FALSE;
    }
    
    jboolean result = libpostal_setup_datadir((char *)datadir_str) ? JNI_TRUE : JNI_FALSE;
    (*env)->ReleaseStringUTFChars(env, datadir, datadir_str);
    return result;
}

JNIEXPORT void JNICALL
Java_com_libpostal_LibPostal_teardown(JNIEnv *env, jclass cls) {
    libpostal_teardown();
}

JNIEXPORT jboolean JNICALL
Java_com_libpostal_LibPostal_setupParser(JNIEnv *env, jclass cls) {
    return libpostal_setup_parser() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_com_libpostal_LibPostal_setupParserDatadir(JNIEnv *env, jclass cls, jstring datadir) {
    const char *datadir_str = (*env)->GetStringUTFChars(env, datadir, NULL);
    if (datadir_str == NULL) {
        return JNI_FALSE;
    }
    
    jboolean result = libpostal_setup_parser_datadir((char *)datadir_str) ? JNI_TRUE : JNI_FALSE;
    (*env)->ReleaseStringUTFChars(env, datadir, datadir_str);
    return result;
}

JNIEXPORT void JNICALL
Java_com_libpostal_LibPostal_teardownParser(JNIEnv *env, jclass cls) {
    libpostal_teardown_parser();
}

JNIEXPORT jobject JNICALL
Java_com_libpostal_LibPostal_parseAddress(JNIEnv *env, jclass cls, jstring address, jstring language, jstring country) {
    const char *address_str = (*env)->GetStringUTFChars(env, address, NULL);
    if (address_str == NULL) {
        return NULL;
    }

    libpostal_address_parser_options_t options = libpostal_get_address_parser_default_options();
    
    const char *language_str = NULL;
    const char *country_str = NULL;
    
    if (language != NULL) {
        language_str = (*env)->GetStringUTFChars(env, language, NULL);
        options.language = (char *)language_str;
    }
    
    if (country != NULL) {
        country_str = (*env)->GetStringUTFChars(env, country, NULL);
        options.country = (char *)country_str;
    }

    libpostal_address_parser_response_t *parsed = libpostal_parse_address((char *)address_str, options);
    
    jobject result = NULL;
    
    if (parsed != NULL) {
        // Find AddressParserResponse class
        jclass response_class = (*env)->FindClass(env, "com/libpostal/AddressParserResponse");
        if (response_class == NULL) {
            libpostal_address_parser_response_destroy(parsed);
            goto cleanup;
        }
        
        // Get constructor
        jmethodID constructor = (*env)->GetMethodID(env, response_class, "<init>", "()V");
        if (constructor == NULL) {
            libpostal_address_parser_response_destroy(parsed);
            goto cleanup;
        }
        
        // Create response object
        result = (*env)->NewObject(env, response_class, constructor);
        if (result == NULL) {
            libpostal_address_parser_response_destroy(parsed);
            goto cleanup;
        }
        
        // Get field IDs
        jfieldID components_field = (*env)->GetFieldID(env, response_class, "components", "[Ljava/lang/String;");
        jfieldID labels_field = (*env)->GetFieldID(env, response_class, "labels", "[Ljava/lang/String;");
        
        if (components_field == NULL || labels_field == NULL) {
            libpostal_address_parser_response_destroy(parsed);
            goto cleanup;
        }
        
        // Create string arrays
        jobjectArray components_array = (*env)->NewObjectArray(env, parsed->num_components, 
            (*env)->FindClass(env, "java/lang/String"), NULL);
        jobjectArray labels_array = (*env)->NewObjectArray(env, parsed->num_components, 
            (*env)->FindClass(env, "java/lang/String"), NULL);
        
        if (components_array == NULL || labels_array == NULL) {
            libpostal_address_parser_response_destroy(parsed);
            goto cleanup;
        }
        
        // Fill arrays
        for (size_t i = 0; i < parsed->num_components; i++) {
            jstring component = (*env)->NewStringUTF(env, parsed->components[i]);
            jstring label = (*env)->NewStringUTF(env, parsed->labels[i]);
            
            if (component == NULL || label == NULL) {
                libpostal_address_parser_response_destroy(parsed);
                goto cleanup;
            }
            
            (*env)->SetObjectArrayElement(env, components_array, i, component);
            (*env)->SetObjectArrayElement(env, labels_array, i, label);
            
            (*env)->DeleteLocalRef(env, component);
            (*env)->DeleteLocalRef(env, label);
        }
        
        // Set fields
        (*env)->SetObjectField(env, result, components_field, components_array);
        (*env)->SetObjectField(env, result, labels_field, labels_array);
        
        (*env)->DeleteLocalRef(env, components_array);
        (*env)->DeleteLocalRef(env, labels_array);
        (*env)->DeleteLocalRef(env, response_class);
        
        libpostal_address_parser_response_destroy(parsed);
    }

cleanup:
    (*env)->ReleaseStringUTFChars(env, address, address_str);
    if (language_str != NULL) {
        (*env)->ReleaseStringUTFChars(env, language, language_str);
    }
    if (country_str != NULL) {
        (*env)->ReleaseStringUTFChars(env, country, country_str);
    }
    
    return result;
}

JNIEXPORT jobjectArray JNICALL
Java_com_libpostal_LibPostal_expandAddress(JNIEnv *env, jclass cls, jstring address, jobject options) {
    const char *address_str = (*env)->GetStringUTFChars(env, address, NULL);
    if (address_str == NULL) {
        return NULL;
    }

    libpostal_normalize_options_t normalize_options = libpostal_get_default_options();
    
    // TODO: Parse options object if needed
    
    size_t num_expansions = 0;
    char **expansions = libpostal_expand_address((char *)address_str, normalize_options, &num_expansions);
    
    jobjectArray result = NULL;
    
    if (expansions != NULL) {
        result = (*env)->NewObjectArray(env, num_expansions, 
            (*env)->FindClass(env, "java/lang/String"), NULL);
        
        if (result != NULL) {
            for (size_t i = 0; i < num_expansions; i++) {
                jstring expansion = (*env)->NewStringUTF(env, expansions[i]);
                if (expansion == NULL) {
                    libpostal_expansion_array_destroy(expansions, num_expansions);
                    (*env)->ReleaseStringUTFChars(env, address, address_str);
                    return NULL;
                }
                (*env)->SetObjectArrayElement(env, result, i, expansion);
                (*env)->DeleteLocalRef(env, expansion);
            }
        }
        
        libpostal_expansion_array_destroy(expansions, num_expansions);
    }
    
    (*env)->ReleaseStringUTFChars(env, address, address_str);
    return result;
}
