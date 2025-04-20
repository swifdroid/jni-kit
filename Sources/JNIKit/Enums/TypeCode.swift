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
}