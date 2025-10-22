public enum TypeCode: String, Sendable {
    case void = "V"

    /// JNI primitives
    case boolean = "Z"
    case byte = "B"
    case char = "C"
    case short = "S"
    case int = "I"
    case long = "J"
    case float = "F"
    case double = "D"
    case object = "L"

    /// Arrays of primitives
    case booleans = "[Z"
    case bytes = "[B"
    case chars = "[C"
    case shorts = "[S"
    case ints = "[I"
    case longs = "[J"
    case floats = "[F"
    case doubles = "[D"
    case objects = "[L"

    /// 2D Arrays of primitives
    case booleans2D = "[[Z"
    case bytes2D = "[[B"
    case chars2D = "[[C"
    case shorts2D = "[[S"
    case ints2D = "[[I"
    case longs2D = "[[J"
    case floats2D = "[[F"
    case doubles2D = "[[D"
    case objects2D = "[[L"
}