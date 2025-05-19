import Android

/// Extensions for `pthread_mutex_t` to provide a more Swift-friendly API for initialization,
/// locking, unlocking, and cleanup.
///
/// These utilities simplify the usage of POSIX mutexes in Swift code, particularly when
/// working with JNI or other concurrency-critical code in Android-native contexts.
extension pthread_mutex_t {
    
    /// Initializes the mutex with optional recursive behavior.
    ///
    /// - Parameter recursive: If `true`, initializes a recursive mutex (i.e., the same thread can lock it multiple times without deadlocking).
    ///
    /// Example usage:
    /// ```swift
    /// var mutex = pthread_mutex_t()
    /// mutex.activate(recursive: true)
    /// ```
    public mutating func activate(recursive: Bool = false) {
        if recursive {
            var attr = pthread_mutexattr_t()
            pthread_mutexattr_init(&attr)
            pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
            pthread_mutex_init(&self, &attr)
            pthread_mutexattr_destroy(&attr)
        } else {
            pthread_mutex_init(&self, nil)
        }
    }

    /// Destroys the mutex, releasing any associated system resources.
    ///
    /// This should be called when the mutex is no longer needed.
    ///
    /// Example:
    /// ```swift
    /// mutex.destroy()
    /// ```
    public mutating func destroy() {
        pthread_mutex_destroy(&self)
    }

    /// Locks the mutex, blocking the calling thread if the mutex is not available.
    ///
    /// For recursive mutexes, the same thread may acquire the lock multiple times.
    ///
    /// Example:
    /// ```swift
    /// mutex.lock()
    /// // critical section
    /// mutex.unlock()
    /// ```
    public mutating func lock() {
        pthread_mutex_lock(&self)
    }

    /// Unlocks the mutex, allowing other threads to acquire it.
    ///
    /// This should be called after a successful `lock()` or within a `defer` block.
    ///
    /// Example:
    /// ```swift
    /// mutex.lock()
    /// defer { mutex.unlock() }
    /// // critical section
    /// ```
    public mutating func unlock() {
        pthread_mutex_unlock(&self)
    }
}
