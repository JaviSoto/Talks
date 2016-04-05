footer: "Asynchronous Code with ReactiveCocoa" - Javier Soto. March 2015
slidenumbers: true
autoscale: true

# [fit] Asynchronous Code with ReactiveCocoa

![inline](Images/rac_logo.png) ![inline](Images/swift-logo.png)

^ - Welcome!

---

# [fit] Previously, on Swift Summit...
![](Images/troy-mcclure.png)

^ - I wanna get an idea of how many of you guys saw my previous talk about Futures at the first Swift Summit. Raise your hand if you have.
- This is chapter 2. In that talk I went over the benefits of abstraction in asynchronous code with Futures, with an emphasis in error handling.
- My name is Javier, and I'm an iOS Engineer on the Fabric team at Twitter here in San Francisco.

---

# Flashback

^ - Let me summarize my previous talk very quickly...

---

# Before

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

^ - What I showed is one way in which we can leverage Swift's features to implement some abstractions that  allow us to simplify this type of code A LOT. By removing most of the boilerplate required to write asynchronous code in a function like this.

---

# After

```swift
func requestUserInfo(userID: String) -> Future<User, UserInfoErrorDomain>

func downloadImage(URL: NSURL) -> Future<UIImage, UserInfoErrorDomain>


func loadAvatar(userID: String) -> Future<UIImage, UserInfoErrorDomain> {
    return requestUserInfo(userID)
    .map { $0.avatarURL }
    .andThen(downloadImage)
}
```

^ - The talk showed the basic concept of Futures. And I showed a fairly naive implementation of this API, to accomplish this.
- Today I'd like to take that a step further.
- But first, I wanna talk about why.

---

# [fit] Why?

^ - Why do I care so much about this? Well, asynchrony is all over the place in mobile apps:

---

# Asynchrony in mobile applications

- KVO
- User data
- Networking
- Gesture recognizers
- Animations
- Sensors
- Mutable State
- ...

^ - Asynchrony is present everywhere in our apps. And by this I don't only mean multi-threading. Even things that are single threaded like animations still introduce asynchrony. Essentially a lot of the things in our applications are dependent on *time*. And this just makes it a whole lot harder to build mental models of the flows of information within our apps.

---

![inline](Images/nacho-talk.png)

^ - My brother Nacho gave a great talk about this. Instead of repeating all that, I simply wanted to reference it here, and encourage you all to watch it! It's available on the awesome Realm website.

---

# [fit] TL;DR
### [fit] Asynchronous code is hard

^ - The TL;DR is that this stuff is really hard. If you don't think it's really hard: we're hiring!

---

# Asynchronous code is hard

- Cancelation
- Throttling
- Error handling
- Retrying
- Threading
- ...

^ - Why is asynchronous code hard?
- Well, for starters we write code using languages and paradigms that were not particularly designed with this in mind.
- So when we're writing asynchronous code, we constantly need to deal with the same problems, over an over: (read list)
- We write code to deal with these problems all the time. So the logic to solve all these problems ends up sprinkled all throughout the app.
- Wouldn't it be great if we just focused on the domain problems of our application, and we leveraged abstraction to hide away all that complexity?
- I've seen several codebases grow from tiny and manageable to huge, and I've spent a lot of time wondering and researching and trying to figure out better patterns and tools to help me write better software with less headaches.
- So today I encourage you all to do the same, to challenge your ideas often, and to be open to the notion that our tools are imperfect.
- I wanted to share with you all some of the things that I learned in the past couple of years as I began on this journey of figuring out how to better architect iOS apps. Because ever since I started working on bigger bases, this idea kept popping into my head:

---

# [fit]''There has to be
# [fit]a better way!''

^ - It's really easy as programmers to get comfortable with what we know and are familiar with, because once we get used to it, we get this sort of Stockholm syndrome, and even Xcode seems to be OK.

---

> That perfection is unattainable is no excuse not to strive for it.
-- Stolen from Nacho's Twitter bio

^ - I like to remind myself this often, as a way of motivating myself to not settle and keep pushing my boundaries, try to get out of my comfort zone, and get better every day.

---

# [fit] ReactiveCocoa™

^ - In this journey, ReactiveCocoa was a huge discovery for me. I started using it back in Objective-C, and thanks to Swift, it got SO MUCH better. For a while I was hesitant of recommending it to people, since it wasn't the most approachable. But today I believe it's so much more mature. To me, it's an indispensable tool, not only to build iOS apps, but just to think about Software in general. I wanted to share some of that with you.
- I'm not trying to sell you anything. I don't get paid to sell ReactiveCocoa. While I have a personal preference, I really don't mind if you choose to adopt ReactiveCocoa, or one of the alternative frameworks that have come out: RxSwift, ReactKit...
- What I want to share is that there's a lot of power in these ideas, and I believe they're incredibly useful, and I encourage you to give them a chance if you haven't already.

---

# [fit]ReactiveCocoa
# is hard

^ - Many of you have heard about this RAC thing already. In fact, some of you are probably bored of hearing about it. Fear not, I'm not going to over every single feature. However, I'd like to discuss a little bit about the philosophy behind it, and hopefully it'll make more sense when I say that I think it's very valuable.
- But before I talk about the good things, let's be realistic: RAC is hard to adopt. Why is it hard?

---

# ReactiveCocoa is hard

- Syntax is unfamiliar
- Foreign concepts
- Feels different to traditional Cocoa APIs
- Apple's APIs don't use it.

^ - One of the ideas that really struck with me was that ReactiveCocoa doesn't necessarily attempt to make it easy. In the strict meaning of the word. Easy implies familiarity. ReactiveCocoa is not going to feel familiar at first. What ReactiveCocoa attempts is to make asynchronous code SIMPLE.
- So I won't lie to you: there is a significant learning curve here.

---

# ReactiveCocoa is simple[^1]

- Few concepts
- Abstract away complexity
- One pattern for asynchronous APIs

[^1]: ''Simple made Easy'' - Rich Hickey

^ - However, ReactiveCocoa tries to be *simple*.
- Simple is the opposite of complex. It brings very few concepts to the table, and with those concepts and ideas we can do all of these things and end up with much simpler code. That is the goal of ReactiveCocoa. Now, it's not gonna be easy to learn, but it may be worth it in the long run.

---

![inline](Images/iphone-cpu-perf.jpg)

^ Mobile apps are increasingly complex. They're not toy apps anymore. As hardware got better over time, we cramped more functionality into them.
- Every app evolved to be a fully fledged chat client. Some apps even evolved to be full Operating Systems with 18k classes.
- We need sane ways to model our apps so that we can spend more time making great features, and less time figuring out race conditions.

---

# [fit] Concepts in Cocoa involved in asynchronous APIs
- Delegation
- NSOperation
- NSNotificationCenter
- KVO
- Target-Action
- Responder chain
- Callback blocks

^ - These are all concepts that at some point we had to learn in order to use Cocoa APIs. This is a LONG list! And while each of these are slightly different, they kind of solve similar problems around asynchronous data flow.
- ReactiveCocoa unifies all of these things of all these under one umbrella. One API to understand. It takes a while, but once you get it, that’s all you need to know. None of us learned all of these concepts overnight!

---

# Signals

^ - This is ReactiveCocoa's core.
- By representing all those mechanisms in the same way, it’s easy to declaratively chain and combine them together, with less spaghetti code and state to bridge between all those words.

---

# Signals

- Next
- Failed
- Completed
- Interrupted

^ - Signals are a pipe that can carry these events...
- And this allows us to represent all things like cancellation or errors.

---

## `Signal`
## and
## `SignalProducer`

^ - Now, if you dig into ReactiveCocoa's API, you're quickly going to run into this, so I'd like to get it out of the way.
- This distinction, which was introduced in ReactiveCocoa 3, helps us understand the effect of observing something asynchronous. Because this can take two shapes. Let's look at an example

---

## [fit] `Signal` vs `SignalProducer`

```swift
func doSomethingAndGiveMeTheResult()    -> SignalProducer<Result, Error>



func observeSomeOnGoingWork()           -> Signal<NewValue, Error>
```

^ - The first one returns a SignalProducer. This API stablishes a contract that says: Whenever you observe this thing, some work is going to happen.
- Observing the signal returned by the second function, on the other hand, won't cause side effects.
- This distinction may seem very subtle, but compared to ReactiveCocoa 2, other RX frameworks, or even callback-block-based APIs, it makes APIs a lot easier to understand, and more importantly, harder to misuse.
- However, this doesn't mean we need to learn 2 separate APIs: Signal and SignalProducer. For the most part, they are used the same way!

---

# Operators

^ - The beauty of the Signal abstraction is the varied set of operators that we have that let us manipulate the values that are carried through in the signals in a declarative way. And in a uniform way.

---

# [fit] RAC's Operators: Declarative vs Imperative

```swift
let array = ["one", "two", "three"]

// Imperative
var newArray: [String] = []
for string in array {
    newArray.append(string.uppercaseString)
}

// Declarative
let newArray = array.map { string in return string.uppercaseString }
```

^ - This is kind of a contrived example, and you've probably seen this a million times, but I wanted to illustrate what I think is the biggest difference about using ReactiveCocoa's Signal operators vs implementing the same things in the ways we're used to.
- The problem with the imperative code above is that in mixes code that communicates (with other developers) *what* we're trying to do, with code that communicates (with the machine) *how* to do that thing.

---

# [fit] RAC's Operators: Declarative vs Imperative

```swift
let throttleInterval: NSTimeInterval = 0.5

// Imperative
func search(query: String, completion: ([SearchResult]?, MyErrorType?) -> ())
var lastSearch: NSDate? // <--- State
func didTypeSearchQuery(searchQuery: String) {
    guard (lastSearch?.timeIntervalSinceNow > throttleInterval) ?? false else { return }

    lastSearchDate = NSDate()
    search(searchQuery) { results, error in ... }
}

// Declarative
let searchQuerySignal: Signal<String, NoError>
func search(query: String) -> SignalProducer<[SearchResult], MyErrorType>

searchQuerySignal.throttle(throttleInterval).flatMap(.Latest, search)
```

^ - This is a parallel example of the same 2 approaches to problem solving. The first one is imperative. Look at all that logic. State. Ugh. I'm not even sure if it's correct, it probably isn't.
- This is what's really powerful about ReactiveCocoa's built-in operators: they encapsulate really complex logic in very simple APIs.

---

# Operators

- `map`
- `filter`
- `reduce`
- `collect`
- `combineLatest`
- `zip`
- `merge` / `concat` / `switchToLatest`
- `flatMapError` / `mapError`
- `retry`
- `throttle`

^ - This is a non exhaustive list of the operators in ReactiveCocoa. One does not need to know all of them. Just knowing a couple can help you accomplish 90% of what you attempt to do. And you can go from there.

---

# KVO

^ - One of the most common criticisms that I hear about Swift is that it's too terse. Its static nature is too strict. One example that's often given of this, is that it doesn't let you do KVO.
- KVO is one of the most powerful concepts that I learned when I started doing iOS, and ReactiveCocoa 2 used to rely heavily on it.
- However, I argue that KVO was also incredibly fragile. Let's see why.

---

# [fit] KVO

- Crash if object deallocates while being observed.
- Crash if observe wrong keypath (stringly-typed API)
- Possible crash when de-registering
- Easy to break parent class (`context` often misused)
- All observations come through one method
- Lose contract: "is this KVO-compliant?"

^ - The idea of KVO is great, its API however has a lot of reasons to make your app crash. And it doesn't precisely help you write small, maintainable functions.
- Even things that look like KVO-compliant, may not always send values through. e.g weak properties going nil, UIKit.

---

# Property

^ - So let me talk about one last tool from ReactiveCocoa's toolbox: Property.
- `Property` allows us to declare a member of an object as explicitly observable. As in, the fact that the values of the property can be observed is part of the API contract. The client of the API doesn't have to guess, or to trust the documentation or StackOverflow.

---

# Property

```swift
// KVO
class MyClass {
    private(set) dynamic var value: Type
}

let object = MyClass()
object.addObserver(self, forKeyPath: "value", options: [], context: ctx)
func observeValueForKeyPath(keyPath: String?,
    ofObject object: AnyObject?,
     change: [NSObject : AnyObject]?,
     context: UnsafeMutablePointer<Void>) { /* HAVE FUN!! */ }

// PropertyType
class MyClass {
    var value: AnyProperty<Type>
}
let object = MyClass()
object.value.producer.startWithNext { value in ... }
```

^ - This is what it looks like. The producer that we observe will automatically complete when the object is deallocated. There are no strings involved, and we have the benefit of code locality since we can react to changes to that property inline with where we observe it, and not in some other method were we handle the changes to all the properties we're observing.
- So next time you hear somebody say "Swift doesn't let you do KVO!", you can say: "that's not true!". I think this is *so much better* than KVO.

---

# Myth:
### *"To use ReactiveCocoa, I need to re-write my whole app"*

^ - So if I've done an OK job, hopefully at this point you're thinking: "OK Javi, that's cool. I'd give this a try, but I'm not gonna re-write my whole app!"
- Something I'd like to stress is that ReativeCocoa is not all-or-nothing. It's not like UIKit in that sense. If you're using UIKit, you kind of have to use view controllers and UIViews. However, it is possible to start using ReactiveCocoa in some small part of your application, learn and benefit from it there, while leaving the rest of the app untouched.
- When I joined Pebble 2 years ago, the 1.0 version of the app didn't use ReactiveCocoa. I adopted it as I started working on the v2. Slowly implementing new features with it, refactoring old code with it to simplify it and fix bugs. I wasn't an expert when I started. Heck, I barely knew what I was doing. But I have no regrets!
- So my suggestion: start small: Try adopting it in maybe the API layer, some view controllers. Wherever there's really heavy asynchronous logic.  I think it's worth it!

---

# Conclusions

- Our tools are imperfect. Strive to reconsider patterns, seek better alternatives.
- There's value in these abstractions.
- ReactiveCocoa can be adopted slowly.

---

# References

- **ReactiveCocoa**: [https://github.com/ReactiveCocoa/ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)
- **Back to the Futures** - Me: [https://realm.io/news/swift-summit-javier-soto-futures](https://realm.io/news/swift-summit-javier-soto-futures/)
- **Functional Reactive Programming
in an Imperative World** - Nacho Soto: [https://realm.io/news/nacho-soto-functional-reactive-programming](https://realm.io/news/nacho-soto-functional-reactive-programming/)
- **"Simple made Easy" - Rich Hickey**: [http://www.infoq.com/presentations/Simple-Made-Easy](http://www.infoq.com/presentations/Simple-Made-Easy)

---

# Thank you!
