import Android
import Logging
import FoundationEssentials

/// A lightweight wrapper for a raw `jobject`, allowing type-safe conversions and introspection.
///
/// Use `JObjectBox` when you have an opaque `jobject` pointer (e.g., from callbacks or native code)
/// and want to convert it into a proper `JObject` using runtime reflection.
public final class JObjectBox: @unchecked Sendable {
    /// The raw JNI object reference (local or global).
    public let ref: jobject
    let vm: JVM

    /// Initialize a box from a `jobject` reference.
    /// - Parameter object: A valid JNI object pointer.
    public init?(_ localObject: jobject, env: JEnv) {
        guard
            let globalRef = env.newGlobalRef(localObject)
        else {
            #if DEBUG
            Logger.debug("💣 JObjectBox: newGlobalRef returned nil")
            #endif
            return nil
        }
        self.ref = globalRef
        self.vm = JVM(env.env)
    }

    deinit {
        vm.attachCurrentThread()?.deleteGlobalRef(ref)
    }
}

extension jobject {
    /// Wrap this `jobject` in a `JObjectBox` for conversion or inspection.
    /// - Returns: A `JObjectBox` containing this reference.
    public func box(_ env: JEnv) -> JObjectBox? {
        JObjectBox(self, env: env)
    }
}

extension JObjectBox {
    /// Convert the boxed `jobject` into a fully typed `JObject` by inspecting its runtime class.
    ///
    /// This method calls `GetObjectClass` and then uses reflection to invoke `getName()`,
    /// obtaining the full class name of the object.
    ///
    /// - Returns: A `JObject` with resolved `JClass`, or `nil` if reflection fails.
    public func object() -> JObject? {
        #if DEBUG
        Logger.trace("Wrapping jobject into JObject")
        #endif
        guard
            // Step 1: Attach thread and get env
            let env = vm.attachCurrentThread(),
            // Step 2: Get the class of the original object (e.g. MainActivity.class)
            let objectClass = env.env.pointee?.pointee.GetObjectClass?(env.env, self.ref),
            // Step 3: Get method ID for getClass()
            let getClassId = env.env.pointee?.pointee.GetMethodID?(
                env.env,
                objectClass,
                "getClass",
                "()Ljava/lang/Class;"
            ),
            // Step 4: Call getClass() to get a java.lang.Class object
            let classObject = env.env.pointee?.pointee.CallObjectMethodA?(
                env.env,
                self.ref,
                getClassId,
                nil
            ),
            // Step 5: Get the class of java.lang.Class (i.e., java/lang/Class)
            let classClass = env.env.pointee?.pointee.GetObjectClass?(env.env, classObject),
            // Step 6: Get method ID for getName()
            let getNameId = env.env.pointee?.pointee.GetMethodID?(
                env.env,
                classClass,
                "getName",
                "()Ljava/lang/String;"
            ),
            // Step 7: Call getName() on the classObject to get class name
            let nameObj = env.env.pointee?.pointee.CallObjectMethodA?(
                env.env,
                classObject,
                getNameId,
                nil
            ),
            let globalNameObj = env.newGlobalRef(nameObj),
            // Step 9: Convert the jstring name into a Swift string
            let javaString = JString(from: globalNameObj),
            let name = javaString.toSwiftString()
        else {
            #if DEBUG
            Logger.debug("💣 Failed wrapping jobject into JObject")
            #endif
            return nil
        }
        // Step 10: Build a slash-separated class name from dot-separated
        let className = JClassName(stringLiteral: name.components(separatedBy: ".").joined(separator: "/"))
        #if DEBUG
        Logger.trace("Wrapped jobject into JObject \"\(className.fullName)\"")
        #endif
        return JObject(self.ref, .init(objectClass, className))
    }
}