//
//  JMethodId.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#endif

public struct JMethodId: @unchecked Sendable {
    #if os(Android)
    public let id: jmethodID
    
    public init(_ id: jmethodID) {
        self.id = id
    }

    /// Convenient overload for optional `id`
    public init?(_ id: jmethodID?) {
        guard let id else { return nil }
        self.id = id
    }
    #endif
}