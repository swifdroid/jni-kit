//
//  String+CString.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if os(Android)
import Android
#else
#if canImport(Glibc)
import Glibc
#endif
#endif

extension String {
    public var cString: RetainedCString {
        RetainedCString(self)
    }
}

/// A C-String wrapper like NSString, it creates a copy of String and retains its pointer.
public final class RetainedCString {
    private var rawPointer: UnsafeMutablePointer<CChar>?

    public init(_ string: String) {
        #if os(Android)
        guard let ptr = strdup(string) else {
            fatalError("💣 Failed to allocate retained C string.")
        }
        self.rawPointer = ptr
        #endif
    }

    /// Accessor for the C string. Returns `nil` if memory is already freed.
    public var pointer: UnsafePointer<CChar>? {
        guard let ptr = rawPointer else {
            return nil
        }
        return UnsafePointer(ptr)
    }

    /// Frees the allocated C string if it hasn’t been freed already.
    public func free() {
        if let rawPointer {
            #if os(Android)
            Android.free(rawPointer)
            self.rawPointer = nil
            #endif
        }
    }

    deinit {
        free()
    }
}
