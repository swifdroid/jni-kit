//
//  JFieldId.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#endif

public struct JFieldId: @unchecked Sendable {
    #if os(Android)
    public let id: jfieldID
    
    public init(_ id: jfieldID) {
        self.id = id
    }

    /// Convenient overload for optional `id`
    public init?(_ id: jfieldID?) {
        guard let id else { return nil }
        self.id = id
    }
    #endif
}