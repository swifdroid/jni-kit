//
//  JEnvironment.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android

/// A safe and ergonomic wrapper around `JNIEnv*` for use in Swift 6.1+
///
/// This wrapper hides unsafe pointer access and provides convenience methods for
/// working with Java classes, methods, fields, strings, and objects.
public struct JNI: @unchecked Sendable {
    /// The raw JNI environment pointer (thread-local)
    public let env: UnsafeMutablePointer<JNIEnv?>

    public init(_ env: UnsafeMutablePointer<JNIEnv?>) {
        self.env = env
    }

    public init?(_ env: UnsafeMutablePointer<JNIEnv?>?) {
        guard let env else { return nil }
        self.env = env
    }
}

        }
        group.wait()
        guard let classRef = _classReference else { return nil }
        return .init(classRef)
    }
    
    public func findClass(_ cClassPath: UnsafePointer<Int8>) -> jclass? {
        pointer.pointee?.pointee.FindClass(pointer, cClassPath)
    }
    
    public func getObjectClass(_ object: jobject) -> jclass? {
        pointer.pointee?.pointee.GetObjectClass(pointer, object)
    }
    
    public func newGlobalRef(_ object: jobject) -> jobject? {
        pointer.pointee?.pointee.NewGlobalRef(pointer, object)
    }
    
    public func newWeakGlobalRef(_ object: jobject) -> jobject? {
        pointer.pointee?.pointee.NewWeakGlobalRef(pointer, object)
    }
    
    public func isSameObject(_ obj1: jobject, _ obj2: jobject) -> Bool {
        guard let jb = pointer.pointee?.pointee.IsSameObject(pointer, obj1, obj2) else { return false }
        return jb == 1
    }
}
