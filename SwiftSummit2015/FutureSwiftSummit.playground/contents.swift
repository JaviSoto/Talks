// Playground - noun: a place where people can play

import UIKit
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely(continueIndefinitely: true)

//: # Swift Future API

//: ## Types

public final class Box<T> {
    public let unbox: T

    init(_ value: T) {
        self.unbox = value
    }
}

public protocol ErrorType { }

public enum NoError: ErrorType { }

extension NSError: ErrorType { }

public enum Result<T, E: ErrorType> {
    case Success(Box<T>)
    case Error(Box<E>)
}

extension Result: DebugPrintable {
    public var debugDescription: String {
        switch self {
            case .Success(let valueBox):
                return "Success: \(toString(valueBox.unbox))"
            case .Error(let errorBox):
                return "Error: \(toString(errorBox.unbox))"
        }
    }
}
//: ## Future
//: - Encapsulate a deferred computation.
//: - Treat values that incur a delay to be retrieved as if they were regular values.
//: - Allow us to treat errors as first class citizens.
//: - Easily composable.

public struct Future<T, E: ErrorType> {
    public typealias ResultType = Result<T, E>
    public typealias Completion = ResultType -> ()
    public typealias AsyncOperation = Completion -> ()

    private let operation: AsyncOperation

    public init(result: ResultType) {
        self.init(operation: { completion in
            completion(result)
        })
    }

    public init(value: T) {
        self.init(result: .Success(Box(value)))
    }

    public init(error: E) {
        self.init(result: .Error(Box(error)))
    }

    public init(operation: AsyncOperation) {
        self.operation = operation
    }

    public func start(completion: Completion) {
        self.operation() { result in
            completion(result)
        }
    }
}

//: ## Future Operations

extension Future {
    public func map<U>(f: T -> U) -> Future<U, E> {
        return Future<U, E>(operation: { completion in
            self.start { result in
                switch result {
                    case .Success(let valueBox): completion(Result.Success(Box(f(valueBox.unbox))))
                    case .Error(let errorBox): completion(Result.Error(errorBox))
                }
            }
        })
    }

    public func andThen<U>(f: T -> Future<U, E>) -> Future<U, E> {
        return Future<U, E>(operation: { completion in
            self.start { firstFutureResult in
                switch firstFutureResult {
                    case .Success(let valueBox): f(valueBox.unbox).start(completion)
                    case .Error(let errorBox): completion(Result.Error(errorBox))
                }
            }
        })
    }
}

extension Future {
    func mapError<F>(f: E -> F) -> Future<T, F> {
        return Future<T, F>(operation: { completion in
            self.start { result in
                switch result {
                    case .Success(let valueBox): completion(Result.Success(valueBox))
                    case .Error(let errorBox): completion(Result.Error(Box(f(errorBox.unbox))))
                }
            }
        })
    }
}

//: ### Traditional async code

struct User {
    let avatarURL: NSURL
}

func requestUserInfo(userID: String, completion: (User?, NSError?) -> ()) {}
func downloadImage(URL: NSURL, completion: (UIImage?, NSError?) -> ()) {}

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

//: ### Same code with Futures

enum UserInfoErrorDomain: ErrorType {
    case UserDoesNotExist
    case UserRequestFailure
    case NetworkRequestFailure
}

extension UserInfoErrorDomain: DebugPrintable {
    var debugDescription: String {
        switch self {
            case .UserDoesNotExist: return "UserDoesNotExist"
            case .UserRequestFailure: return "UserRequestFailure"
            case .NetworkRequestFailure: return "NetworkRequestFailure"
        }
    }
}

func downloadFile(URL: NSURL) -> Future<NSData, UserInfoErrorDomain> {
    return Future() { completion in
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let result: Result<NSData, UserInfoErrorDomain>

            if let data = NSData(contentsOfURL: URL) {
                result = Result.Success(Box(data))
            }
            else {
                result = Result.Error(Box(.NetworkRequestFailure))
            }

            completion(result)
        }
    }
}

func requestUserInfo(userID: String) -> Future<User, UserInfoErrorDomain> {
    if let url = NSBundle.mainBundle().URLForResource("\(userID)-avatar", withExtension: "jpeg") {
        return Future(value: User(avatarURL: url))
    }
    else {
        return Future(error: .UserDoesNotExist)
    }
}

func downloadImage(URL: NSURL) -> Future<UIImage, UserInfoErrorDomain> {
    return downloadFile(URL)
        .map { UIImage(data: $0)! }
}

func loadAvatar(userID: String) -> Future<UIImage, UserInfoErrorDomain> {
    return requestUserInfo(userID)
        .map { $0.avatarURL }
        .andThen(downloadImage)
}

let avatarFuture = loadAvatar("javi")

avatarFuture.start() { result in
    switch result {
        case .Success(let image):
            image.unbox
        case .Error(let error):
            error.unbox
    }
}

let avatarError = loadAvatar("invalidUser").mapError { _ in
    return NSError(domain: "MyErrorDomain", code: 3, userInfo: nil)
}

avatarError.start() { result in
    println(result)
}
