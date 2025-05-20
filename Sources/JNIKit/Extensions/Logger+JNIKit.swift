import Logging

extension Logger {
    // MARK: - Trace Level (Android Log.v)

    /// Logs a verbose (trace-level) message using Android's `Log.v`.
    ///
    /// Use this for detailed diagnostic messages that are useful during development but
    /// too verbose for production. This maps to Android’s `Log.v(tag, message)` internally.
    ///
    /// The log will only be emitted if the current `logLevel` is `.trace` or lower.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - metadata: Optional metadata to attach to this specific message.
    ///   - source: Optional string identifying the source (e.g., module or subsystem).
    ///   - file: The file name where this log call originates (default: `#fileID`).
    ///   - function: The function name where this log call originates (default: `#function`).
    ///   - line: The line number where this log call originates (default: `#line`).
    @inlinable
    public static func trace(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .trace,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a verbose (trace-level) message using Android's `Log.v`.
    ///
    /// This overload omits the `source` field, automatically assigning the current module.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - metadata: Optional metadata.
    ///   - file: File where the log call originates.
    ///   - function: Function name where the log call originates.
    ///   - line: Line number of the log statement.
    @inlinable
    public static func trace(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.trace(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }

    // MARK: - Debug Level (Android Log.d)

    /// Logs a debug-level message using Android's `Log.d`.
    ///
    /// Use this for debugging output that’s useful during development or testing. It is
    /// typically filtered out in production.
    ///
    /// - Parameters follow same description pattern as above.
    @inlinable
    public static func debug(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .debug,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a debug-level message using Android's `Log.d` without explicitly passing `source`.
    @inlinable
    public static func debug(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.debug(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }

    // MARK: - Info Level (Android Log.i)

    /// Logs an informational message using Android's `Log.i`.
    ///
    /// This level is appropriate for general messages that highlight the progress of the app.
    @inlinable
    public static func info(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .info,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs an informational message using Android's `Log.i` (overload without `source`).
    @inlinable
    public static func info(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.info(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }

    // MARK: - Notice Level (Android Log.i)

    /// Logs a notice-level message using Android's `Log.i`.
    ///
    /// Slightly more significant than `.info`, often used for lifecycle events or configuration.
    @inlinable
    public static func notice(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .notice,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a notice-level message using Android's `Log.i` (overload without `source`).
    @inlinable
    public static func notice(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.notice(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }

    // MARK: - Warning Level (Android Log.w)

    /// Logs a warning using Android's `Log.w`.
    ///
    /// Indicates a non-critical issue that may require attention.
    @inlinable
    public static func warning(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .warning,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a warning using Android's `Log.w` (overload without `source`).
    @inlinable
    public static func warning(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.warning(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }

    // MARK: - Error Level (Android Log.e)

    /// Logs an error using Android's `Log.e`.
    ///
    /// Use this for recoverable failures or significant malfunctions.
    @inlinable
    public static func error(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .error,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs an error using Android's `Log.e` (overload without `source`).
    @inlinable
    public static func error(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.error(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }

    // MARK: - Critical Level (Android Log.wtf / Log.f)

    /// Logs a critical error using Android's `Log.wtf` or system-equivalent fallback.
    ///
    /// Use for unrecoverable errors that represent application-level failure.
    /// These logs are always emitted regardless of the current log level.
    @inlinable
    public static func critical(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.log(
            level: .critical,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a critical error using Android's `Log.wtf` (overload without `source`).
    @inlinable
    public static func critical(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        JNIKit.logger.critical(message(), metadata: metadata(), source: nil, file: file, function: function, line: line)
    }
}
