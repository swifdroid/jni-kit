#if os(Android)
import Android
#endif
#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif
import FoundationEssentials

/// A lightweight wrapper for a raw `jobject`, allowing type-safe conversions and introspection.
///
/// Use `JObjectBox` when you have an opaque `jobject` pointer (e.g., from callbacks or native code)
/// and want to convert it into a proper `JObject` using runtime reflection.
public final class JObjectBox: @unchecked Sendable {
    #if os(Android)
    /// The raw JNI object reference (local or global).
    public let ref: jobject

    /// Initialize a box from a `jobject` reference.
    /// - Parameter object: A valid JNI object pointer.
    public init?(_ localObject: jobject, env: JEnv) {
        guard
            let globalRef = env.newGlobalRef(localObject)
        else {
            #if JNILOGS
            Logger.critical("💣 JObjectBox: newGlobalRef returned nil")
            #endif
            return nil
        }
        self.ref = globalRef
    }

    // deinit {
    //     Logger(label: "JObjectBox").critical("🧹🧹🧹 deleted global ref: \(ref)")
    //     vm.attachCurrentThread()?.deleteGlobalRef(ref)
    // }
    #else
    public init () {}
    #endif
}

#if os(Android)
extension jobject {
    /// Wrap this `jobject` in a `JObjectBox` for conversion or inspection.
    /// - Returns: A `JObjectBox` containing this reference.
    public func box(_ env: JEnv) -> JObjectBox? {
        JObjectBox(self, env: env)
    }
}
#endif

extension JObjectBox {
    /// Convert the boxed `jobject` into a fully typed `JObject` by inspecting its runtime class.
    ///
    /// This method calls `GetObjectClass` and then uses reflection to invoke `getName()`,
    /// obtaining the full class name of the object.
    ///
    /// - Returns: A `JObject` with resolved `JClass`, or `nil` if reflection fails.
    public func object() -> JObject? {
        #if os(Android)
        #if JNILOGS
        Logger.trace("JObjectBox.object 1")
        #endif
        // Step 1: Attach thread and get env
        guard let env = JEnv.current() else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 1.1 exit: 💣 Unable to get JEnv")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 2")
        #endif
        // Step 2: Get the class of the original object (e.g. MainActivity.class)
        guard let localObjectClass = env.env.pointee?.pointee.GetObjectClass?(env.env, self.ref) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 2.1 exit: 💣 Unable to get localObjectClass")
            #endif
            return nil
        }
        defer { env.deleteLocalRef(localObjectClass) }
        #if JNILOGS
        Logger.trace("JObjectBox.object 3")
        #endif
        guard let globalObjectClass = env.newGlobalRefPure(localObjectClass) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 3.1 exit: 💣 Unable to newGlobalRef for localObjectClass")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 4")
        #endif
        // Step 3: Get method ID for getClass()
        guard let getClassId = env.env.pointee?.pointee.GetMethodID?(
            env.env,
            globalObjectClass,
            "getClass",
            "()Ljava/lang/Class;"
        ) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 4.1 exit: 💣 Unable to getClassId")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 5")
        #endif
        // Step 4: Call getClass() to get a java.lang.Class object
        guard let classObject = env.env.pointee?.pointee.CallObjectMethodA?(
            env.env,
            self.ref,
            getClassId,
            nil
        ) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 5.1 exit: 💣 Unable to get classObject")
            #endif
            return nil
        }
        defer { env.deleteLocalRef(classObject) }
        #if JNILOGS
        Logger.trace("JObjectBox.object 6")
        #endif
        // Step 5: Get the class of java.lang.Class (i.e., java/lang/Class)
        guard let classClass = env.env.pointee?.pointee.GetObjectClass?(env.env, classObject) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 6.1 exit: 💣 Unable to get classClass")
            #endif
            return nil
        }
        defer { env.deleteLocalRef(classClass) }
        #if JNILOGS
        Logger.trace("JObjectBox.object 7")
        #endif
        // Step 6: Get method ID for getName()
        guard let getNameId = env.env.pointee?.pointee.GetMethodID?(
            env.env,
            classClass,
            "getName",
            "()Ljava/lang/String;"
        ) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 7.1 exit: 💣 Unable to getNameId")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 8")
        #endif
        // Step 7: Call getName() on the classObject to get class name
        guard let localNameObj = env.env.pointee?.pointee.CallObjectMethodA?(
            env.env,
            classObject,
            getNameId,
            nil
        ) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 8.1 exit: 💣 Unable to get localNameObj")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 9")
        #endif
        // Step 9: Convert the jstring name into a Swift string
        guard let javaString = JString(from: localNameObj) else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 9.1 exit: 💣 Unable to make javaString")
            #endif
            return nil
        }
        defer { env.deleteLocalRef(localNameObj) }
        #if JNILOGS
        Logger.trace("JObjectBox.object 10")
        #endif
        guard let name = javaString.string() else {
            #if JNILOGS
            Logger.critical("JObjectBox.object 10.1 exit: 💣 Unable to convert javaString into String")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 11")
        #endif
        // Step 10: Build a slash-separated class name from dot-separated
        let className = JClassName(stringLiteral: name.components(separatedBy: ".").joined(separator: "/"))
        #if JNILOGS
        Logger.trace("JObjectBox.object 12")
        #endif
        guard let refBox = self.ref.box(env) else {
            #if JNILOGS
            Logger.trace("JObjectBox.object 12.1 exit: 💣 Unable to wrap jobject into JObjectBox")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JObjectBox.object 13, wrapped jobject into JObjectBox \"\(className.fullName)\"")
        #endif
        return JObject(refBox, .init(globalObjectClass, className))
        #else
        return nil
        #endif
    }
}