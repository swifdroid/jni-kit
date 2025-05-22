//
//  Bool+jboolean.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android

extension Bool {
    var jboolean: jboolean {
        self ? UInt8(JNI_TRUE) : UInt8(JNI_FALSE)
    }
}

extension jboolean {
    var value: Bool { self == JNI_TRUE }
}
#endif