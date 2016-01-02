footer: "Swift Sync and Async Error Handling" - Javier Soto. iOS Conf Singapore - October 2015
slidenumbers: true
autoscale: true
build-lists: true


# Swift Sync and Async Error Handling
### iOS Conf Singapore - October 2015

![inline](Images/swift-logo.png)

> -- @Javi

^ - My name is Javi, I'm an iOS Engineer at Twitter in San Francisco.
- We're going to talk about error handling. It's not a sexy topic, but it is very important, and it's often neglected. We're going to look into the traditional Obj-C error handling mechanisms, and how we can do a lot better in Swift.
- I gave a similar version of this talk in SF 6 months ago, right after Swift 2 was announced, and I hoped that by this time this content would be outdated. Unfortunately it still very much applies. Error handling in Swift 2 is still problematic, We'll see why, and the alternatives that we have.
- Disclaimer about opinions vs facts: I wanna share my views and hopefully you find them useful.

---

# Agenda

- Traditional Asynchronous Code
- Problems with Traditional Error Handling
- `Result` vs `throws`
- Modeling asynchronous computation: `Future`
- Making `Result` and `throws` play together

---

# [fit] Traditional asynchronous code

^ - Let's talk about the problem first.

---

## Traditional asynchronous code

```swift
struct User { let avatarURL: NSURL }
func requestUserInfo(userID: String, completion: (User?, NSError?) -> ())
func downloadImage(URL: NSURL, completion: (UIImage?, NSError?) -> ())

func loadAvatar(userID: String, completion: (UIImage?, NSError?) -> ()) {
    requestUserInfo(userID) { user, error in
        if let user = user {
            downloadImage(user.avatarURL) { avatar, error in
                if let avatar = avatar { completion(avatar, nil) }
                else { completion(nil, error!) }
            }
        } else { completion(nil, error!) }
    }
}
```

^ - We're used to this in Obj-C, but we can do better in Swift.
- Concatenating asynchronous work means that we need to check for error every step of the way. There surely has to be a better pattern.
- This grows to the right very quickly as soon as you start having to do more and more things.

---

## Traditional asynchronous code

![inline](Images/php-callback-hell.jpg)

^ - Let's avoid this.

---

## Traditional asynchronous code

```swift
func downloadImage(URL: NSURL, completion: (UIImage?, NSError?) -> ())
```

(.Some, .None)
(.None, .Some)
**(.Some, .Some)**
**(.None, .None)**

^ - Let's look at a problem with the type signatures.
- This tuple can hold 4 possibilities
- Not a Swift problem: Those question marks are always there implicitly in Obj-C!
- The last 2 cases mean both image and error, and neither image nor error.


---

**(.Some, .Some)**
**(.None, .None)**

![inline](Images/wat.jpg)

^ - I always like to remind people that computers never make mistakes: bugs occur when there's a difference between what we think we told the computer to do, and what we actually told the computer to do.
- If we don't have a way of properly expressing our intentions in code, bugs will pop up.
- I've seen code written in Swift that utilizes the exact same pattern for asynchronous APIs. We'll see a bit later my recommended approach.

---

## Error Handling

```swift
func downloadImage(URL: NSURL, completion: (UIImage?, NSError?) -> ())

downloadImage(url) { imageOrNil, errorOrNil in
    if error = errorOrNil {
        // What if image is also not nil??
    }
    else if image = imageOrNil {

    }
}
```

^ - Checking the error first is an anti-pattern in Cocoa.
- We couldn't do better in Obj-C, because any reference type can hold nil, but we can do better in Swift.

---

## Error Handling

```swift
var error: NSError?
let string = NSString(contentsOfFile:path encoding:NSUTF8Encoding error:&error)

if string == nil {
    // Oops:
    if error.code == NSFileReadNoSuchFileError {
        // ...
    }
    else if ...
}
```

^ - Now APIs like these are automatically converted to Swift 2's error handling mechanism. However it's just syntactic sugar, and they still have some of the same issues.
- NSError-based APIs don't give us any information at compile-time about the types of errors we may get.
- In this example: how do we know what domain and codes are possible? NSString's documentation doesn't mention.
- Checking the code without checking the domain is a very subtle bug that NSError doesn't prevent.
- This type of API also makes it possible to ignore errors.
- Robust software must take good care of errors, and ignoring them is a recipe for disaster.

---

![inline](Images/error-6.jpg)

^ - We don't spend as much time making our APIs easy to use outside of the happy path. Some of the buggiest codebases I've seen shared a common problem: they lacked error handling.
- We need proper abstractions that allow us to easily handle errors without adding complexity to our code if we want to make our programs correct outside of the happy paths.
- No surprise that we often see errors like these in the apps that we use.

---

![inline](Images/error-due-to-error.jpg)

---

![inline](Images/error-no-error.png)

---

![inline](Images/tweet_1.png) ![inline](Images/tweet_2.png)

---

## NSError Alternative

```swift
protocol ErrorType { }

enum UserInfoErrorDomain: ErrorType {
    case UserDoesNotExist
    case UserRequestFailure(reason: String)
    case NetworkRequestFailure(underlyingError: NSError)
}

extension NSError: ErrorType { }
```

^ - This `ErrorType` was introduced in ReactiveCocoa before Swift 2. I really like this pattern.
- Interestingly, Swift 2's stdlib introduced this very same protocol.
- We won't require the use of NSError: instead, we'll define a protocol, so that the clients can use anything as an error type.
- For example, here we have a domain definition, with a close set of error cases, which can also carry additional information, in this case, in the form of strings.

---
## NSError Alternative

```swift
enum NoError: ErrorType { }

let error = NoError(?)
```

^ - We can also define a "no error" type. For what?
- We can't create a NoError error, because we've declared it as an empty enum type.
- Can't create values of that type. This allows us to declare Futures that we know can't come back with errors.
- And this is ensured at compile-time: no need for unit tests!

---

## Result

```swift
enum Result<T, E: ErrorType> {
    case Success(T)
    case Failure(E)
}
```

`Result` by Rob Rix:
https://github.com/antitypical/Result

^ - `Result` is what makes the type-contract explicit: no more corner cases!
- Thanks to the user of `enum`, we know that a `Result` value can only hold \_either\_ a value, or an error.
- We restrict E to ErrorType.

---

## Swift's `throws`

---

## Swift's `throws`

```swift
func readFile(path: String) throws -> NSData
```

^ - This is the basic shape of a function that `throws` in Swift2.
- This syntax allows us to express that this function may fail.
- I'm not gonna explain all the details about how throws works, I wanna focus on the concepts here.
- This means that this function may either return NSData or "throw" an error.

---

## Swift's `throws`

```swift
func readFile(path: String) throws -> NSData
// throws... what exactly?
```

^ - The problem is: what sort of error can it return? We don't have a way to specify that.

---

## Swift's `throws`

```swift
func readFile(path: String) throws -> NSData
```

### Functionally equivalent to

```swift
func readFile(path: String) -> Result<NSData, ErrorType>
```

^ - Using `Result`, it would look like this. The `ErrorType` is simply the protocol, no specific implementation.

---

## Swift's `throws`

```swift
func readFile(path: String) throws -> NSData

do {
  let contents = try readFile("path/to/my/file")
}
catch(SomeTypeOfError) {
  // How can I know which errors I should match..?
}
catch {
  // catch-all block.
}
```

^ - So this has the same issues as NSError that we saw earlier.
- When Apple first released this, I was happy about one thing however: it forced us to consider the error case, and we could no longer say: "error:NULL"
- However, a later seed came with this new syntax:

---

## Swift's `throws`

```swift
func readFile(path: String) throws -> NSData

let contents: NSData? = try? readFile("path/to/my/file")
```

^ - While this may be useful in *some* cases where we truly don't care about the error, it's concerning because having a tool that's so *easy* to use, but which in most cases you shouldn't be using, encourages developers to do the wrong thing.

---

## Swift's `throws`

```swift
func readFile(path: String) -> Result<NSData, FileIOError>

let file = readFile("path/to/my/file")

switch file {
  case let .Succcess(value):
    // ...
  case let .Failure(error):
    // This `error` variable has type information!
}
```

^ - This is how we would use this API with Result, as opposed to throws.
- I'm not trying to say that Result is inherently better than Swift's throws mechanism.
- But it is important to realize the limitations of this new language feature.
- By the way, if you prefer the try / catch syntax from the previous slide, hold on until the end where I'm going to show how to take advantage of that with `Result` as well.

---

## Swift's `throws`

### *Hopefully in a future version of Swift ...*

```swift
func readFile(path: String) throws FileIOError -> NSData
```

^ - I was really hopeful during the summer that this would come, but it didn't. I really hope that it does!

---

## Error handling in Asynchronous APIs

^ - So now let's talk about the asynchronous case, which is always much more complicated.
- It's important to note that Swift2's new error handling feature is designed to work with synchronous APIs: methods that either return something, or send an error.

---

# `Future<T, E>`

^ - So what are futures? Futures are a great abstraction to allow us to deal with asynchrony much more easily.
- There are many libraries that accomplish this in different ways. You may already be familiar with this concept, but I want to talk about it a little bit.
- This pattern has been implemented millions of times in many languages. I hope that by looking at how to implement it, and compare it to what we're used to, we can gain a better understanding of this abstraction.
- We're going to see how we can come up with a very simple API that is going to simplify all of our asynchronous code.

---

## Futures

- Encapsulate a deferred computation.
- Treat values that incur a delay to be retrieved as if they were regular values.
- Allow us to treat errors as first class citizens.
- Easily composable.

^ - Futures encapsulate the work required to retrieve a value that incurs in some delay into a simple interface.
- Abstracting away the asynchrony, which allows us to simplify the way we describe the operations and transformations we want to apply to those values.

---

## Future

```swift
struct Future<T, E: ErrorType> {
    typealias ResultType = Result<T, E>
    typealias Completion = ResultType -> ()
    typealias AsyncOperation = Completion -> ()

    private let operation: AsyncOperation
}

```

^ - Defining some intermediate typealiases helps us understand the signatures of these closures.
- Operation is the closure that we can call when we want the Future to start performing the work required to retrieve the value.

---

## Future

```swift
struct Future<T, E: ErrorType> {
    init(operation: AsyncOperation) {
        self.operation = operation
    }

    func start(completion: Completion) {
        self.operation() { result in
            completion(result)
        }
    }
}
```

^ - The initializer allows us to create a Future with the operation closure.
- The start method is the main method of the public API: allows us to tell Future to do the work to retrieve the value asynchronously.

---

## [fit] `Future.map()`: transforming the computed value

^ - `Future` as is is not very useful. Let's see what APIs we can add that will let us operate with them.

---

## [fit] `Future.map()`: transforming the computed value

```swift
struct User { let avatarURL: NSURL }

func requestUserInfo(userID: String) -> Future<User, ErrorDomain>


func requestUserAvatarURL(userID: String) -> Future<NSURL, ErrorDomain> {
    return requestUserInfo(userID)
    .map { $0.avatarURL }
}
```

^ - If we have a function that can give us a future of a User, we can map it to get a function that will give you a Future of an URL for the avatar.

---

## [fit] `Future.map()`: transforming the computed value

```swift
struct Future<T, E: ErrorType> {
    func map<U>(f: T -> U) -> Future<U, E>
}
```

^ - This would be the type signature.

---

## map() in other types

```swift
struct Array<T> {
    func map<U>(f: T -> U) -> [U]
}

enum Optional<T> {
    func map<U>(f: T -> U) -> U?
}

struct Future<T, E: ErrorType> {
    func map<U>(f: T -> U) -> Future<U, E>
}
```

^ - It's no coincidence that the signature looks exactly the same as in all these other types.
- It allows you to apply a function that transforms T values into other values, when those values are enclosed within a context, whether it's an Array, or an Optional "box".

---

## [fit] `Future.map()`: transforming the computed value

```swift
func map<U>(f: T -> U) -> Future<U, E> {
    // Return a new Future w/ a new operation...
    return Future<U, E>(operation: { completion in

    })
}
```

^ - How would we implement it? It's easy.
- In fact, given the type signature, there's only one way to implement it.

---

## [fit] `Future.map()`: transforming the computed value

```swift
func map<U>(f: T -> U) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
        // Retrieve the value from self...
        self.start { result in

        }
    })
}
```

---

## [fit] `Future.map()`: transforming the computed value

```swift
func map<U>(f: T -> U) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
        self.start { result in
            // Consider .Success and .Failure...
            switch result {

            }
        }
    })
}
```

---

## [fit] `Future.map()`: transforming the computed value

```swift
case let .Success(value):
    // Call completion with the transformed value
    completion(Result.Success(f(value)))
```

---

## [fit] `Future.map()`: transforming the computed value

```swift
case let .Failure(error):
    // We didn't get a value: no transformation
    completion(Result.Failure(error))
```

^ - What we pass in the completion block is essentially the same as the value we're switching on.
- We have to construct a new Result because value is a Result<T, E>, and we need a Result<U, E>

---

## [fit] `Future.map()`: transforming the computed value

```swift
func map<U>(f: T -> U) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
        self.start { result in
            switch result {
                case let .Success(value):
                    completion(Result.Success(f(value)))
                case let .Failure(error):
                    completion(Result.Failure(error))
            }
        }
    })
}
```

^ - Putting it all together.

---

## [fit] `Future.andThen()`: concatenating async work

^ - What if what we want to do after getting the value from a future is to do something with it that also incurs in a delay?

---

## [fit] `Future.andThen()`: concatenating async work

```swift
func requestUserAvatarURL(userID: String) -> Future<NSURL, ErrorDomain>

func downloadImage(URL: NSURL) -> Future<UIImage, ErrorDomain>


func downloadUserAvatar(userID: String) -> Future<UIImage, ErrorDomain> {
    return requestUserAvatarURL(userID)
    .andThen(downloadImage)
}
```
^ - map() won't work because it requires that the function we pass returns a U value synchronously.
- We can define a `andThen` function that allows you to concat another future.
- Given 2 functions that perform asynchronous work, we can compose them together by concatenating them with an `andThen` function.
- We go from String to a Future of NSURL to a Future of UIImage, all in one line.

---

## [fit] `Future.andThen()`: concatenating async work

```swift
struct Future<T, E: ErrorType> {
    func andThen<U>(f: T -> Future<U, E>) -> Future<U, E>
}
```

^ - This would be the type signature.

---

## [fit] `Future.andThen()`: concatenating async work

```swift
func andThen<U>(f: T -> Future<U, E>) -> Future<U, E> {
    return Future<U, E>(operation: { completion in

    }
}

```

^ - Same as before, we create a new operation...

---

## [fit] `Future.andThen()`: concatenating async work

```swift
func andThen<U>(f: T -> Future<U, E>) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
        self.start { firstFutureResult in

        }
    })
}

```

^ - ...and retrieve the value from the original one.

---

## [fit] `Future.andThen()`: concatenating async work

```swift
func andThen<U>(f: T -> Future<U, E>) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
        self.start { firstFutureResult in
            switch firstFutureResult {
                case let .Success(value): // ...
                case let .Failure(error): // ...
            }
        }
    })
}

```

^ - Again, the value we retrieve can mean a success or an error...

---

## [fit] `Future.andThen()`: concatenating async work

```swift
case let .Success(value):
    let nextFuture = f(value)
```

^ - In the success case, we have the value T, and if we apply the function f we're given, we can get the new future we're going to concatenate.

---

## [fit] `Future.andThen()`: concatenating async work

```swift
case let .Success(value):
    let nextFuture = f(value)

    nextFuture.start { finalResult in
        completion(finalResult)
    }
```

^ - We can start the new future right away, and when we get the value, call the initial completion closure.

---

## [fit] `Future.andThen()`: concatenating async work

```swift
case let .Failure(error):
    completion(Result.Failure(error))
```

^ - The case of error looks just like in map: we didn't get the value `T`, so we can't apply the f function to continue, we must bail out and report the error to the caller.

---

## [fit] `Future.andThen()`: concatenating async work

```swift
func andThen<U>(f: T -> Future<U, E>) -> Future<U, E> {
    return Future<U, E>(operation: { completion in
        self.start { firstFutureResult in
            switch firstFutureResult {
                case let .Success(value): f(value).start(completion)
                case let .Failure(error): completion(Result.Failure(error))
            }
        }
    })
}
```

^ - This is what it looks like putting it all together.
- The implementation looks an awful lot like map(). In fact we could implement one in terms of the other.

---

## We can go from this...

```swift
func loadAvatar(userID: String, completion: (UIImage?, NSError?) -> ()) {
    requestUserInfo(userID) { user, error in
        if let user = user {
            downloadImage(user.avatarURL) { avatar, error in
                if let avatar = avatar {
                    completion(avatar, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
        else { completion(nil, error) }
    }
}
```

^ - Let's look at what we've accomplished; How this `Future` API has simplified our asynchronous code.
- We can get rid of this mess of nested callbacks, where errors have to be handled manually in every step of the way, which adds a lot of noise.

---

## ... To this

```swift
func requestUserInfo(userID: String) -> Future<User, UserInfoErrorDomain>

func downloadImage(URL: NSURL) -> Future<UIImage, UserInfoErrorDomain>


func loadAvatar(userID: String) -> Future<UIImage, UserInfoErrorDomain> {
    return requestUserInfo(userID)
    .map { $0.avatarURL }
    .andThen(downloadImage)
}
```

^ - No explicit error handling everywhere, but errors are being sent through.
- The `loadAvatar` function expresses with little noise what it needs to do to retrieve the values.
- When using this function, we have a compile-time guarantee that we detect the success and error cases correctly, and we can handle exactly the types of errors that are possible.

---

## Mixing it all up
### `Result<T, E>` and `throws`

^ - I've shown the now pretty standard `Result` type, and an example implementation of a bare-bones `Future` API.
- But it doesn't make sense to ignore Swift2's error handling features. They're going to be with us, so we have to embrace them.
- if I want you all to take something away from this talk is that these 2 things are not something we have to choose one and ignore the other. It's important to understand the pros and cons of each. And the great thing is that we can mix and match.

---

## `Result<T, E>` and `throws`
### `throws` => `Result`

```swift
extension Result {
  public init(@autoclosure _ f: () throws -> T) {
		do {
			self = .Success(try f())
		} catch {
			self = .Failure(error as! Error)
		}
	}
}
```

^ - Given a function that throws, we can construct a Result like this.

---

## `Result<T, E>` and `throws`
### `Result` => `throws`

```swift
extension Result {
  public func dematerialize() throws -> T {
		switch self {
		case .Success(value):
			return value
		case let .Failure(error):
			throw error
		}
	}
}
```

^ - But we can also go the other way around. Given a `Result`, we can extract the value using a `dematerialize` function, which is a throws function.
- This allows to go from the Result world, to the Swift2 function-that-errors world.

---

## `Result<T, E>` and `throws`
### `Future` => `throws`

```swift
let avatarFuture = loadAvatar("4815162342")

avatarFuture.start { result in
  do {
    let avatar = try result.dematerialize()
  }
  catch {
    // handle `error`
  }
}
```

^ - And this could for example be useful if we want to use the `Future` API that we just saw using Swift2's error handling syntax.

---

# Limitations of Futures

- Only represent computation to retrieve one value.
- Can't encapsulate streams of values.
- Only consumer (pull) driven, not producer (push) driven.

^ - Before we finish I'd like to say how I really feel about `Future`s.
- While a very useful abstraction, and we saw how it can dramatically improve traditional asynchronous code, it has a very important limitation.
- Futures or promises fail to represent another very common use case: continuous streams of values. They only encapsulate one value, but sometimes we deal with things like user interaction events or application state changes, which are continuous and producer driven, not consumer driven, like what we just showed.

---

## ReactiveCocoa

### Signals > Futures

^ - Signals are in a way a superset of Futures, and therefore they're a more useful abstraction.
- They make RAC an incredibly powerful tool.
- If I've convinced you that this API can help simplify your code, then check out ReactiveCocoa.
- RAC3 is implemented in Swift, and is currently in beta. If the stuff in this presentation was exciting to you, I encourage you to check it out when building your next Swift app.

---

## Follow-up Resources

- ReactiveCocoa: https://github.com/ReactiveCocoa/ReactiveCocoa
- Railway Oriented Programming: http://fsharpforfunandprofit.com/posts/recipe-part2/

---

# Thanks!

### *Questions?*
