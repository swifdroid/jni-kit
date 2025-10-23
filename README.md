<p align="center">
<img src="https://avatars.githubusercontent.com/u/87046691?s=200&v=4">
</p>

**JNIKit** is a foundation for convenient Swift-JNI development.

## Installation

Add it to the `Package.swift` file of your project:
```swift
// package dependencies
.package(url: "https://github.com/swifdroid/jni-kit.git", from: "2.10.0")

// target dependencies
.product(name: "JNIKit", package: "jni-kit")
```
> [!NOTE]
> The most convenient way to start developing your Swift-JNI code is via [Swift Stream IDE](https://swift.stream) 
> using templates it provides in a fully preconfigured development environment.

## Preambula

Let's talk about declaring JNI methods on the Swift side with `@_cdecl`. 

> [!IMPORTANT]
> `@_cdecl` naming convention is important as it follows JNI naming pattern `Java_<package>_<class>_<method>`, where:  
> - `<package>` is the fully qualified package name with underscores instead of dots  
> - `<class>` is the class name
> - `<method>` is the method name

Let's say you have a package `com.mylib.somecode` which contains `AwesomeCode` class which contains exported `hello` method.  
`@_cdecl` for it will be:
```swift
@_cdecl("Java_com_mylib_somecode_AwesomeCode_hello")
```

Method arguments vary depending on your class and method declaration.

**The first** argument is required and is always a pointer to the JNI environment, which is used to interact with the JVM.

```swift
envPointer: UnsafeMutablePointer<JNIEnv?>
```

**The second** argument is required and depends on whether the method is static or not.

So it could be
```swift
thizRef: jobject
```
if the method is **instance-based (non-static)**, in which case it will pass the instance from which it was called.

Or it could be
```swift
clazzRef: jobject
```
if method was `static` so it will pass just a reference to the Java class.

**The next** arguments are optional and directly represent the arguments declared in the Java/Kotlin method.

**The return** type can be empty (`void`) or can return a value (even an optional one).

The method can't be marked `async`, as it is not supported by `@_cdecl`. However, it is still possible to run asynchronous code in Swift if the original Java method was running on a **non-UI** thread.

JNI types, how they represented in Swift:

| JNI      | Swift  |
|----------|--------|
| jbyte    | Int8   |
| jshort   | Int16  |
| jint     | Int32  |
| jlong    | Int64  |
| jboolean | Bool   |
| jfloat   | Float  |
| jdouble  | Double |
| jchar    | UInt16 |

Any other Swift types are `jobject`.  
Also `jclass`, `jstring`, and `jarray` are typealiases for `jobject`.

> [!NOTE]
> Wrapping up: first two arguments are required and passed into Swift automatically by JVM-JNI mechanism, while third and subsequent arguments are actually arguments from your Java/Kotlin method.

## The beginning

Required imports
```swift
import JNIKit
import Android
```

Your first task is to initialize the JVM connection.

For that, you can declare a JNI initialization method like this:

```swift
@_cdecl("Java_com_mylib_mypackage_MyClass_initialize")
public func initialize(
    // pointer to the JNI environment
    // which is used to interact with the JVM
    envPointer: UnsafeMutablePointer<JNIEnv?>,
    // reference to the Java class
    // or could be `thizRef` for the call from the instance
    clazzRef: jobject,
    // optional, but recommended if you don't have a `thizRef`
    callerRef: jobject
) {
    // Initialize JVM
    let jvm = envPointer.jvm()
    JNIKit.shared.initialize(with: jvm)
}
```
At this point, your JNI connection is ready to use from the Swift side.

But I also highly recommend caching the class loader instance by taking it from the `thizRef` or `callerRef` objects:
```swift
// Access current environment
let localEnv = JEnv(envPointer)

// Convert caller's local ref into global ref
let callerBox = callerRef.box(localEnv)

// Defer block to clean up local references
defer {
    // Releases local ref to caller object
    localEnv.deleteLocalRef(callerRef)
}

// Initialize `JObject` from boxed global reference to the caller object
guard let callerObject = callerBox?.object() else { return }

// Cache the class loader from the caller object
// It is important for loading non-system classes later
// e.g. your own Java/Kotlin classes
if let classLoader = callerObject.getClassLoader(localEnv) {
    JNICache.shared.setClassLoader(classLoader)
    logger.info("🚀 class loader cached successfully")
}
```

Why do you need the class loader instance? Because without it, JNIKit will use the system-wide class loader, which can't load dynamically added classes like those from your app or your app's Gradle dependencies.  
So, it is a really important step.

## Cache

When working with JNI, it is important to minimize roundtrips to retrieve the same resources repeatedly. The `JNICache` implementation handles this by automatically storing `jclass` instances (by name), methodIDs, and fieldIDs for classes you have already used. You don't need to do anything for this; it caches these things automatically under the hood.

## Class

Loading a class is the first thing you will face.

There are a few ways to load it.

#### Via `env`

```swift
let env = JEnv.current()!
let clazz = env.findClass("com/mylib/mypackage/MyClass")
```
This way you will use the system's class loader, which will fail loading your dynamically loaded class. It should be used only for fundamental classes like `java/lang/Object`.

#### Via `classLoader`

The goal is to retrieve the application's class loader, which has access to dynamically loaded classes.

In pure Java you could retrieve a class loader from any `jobject`, as was shown above in the initialize method.

In Android the class loader is available in `ApplicationContext` or `ActivityContext`, as well as in any `jobject` of course, but there is a shorter convenience getter like `context.getClassLoader()`.

The usage is as simple as
```swift
let clazz = classLoader.loadClass("com/mylib/mypackage/MyClass")
```

#### Via `cached` instance

The preferred way is to use a convenience `JClass` method:

```swift
let clazz = JClass.load("com/mylib/mypackage/MyClass")
```
This way it tries to get it first from cache, then from the cached class loader, and if there is no cached class loader, then from the system's class loader.

##### Class names

As you can see above, the class name is represented as a `String`, but actually it is not. The `JClassName` object contains the class name in all possible forms: dotted, slashed, and even just its pure name.

You can predefine classnames as constants in the code for easy reuse and typo safety:
```swift
let class1 = JClassName("com/mylib/mypackage/MyClass1")
let class2 = JClassName("com/mylib/mypackage/MyClass2")
```
and then pass it like this:
```swift
JClass.load(class1)
```
or even put it into a `JClassName` extension:
```swift
extension JClassName {
    static let class1 = JClassName("com/mylib/mypackage/MyClass1")
    static let class2 = JClassName("com/mylib/mypackage/MyClass2")
}
```
and then use it anywhere like this:
```swift
JClass.load(.class1)
```

## Environment

Environment is the real bridge for any JNI call which in JNIKit's implementation is hidden under the hood but can also be used directly if needed.

The environment pointer is wrapped into convenient `JEnv` object.

Retrieve it this way:
```swift
let env = JEnv.current()
```

> [!IMPORTANT]
> Each instance works only in the thread where it was retrieved, so call `JEnv.current()` again if you switched thread or moved into `Task {}`

The possibilities of `JEnv` are a huge topic to describe in detail. I would say if you know what you want from it you will get it.

Let's describe it in short, what it provides:
- creating/deleting object references
- converting local ref into global ref
- finding and definig classes
- throwing and handling exceptions
- objects creation, allocation, comparison
- looking up methods and fields of object
- calling object instance methods
- calling class static methods
- getting and setting object fields
- strings and byte buffers
- etc.

All its methods are ergonomically wrapped for easy use with Swift types and convenience types like `JClass`, `JClassName`, `JObject`, `JMethodId`, `JFieldId`, 

### How to create a new object

JNIKit provides the `JObject` class, which holds a reference to a Java object.

#### Construct JObject with no arguments

Convenient way with `clazz`:
```swift
guard
    let clazz = JClass.load("com/mylib/mypackage/MyClass"),
    let object = clazz.newObject()
else { return }
```
More explicit way with `env`:
```swift
guard
    let env = JEnv.current(),
    let clazz = JClass.load("com/mylib/mypackage/MyClass"),
    let methodId = clazz.methodId(
        env: env,
        name: "<init>",
        signature: .returning(.void)
    ),
    let object = env.newObject(
        clazz: clazz,
        constructor: methodId
    )
else { return }
```

#### Construct JObject with arguments

Arguments have to be listed in both `methodId` and `newObject` in case of creating with `env`.

Let's assume a class constructor expects `jint`, `jfloat`, and `jobject` (which is `java/lang/String`).

Convenient way with `clazz`:
```swift
let object = clazz.newObject(
    123,
    1.23,
    "Hello" // or "Hello".wrap().signedAsString()
)
```

Explicit way with `env`:
```swift
let methodId = clazz.methodId(
    env: env,
    name: "<init>",
    signature: .init(
        .int,
        .float,
        .object("java/lang/String"),
        returning: .void // optional, .void by default
    )
)
let object = env.newObject(
    clazz: clazz,
    constructor: methodId,
    args: [
        123, // Int32 -> jint
        1.23, // Float -> jfloat
        "Hello".wrap()!.object // JObject -> jstring
    ]
)
```

The constructed object is now a `JObject` that holds a global reference to the instance and a global reference to its class. Keep this object for as long as you need it.

> [!NOTE]
> **When `JObject` is deinitialized, its underlying `jobject` reference is released automatically.**

> [!WARNING]
> Do not delete the underlying `jobject` reference manually, and do not use `jobject` from `JObject` anywhere outside.

### How to call an instance method

First of all, you need to know that the method call name depends on what type your method returns:

| Name              | Return type |
|-------------------|-------------|
| callObjectMethod  | JObject     |
| callBooleanMethod | Bool        |
| callByteMethod    | Int8        |
| callCharMethod    | UInt16      |
| callShortMethod   | Int16       |
| callIntMethod     | Int32       |
| callLongMethod    | Int64       |
| callFloatMethod   | Float       |
| callDoubleMethod  | Double      |
| callVoidMethod    | Void        |

Then you have a choice of wether to call it on `env` which is a bit more complex or call it on an `object` much shorter convenience way.

#### Calling method that returns an object

The way with `env`:
```swift
let env = JEnv.current()
let methodId = clazz.methodId(
    env: env,
    name: "getSomeObject",
    signature: .returning(.object("com/mylib/mypackage/SomeObject"))
)
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
let resultObject = env.callObjectMethod(
    object: object,
    methodId: methodId,
    returningClass: returningClazz
)
```

The way with `object`:
```swift
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
let resultObject = object.callObjectMethod(
    name: "getSomeObject",
    returningClass: returningClazz
)
```
So the difference is that you don't have to get the `methodID` yourself, as it is handled automatically under the hood. You also have the option to not pass the `env`.
> [!NOTE]
> The way with `object` is always shorter than with `env`.

#### Calling method that pass an object and returns nothing

The way with `env`:
```swift
let env = JEnv.current()
let methodId = clazz.methodId(
    env: env,
    name: "setSomeObject",
    signature: .init(
        .object("com/mylib/mypackage/SomeObject"),
        returning: .void // optional, .void by default
    )
)
let resultObject = env.callVoidMethod(
    object: object,
    methodId: methodId,
    args: [someObject.object]
)
```

The way with `object`:
```swift
object.callVoidMethod(
    name: "setSomeObject",
    args: someObject.signed(as: "com/mylib/mypackage/SomeObject")
    // or just someObject if you sure that automatic class is correct
)
```
It is even shorter than the getter.

#### Calling method that pass a string and returns nothing
The way with `object`:
```swift
object.callVoidMethod(
    name: "setString",
    args: "Hello" // or "Hello".wrap().signedAsString()
    // or "Hello".signedAsCharSequence()
)
// String is always signed as java/lang/String by default
```

### How to get a field value

The principle is the same, but you need a fieldID and can't pass any arguments. The signature is needed only if the field returns an object.

#### Getting an object

The way with `env`:
```swift
let env = JEnv.current()
let fieldId = object.clazz.fieldId(
    env: env,
    name: "someField",
    signature: .object("com/mylib/mypackage/SomeObject")
)
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
let resultObject = env.getObjectField(
    object: object,
    fieldId,
    clazz: returningClazz)
```

The way with `object`:
```swift
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
object.objectField(name: "someField", returningClass: returningClazz)
```

#### Getting an Int

The way with `env`:
```swift
let env = JEnv.current()
let fieldId = object.clazz.fieldId(
    env: env,
    name: "numberField",
    signature: .int
)
let resultInt = env.getIntField(object: object, fieldId)
```

The way with `clazz`:
```swift
object.intField(name: "numberField")
```

### How to set a field value

#### Setting an object

The way with `env`:
```swift
let env = JEnv.current()
let fieldId = object.clazz.fieldId(
    env: env,
    name: "someField",
    signature: .object("com/mylib/mypackage/SomeObject")
)
env.setObjectField(
    object: object,
    fieldId,
    object.signed(as: "com/mylib/mypackage/SomeObject")
)
```

The way with `object`:
```swift
object.objectField(
    name: "someField",
    object.signed(as: "com/mylib/mypackage/SomeObject")
)
```

#### Setting an Int

The way with `env`:
```swift
let env = JEnv.current()
let fieldId = object.clazz.fieldId(
    env: env,
    name: "numberField",
    signature: .int
)
let resultInt = env.setIntField(object: object, fieldId, 123)
```

The way with `object`:
```swift
object.intField(name: "numberField", 123)
```

### How to call a static method

#### Calling static method that returns an object

The way with `env`:
```swift
let env = JEnv.current()
let methodId = clazz.staticMethodId(
    name: "getSomeObject",
    signature: .returning(.object("com/mylib/mypackage/SomeObject"))
)
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
let resultObject = env.callStaticObjectMethod(
    clazz: clazz,
    methodId: methodId,
    returningClass: returningClazz
)
```

The way with `clazz`:
```swift
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
let resultObject = clazz.staticObjectMethod(
    name: "getSomeObject",
    returningClass: returningClazz
)
```

### How to get static field value

The way with `env`:
```swift
let env = JEnv.current()
let currentClazz = JClass.load("com/mylib/mypackage/MyClass")
let fieldId = currentClazz.fieldId(env: env, name: "someField", signature: .object("com/mylib/mypackage/SomeObject"))
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
let resultObject = env.getStaticObjectField(currentClazz, fieldId, clazz: returningClazz)
```

The way with `clazz`:
```swift
let currentClazz = JClass.load("com/mylib/mypackage/MyClass")
let returningClazz = JClass.load("com/mylib/mypackage/SomeObject")
currentClazz.staticFieldId(name: String, signature: JSignatureItem)
```

## Signature

We use it every time when discovering `methodID` or `fieldID`.

For methods it consists of two parts, the arguments types and the returning type:
```swift
// method with no arguments, returns Void
JSignature(returning: .void)
// method with no arguments, returns Int32
JSignature(returning: .int)
// method with no arguments, returns JObject
JSignature(returning: .object("com/mylib/mypackage/SomeObject"))
// method with no arguments, returns String
JSignature(returning: .object(JString.className))
// or
JSignature(returning: .object(JString.charSequenseClassName))
// method with Int32 argument, returns Void
JSignature(.int, returning: .void)
// method with JObject argument, returns Void
JSignature(.object("com/mylib/mypackage/SomeObject"), returning: .void)
// method with String argument, returns Void
JSignature(.object(JString.className), returning: .void)
// or
JSignature(.object(JString.charSequenseClassName), returning: .void)
```

For fields only returning type matters:
```swift
.int // for Int32
.float // for Float
// similar for the other primitive types
.object("com/mylib/mypackage/SomeObject") // for JObject
.object(JString.className) // for String
.object(JString.charSequenseClassName) // for String
```

## Signing objects

When passing a `JObject` as a method argument, you have two options for specifying its type signature

**Rely on automatic signature inference**, which uses the `JClass` associated with the `JObject`

Example with a generic `JObject`:
```swift
let object: JObject
object.callVoidMethod(name: "setView", args: object)
```
Example with a `JString`:
```swift
let string = "Hello"
object.callVoidMethod(name: "setView", args: string) // signed as java/lang/String by default
```

**Manually sign the object with a specific class** using the `signed(as:)` method

Example with a generic `JObject`:
```swift
let object: JObject
object.callVoidMethod(name: "setView", args: object.signed(as: "com/my/lib/SomeObject"))
```
Example with a `JString` (signed as a `CharSequence`):
```swift
let string = "Hello"
object.callVoidMethod(name: "setView", args: string.signedAsCharSequence())
```

## Wrapping Java/Kotlin class

A common use case is to wrap an existing Java/Kotlin class into a convenient Swift class.

The following example demonstrates this using `java/util/Date`:

<details>
    <summary>JDate.swift</summary>

```swift
// Example of Date object wrapper

/// A classic example of how to wrap a Java object into a Swift class.
/// 
/// Here we wrap `java.util.Date` object and provide some convenience methods.
public final class JDate: JObjectable, Sendable {
    /// The JNI class name
    public static let className: JClassName = "java/util/Date"

    /// JNI global reference object wrapper, it contains class metadata as well.
    public let object: JObject

    /// Initializer for when you already have a `JObject` reference.
    /// 
    /// This is useful when you receive a `Date` object from Java code.
    public init (_ object: JObject) {
        self.object = object
    }

    /// Allocates a `Date` object and initializes it so that it represents the time
    /// at which it was allocated, measured to the nearest millisecond.
    public init? () {
        #if os(Android)
        guard
            // Access current environment
            let env = JEnv.current(),
            // It finds the `java.util.Date` class and loads it directly or from the cache
            let clazz = JClass.load(Self.className),
            // Call to create a new instance of `java.util.Date` and get a global reference to it
            let global = clazz.newObject(env)
        else { return nil }
        // Store the object to access it from methods
        self.object = global
        #else
        // For non-Android platforms, return nil
        return nil
        #endif
    }

    /// Allocates a `Date` object and initializes it to represent the specified number of milliseconds since the standard base time known as "the epoch", namely January 1, 1970, 00:00:00 GMT.
    /// 
    /// - Parameter milliseconds: The number of milliseconds since January 1, 1970, 00:00:00 GMT.
    public init? (_ milliseconds: Int64) {
        #if os(Android)
        guard
            // Access current environment
            let env = JEnv.current(),
            // It finds the `java.util.Date` class and loads it directly or from the cache
            let clazz = JClass.load(Self.className),
            // Call to create a new instance of `java.util.Date`
            // with `milliseconds` parameter and get a global reference to it
            let global = clazz.newObject(env, args: milliseconds)
        else { return nil }
        // Store the object to access it from methods
        self.object = global
        #else
        // For non-Android platforms, return nil
        return nil
        #endif
    }

    /// Returns the day of the week represented by this date.
    public func day() -> Int32? {
        // Convenience call to `java.util.Date.getDay()`
        object.callIntMethod(name: "getDay")
    }

    /// Returns the hour represented by this Date object.
    public func hours() -> Int32? {
        // Convenience call to `java.util.Date.getHours()`
        object.callIntMethod(name: "getHours")
    }

    /// Returns the number of minutes past the hour represented by this date
    public func minutes() -> Int32? {
        // Convenience call to `java.util.Date.getMinutes()`
        object.callIntMethod(name: "getMinutes")
    }

    /// Returns the number of seconds past the minute represented by this date.
    public func seconds() -> Int32? {
        // Convenience call to `java.util.Date.getSeconds()`
        object.callIntMethod(name: "getSeconds")
    }

    /// Returns the number of milliseconds since January 1, 1970, 00:00:00 GMT for this date instance.
    public func time() -> Int32? {
        // Convenience call to `java.util.Date.getTime()`
        object.callIntMethod(name: "getTime")
    }

    /// Tests if this date is before the specified date.
    public func before(_ date: JDate) -> Bool {
        // Convenience call to `java.util.Date.before(Date date)`
        // which passes another `Date` object as a parameter
        // and returns a boolean result
        object.callBoolMethod(name: "before", args: date.object.signed(as: JDate.className)) ?? false
    }

    /// Tests if this date is after the specified date.
    public func after(_ date: JDate) -> Bool {
        // Convenience call to `java.util.Date.after(Date date)`
        // which passes another `Date` object as a parameter
        // and returns a boolean result
        object.callBoolMethod(name: "after", args: date.object.signed(as: JDate.className)) ?? false
    }

    /// Converts this java `Date` object to a Swift `Date`.
    public func date() -> Date? {
        // Get milliseconds since epoch using `getTime` method
        guard let time = time() else { return nil }
        // Convert milliseconds to seconds and create a Swift `Date` object
        return Date(timeIntervalSince1970: TimeInterval(time) / 1000.0)
    }
}
```
</details>

## Casting

There are two situations where you need to cast an object from one class to another.

1. **When you want to treat an existing object as an instance of another class** (usually a parent) to call a method or access a field.

This is done using the `cast(to:)` method of `JObject`. It creates a proxy `JObject` of the target class but retains the same underlying JNI reference:
```swift
let editText: EditText
let textView = editText.cast(to: TextView.className)
```

2. **When you need to pass an object to a method that expects a different class** (also usually a parent).

This is done using the `signed(as:)` method of `JObject`:
```swift
let customView: CustomView
object.callVoidMethod(name: "setView", args: customView.signed(as: View.className))
```

## Optionals and NULL

You may have Java/Kotlin methods that accept nullable arguments. 
For any `JObject`, you can pass Swift `nil`, which will be converted to JNI `NULL`:
```swift
let object1: JObject
let object2: JObject? // this could be nil
let object3: JObject
object.callVoidMethod(name: "setView", args: object1, object2, object3)
```

## Primitive type objects

Pure primitive types can be passed as method arguments directly:
```swift
let intValue: Int32 = 9.41
let floatValue: Float = 9.41
let doubleValue: Double = 9.41
object.callVoidMethod(name: "setValues", args: intValue, floatValue, doubleValue)
```
These values cannot be `nil` and are always represented in the JNI signature as primitives.

However, if the Java/Kotlin side expects full object types like `java.lang.Integer` or `java.lang.Long`, you need to use their Swift wrapper equivalents. 
Refer to the table below:
| Swift Type | Swift Wrapper               | Java Type           |
|------------|-----------------------------|---------------------|
| Int8       | JInt8 (JByte)               | java/lang/Byte      |
| Int16      | JInt16 (JShort)             | java/lang/Short     |
| Int32      | JInt32 (JInt, JInteger)     | java/lang/Integer   |
| Int64      | JInt64 (JLong)              | java/lang/Long      |
| Bool       | JBool                       | java/lang/Boolean   |
| Float      | JFloat                      | java/lang/Float     |
| Double     | JDouble                     | java/lang/Double    |
| UInt16     | JUInt16 (JChar, JCharacter) | java/lang/Character |

**Usage Example:**
```swift
let nilDoubleObject: JDouble? = nil
let doubleObject: JDouble? = 9.41
let double: Double = 9.41
object.callVoidMethod(name: "sendDouble", args: nilDoubleObject) // Object Double is NULL
object.callVoidMethod(name: "sendDouble", args: doubleObject) // Object Double is NOT NULL: 9.41
object.callVoidMethod(name: "sendDouble", args: double) // Primitive Double: 9.41
```
**Corresponding Kotlin Code**:
```kotlin
fun sendDouble(value: Double) {
    Log.d("CHECK", "Primitive Double: $value")
}
fun sendDouble(value: Double?) {
    if (value != null) {
        Log.d("CHECK", "Object Double is NOT NULL: $value")
    } else {
        Log.d("CHECK", "Object Double is NULL")
    }
}
```

## License

**MIT License**

Copyright (c) 2021 Mikhail Isaev

## Contribution

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

Don't forget to give the project a star! Thanks again!
