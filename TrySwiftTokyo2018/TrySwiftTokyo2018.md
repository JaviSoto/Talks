footer: "​Optimizing Swift code for separation of concerns and simplicity." "関心の分離と単純化のためのSwiftコードの最適化" - @Javi
slidenumbers: true
autoscale: true
theme: Libre, 1

# Optimizing Swift code for separation of concerns and simplicity
### 関心の分離と単純化のためのSwiftコードの最適化

---

# Intro

## - Pebble
## - Twitter (Fabric)
## - ![inline 100%](Images/twitch.png)

^ - Hi! My name is Javi. I'm an iOS engineer at Twitch in San Francisco, California.
- I'm originally from Spain. Previously, I worked on the iOS apps at Pebble, and Fabric at Twitter.
- You can find me on Twitter at @Javi, where I tweet about iOS, but also about other random things like space, chess, and airplanes.

----

## Coding Principles
### コーディングの原則

^ - At Twitch, I work with a fairly big team of 10 iOS engineers. I would say that one of my biggest responsibilities is code reviewing.
- I love code reviewing because it's a great way to learn from one another. I review a lot of code because I like to help keep a high bar of quality in our codebase. And at the same time I also learn a lot by reading my coworkers' code.

----

## Coding Principles
### コーディングの原則<br><br>
### - Simplicity / 単純
### - Conciseness / 簡潔
### - Clarity / 明確

^ - These are some of the principles that I abide by and try to optimize for when I provide code review feedback. They also happen to be core tenets of Swift, which is great.
- In today's short talk I wanted to show some examples of different tips and tricks that I have found to really help when optimizing for simplicity in the code that we write. You may already know some of them, but I hope you can still take some ideas away from this talk.
- We often talk about high level architecture patterns, but it's more rare that we think about optimizing the way we write code locally, how to make functions and classes easier to understand and follow. That's what I'd like to focus on today.

---

[.build-lists: true]

## Separation of Concerns
### 関心の分離<br><br>

### - Code is read much more often than it is written
### コードは書かれることよりも読まれることの方が多い<br><br>
### - Separating the *"what"* from the *"how"*
###   *How* から *what* を切り離す

^ - One of the things I like to remind myself of is that we read code many more times than we write it, so taking a bit of extra time to make it simple we can make it easier for other people, and our future selves, to understand it. Sometimes we want to get something done and working quickly, maybe because we can't wait to get it in front of our users. So the question I like to ask myself is: "will I understand what this code was trying to do when I read it again some time in the future".
- It's hard to answer that question as you're writing some code, because at that time you probably have a good understanding of what it does. But learning to critically answer that question helps develop empathy for other people as well.
- ​Separating concerns in code is often seen as a premature optimization when code doesn’t need to be reused, but it has huge implications in our ability to comprehend what code does. The way that I think about this is the following: "Is the details in this code about how some task is achieved obscuring the details of WHAT is this code trying to achieve?".
- Let’s explore examples of this in Swift, and how we can extract the "how" some code works using tools like extensions and enums, so that the core parts of our code can be focused on the "what" this code does, gaining clarity as a result.

----

# Example 1 (Before)

```swift
func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
              replacementText text: String) -> Bool {
    sendButton.isEnabled =
      textView.text.utf16.count
      + text.utf16.count
      - range.length <= 140

    return true
}
```

^ - Here we have a small example of code duplication. We're counting the length of the strings using "utf16 dot count" twice, to determine whether the length of the text after an edit exceeds some limit.
- This is completely fine. And I when I point it out, most people would probably say it's not worth extracting this and creating an abstraction.
- But I would argue that the fact that we're doing that twice is obscuring the detail that it's important in this context to count the characters in this specific way.
- Going back to my earlier point. One way that we can approach this is asking ourselves: "When I see this code in 3 months, will I understand why it's using utf16 to count characters?"

----

# Example 1 (After)

```swift
private extension String {
  var characterCountUsingBackendPolicy: Int {
    return utf16.count
  }
}

func textView(_ textView: UITextView,
              shouldChangeTextIn range: NSRange,
              replacementText text: String) -> Bool {
  let characters =
    textView.text.characterCountUsingBackendPolicy
    + text.characterCountUsingBackendPolicy
    - range.length

  let characterLimit = 140

  sendButton.isEnabled = characters <= characterLimit

  return true
}
```

^ - We can very easily create a helper on String that gives a name to our "concept". We don't have to create a different file for it. We can put it alongside the code that uses it. But now we can read the code and understand that this is using a very specific policy for counting characters, that is important for how it's implemented in the backend.
- Before Swift, we could do this sort of thing in Obj-C using categories. However the syntax was a lot more verbose, and you had to worry about name collisions with Apple's private methods. But in Swift, this becomes so much easier, that I find myself doing this in many more places that I wouldn't have considered before.
- With this code I can be much more confident that, when I read it in 3 months, I will understand why it behaves that way. We've separated the "how characters are counted" from "what we're trying to accomplish".

----

# Example 2 (Before)

```swift
api.requestReplies(postID: 4815162342) { [weak self] result in
   switch result {
   case .success(let replies):
     var filteredReplies: [Reply] = []
     for reply in replies {
       if !user.isBlocking(reply.author) {
         filteredReplies.append(reply)
       }
     }

     self?.replies = filteredReplies
   case .failure:
       // ...
   }
}
```

^ - I based this one on some code in our app and simplified it a bit for this example. Now, there isn't anything wrong per-se with this code! But let's ask ourselves the same question again, and be critical about how easy it is to read this and figure out what it's trying to do.
- It's not terribly hard, but there's some reading required. The actual code in our app is actually more verbose and has more details than this. It's often that code can be optimized but we leave it the way it is because at the beginning it's not very long. And it's afterwards as we add more features that now logic behind the code starts getting more blurry.
- Here we're making a network request to get some post's replies, and we'll filtering them, inline with the request code.

----

# Example 2 (After)

```swift
extension Collection where Element == Reply {
  var filteringBlockedContent: [Reply] {
    return filter { !user.isBlocking($0.author) }
  }
}

api.requestReplies(postID: 4815162342) { [weak self] result in
   switch result {
   case .success(let replies):
     self?.replies = replies.filteringBlockedContent
   case .failure:
       // ...
   }
}
```

^ - What I have done here is 2 things. The first is I've extracted the logic into an extension. This way the code that uses it contains no details about *how* the filtering works. It now only points at the fact that it's filtering blocked content. We've greatly increased the signal-to-noise ratio in this code. We've made it a ton more expressive, with less code to read.
- The extension `var` is also implemented using a functional operator, `filter`. These are often a great way to abstract away the details of how something is done. They allow us to focus on the task at hand, in this case, filtering a collection.

----

# Example 3 (Before)

```swift
NSLayoutConstraint.activate([
  subview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
  subview.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
  view.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
  view.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom)
])
```

^ - This example is about AutoLayout. The AutoLayout APIs can be very verbose. This can lead to code with a lot of noise, like this.
- Can you tell me at first sight what this code is trying to do? Its goal is actually very simple, but it's obscured by the amount of syntactic noise. Apple made this a lot better with the introduction of the layoutAnchor APIs, but it could still be improved.

----

# Example 3 (After)

```swift
NSLayoutConstraint.activate([
  subview.leadingAnchor ≈ view.leadingAnchor + insets.left,
  subview.topAnchor ≈ view.topAnchor + insets.top,
  view.trailingAnchor ≈ subview.trailingAnchor + insets.right,
  view.bottomAnchor ≈ subview.bottomAnchor + insets.bottom
])

infix operator ≈ : LayoutAnchorPrecedence

func ≈ <AnchorType>(lhs: NSLayoutAnchor<AnchorType>,
                    rhs: LayoutAnchorTransform<AnchorType>) -> NSLayoutConstraint {
    return lhs.constraint(equalTo: rhs.anchor, constant: rhs.constant)
}

func + <AnchorType>(lhs: NSLayoutAnchor<AnchorType>,
                    rhs: CGFloat) -> LayoutAnchorTransform<AnchorType> {
    return LayoutAnchorTransform(anchor: lhs, constant: rhs)
}
```

^ - My coworker Kevin contributed this awesome set of operators. Now, a lot of us get a little scared with the idea of custom operators cluttering our codebase. But these have been incredibly useful simplifying all the code where we create constraints. The readability of the code that creates constraints, without all the syntactic noise of the NSLayoutConstraint API is fantastic.

----

# Example 3 (After 2)

```swift
NSLayoutConstraint.activate(NSLayoutConstraint.anchoring(subview, within: view))

extension NSLayoutConstraint {
  static func anchoring(_ subview: UIView,
                        within view: UIView,
                        insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
    return [
      subview.leadingAnchor ≈ view.leadingAnchor + insets.left,
      subview.topAnchor ≈ view.topAnchor + insets.top,
      view.trailingAnchor ≈ subview.trailingAnchor + insets.right,
      view.bottomAnchor ≈ subview.bottomAnchor + insets.bottom
    ]
 }
}
```

^ - But we can do even better. Constraining one view to its parent, which is what the initial code was doing, is such a common task, that it would be worth having a helper for that. So we can just say, activate the constraints to anchor one view within a superview.

----

# Example 3 (Before and After)

```swift
// Before
NSLayoutConstraint.activate([
  subview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
  subview.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
  view.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
  view.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom)
])

// After
NSLayoutConstraint.activate(NSLayoutConstraint.anchoring(subview, within: view))
```

^ - This is the before and after. Note that this is not about the number of lines of code. Even though having less is definitely not a bad thing, but it's about the expressivity of the code. With the new API, the code tells us exactly what it's purpose is, we don't have to guess it.

-----

# Example 4


```swift
class MyView: UIView {
  var activeConstraints: [NSLayoutConstraint] = [] {
    willSet { NSLayoutConstraint.deactivate(activeConstraints) }
    didSet { NSLayoutConstraint.activate(activeConstraints) }
  }

  var headerVisible: Bool { didSet {
    activeConstraints = [
      view.topAnchor ≈ (headerVisible ? header.topAnchor : header.bottomAnchor),
      // more ...
    ]
  }
}
```

^ - This is a very simple one that I picked up recently from a coworker and I quite like. I was really struggling keeping track of constraints in views that dynamically updated the layout. And I kept making mistakes when enabling / disabling constraints.
- This strategy is to have an array of the active constraints, and make it be responsible for deactivating the old ones and activating the new ones.
- So now making changes is just as simple as just setting a new array of constraints.

----

# Example 5 (Before)

```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
  return 3
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  let cell = tableView.dequeueReusableCell(withIdentifier: "identifier", for: indexPath)

  if indexPath.row == 0 {
    cell.textLabel.text = "General"
  } else if indexPath.row == 1 {
    cell.textLabel.text = "Notifications"
  } else if indexPath.row == 2 {
    cell.textLabel.text = "Log Out"
  }

  return cell
}
```

^ - Next is a classic one. So many times we have a table view with a known set of rows, and we end up writing code like this, that looks at the indexPaths in several places. This is fragile, and very error prone when we want to make changes to this table view.

----

# Example 5 (After)

```swift
enum Row {
  case general, notifications, logout

  var title: String {
    switch self {
    case .general: return "General"
    // ...
    }
  }
}
let rows: [Row] = [.general, .notifications, .logout]

func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
  return rows.count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  let cell = collectionView.dequeueReusableCell(...
  cell.textLabel.text = rows[indexPath.row].title
  return cell
}
```

^ - What we have done here is created a source of truth for the data behind a table view, even if it's a static one like this.
- Now if we want to reorder the rows, or add a new one, we can do that with our `Row` type, and we don't have to deal with indexPaths.

----

# Example 6 (Before)

```swift
func showTutorial() {
  guard !UserDefaults.standard.bool(forKey: "has_seen_tutorial") else { return }

  // Show tutorial

  UserDefaults.standard.set(true, forKey: "has_seen_tutorial")
}
```

^ - The goal of this example is to show the power of simply extracting some code into a `var` property. You may have written code like this where you're accessing `user defaults` several times in a lot of places in some file. Instead of this...

----

# Example 6 (After)

```swift
var hasSeenTutorial: Bool {
  get { return UserDefaults.standard.bool(forKey: "has_seen_tutorial") }
  set { UserDefaults.standard.set(newValue, forKey: "has_seen_tutorial") }
}

func showTutorial() {
  guard !hasSeenTutorial else { return }

  // Show tutorial

  hasSeenTutorial = true
}
```

^ - We can create a variable that's backed by user defaults. Now we can access a value that's really stored in user defaults as if it was a regular variable access. I think it's quite neat.

----

# Example 7 (Before)

```swift
if #available(iOS 11.0, *) {
  constraints = [
    subview.topAnchor ≈ view.safeAreaLayoutGuide.topAnchor,
    subview.leadingAnchor ≈ view.safeAreaLayoutGuide.leadingAnchor,
    subview.bottomAnchor ≈ view.safeAreaLayoutGuide.bottomAnchor,
    subview.trailingAnchor ≈ view.safeAreaLayoutGuide.trailingAnchor,
  ]
} else {
  constraints = [
    subview.topAnchor ≈ view.topAnchor,
    subview.leadingAnchor ≈ view.leadingAnchor,
    subview.bottomAnchor ≈ view.bottomAnchor,
    subview.trailingAnchor ≈ view.trailingAnchor,
  ]
}
```

^ - I decided to include this one because I bet a lot of you have code like this in your app, especially to support iPhone X.
- We were doing this all over the codebase. We needed to constrain views to the safe area layout guide, but that's only available on iOS 11, and we support iOS 9. So we had to constantly conditionally set up the constraints like this.
- But then I learned that you can create your own layout guides!

----

# Example 7 (After)

```swift
extension UIView {
  var tw_safeAreaLayoutGuide: UILayoutGuide {
    if #available(iOS 11.0, *) {
      return safeAreaLayoutGuide
    }

    if let tw_safeAreaLayoutGuide = objc_getAssociatedObject(self, associatedKey) as? UILayoutGuide {
      return tw_safeAreaLayoutGuide
    }

    let tw_safeAreaLayoutGuide = UILayoutGuide()
    addLayoutGuide(tw_safeAreaLayoutGuide)

    NSLayoutConstraint.activate(NSLayoutConstraint.anchoring(tw_safeAreaLayoutGuide, within: self))

    objc_setAssociatedObject(self, associatedKey, tw_safeAreaLayoutGuide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    return tw_safeAreaLayoutGuide
  }
}
```

^ - So we created a `tw safeAreaLayoutGuide`. That is always available, regardless of the iOS version. If we're on iOS 11, it just returns the UIKit safe area layout guide. If not, we create our own layout guide, that's simply anchored to the view bounds.
- The idea here is to, whenever possible, implement a backwards-compatible alternative to a new API, that, when running on the old iOS version, has the legacy behavior. That way we can write code around the app as if that API was always available, without having to check everywhere for API availability.

----

# Example 8 (Before)

```swift
// Set size big enough to make it easy to tap
button.frame = CGRect(origin: .zero, size: CGSize(width: 44, height: 44))
```

^ - How many times have you made a button artificially big so that it could be easier to tap?
- Apple recommends touch targets to be at least 44x44 points. If we have a button with an icon that's a small image, and we let the button size itself, sometimes it won't be big enough, so we may do something like this.
- We were doing this in several places in our app, but it meant that these buttons were hard to align visually with one another.

----

# Example 8 (After)

```swift
class TWMinimumHitAreaButton: UIButton {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard !isHidden && enabled && isUserInteractionEnabled && alpha >= 0.01 else {
      return nil
    }

    let lengthOfTappableAreaOutside: CGFloat = 10.0
    let minimumHitAreaSize = CGSize(width: 44, height: 44)

    // Increase the hit frame to be at least as big as `minimumHitArea`
    let buttonSize = bounds.size
    let widthToAdd = max(minimumHitAreaSize.width - buttonSize.width, lengthOfTappableAreaOutside * 2)
    let heightToAdd = max(minimumHitAreaSize.height - buttonSize.height, lengthOfTappableAreaOutside * 2)
    let largerFrame = bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

    // Perform hit test on larger frame
    let hit = largerFrame.contains(point)
    return hit ? self : nil
  }
}
```

^ - Instead of this, we created a reusable `UIButton` subclass, "Minimum Hit Area Button".
- Don't worry if you can't read everything on the slide, they're available on my Github and I'll be tweeting a link later.
- This class implements "hit test" to extend the tappable surface of the button, regardless of the size of its `frame`.
- The implementation details don't matter that much. What matters is that now we can use this class, instead of making buttons artificially big all over the place, or hardcoding 44pt, and we'll know those buttons will be easy to tap on.

----

# Example 9 (Before)

```swift
/// [ Send ]   /   [ Close ]   /   [ Send ] - [ Close ]

private let sendButton: UIButton
var showSendButton: Bool {
  didSet {
    if showSendButton {
      addSubview(sendButton)
    } else {
      sendButton.removeFromSuperview()
    }
    configureConstraints()
  }
}

private let closeButton: UIButton
var showCloseButton: Bool {
  didSet {
    // ...
  }
}
```

^ - Alright, continuing with the `UIKit` theme here.
- This won't be nothing new, but we only started adopting this in the Twitch codebase recently.
- So whenever you have a dynamic view like this, where depending on the state we hide or show some views, it becomes complicated to manage the layout. We have to handle different combinations, and often manage a complex set of constraints.
- So writing code like this is very cumbersome, and very error prone. How can we do this better?

----

# Example 9 (After)

```swift
private let sendButton: UIButton
private let closeButton: UIButton
private let stackView = UIStackView(arrangedViews: sendButton, closeButton)

var showSendButton: Bool {
  didSet {
    sendButton.isHidden = !showSendButton
  }
}

var showCloseButton: Bool {
  didSet {
    closeButton.isHidden = !showCloseButton
  }
}
```

^ - Using `stack views`! Turns out that `stack views` have these magic behavior where, if you set one of its `arranged subviews` hidden, it not only disappears, but the `stack view` will actually remove it from the layout, moving everything around. So managing the state of a view where we want to hide/show subviews like this is as easy as setting those subviews isHidden property. It's fantastic. This may be the most useful thing I have learned in the past year. Adopting this allowed us to remove a lot of code and simplify a lot of the UI code in the Twitch app.

----

### Example 10

^ - To put this last example in context, let me talk about a specific task I was working on a few weeks ago.
- The `ViewController` that we use to show a user profile in our app used to require to be instantiated with a lot of details about the user.
- However, in this new scenario we were only going to have the user ID, and we needed to present the profile screen with only that. And it would perform a network request before showing all the rest of the information.

----

# Example 10

- ProfileViewController
  - user details
      - children views

^ - This is what we had before. We instantiated the profile view controller with all of the user details, and that allowed us to instantiate all of the internal views, which depended on having all of the properties of the user object during initialization.

----

# Example 10

- ProfileViewController
  - userID
  -  *(user details)*
      - *(children views)*

^ - And now we needed it to work like this. Instantiating the view controller with just a user ID, and the rest of the user details and children views would come later.

----

# Example 10

```swift
final class ProfileViewController: UIViewController {
  // Before:
  private let userInfo: UserInfo
  private let headerView: ProfileHeaderView

  // After:
  private var userInfo: UserInfo?
  private var headerView: ProfileHeaderView?
  private var spinner: UIActivityIndicatorView?
  private var retryButton: UIButton?
}
```

^ - Again, the code in this slide is simplified from the actual source. In practice, it's very common in a scenario like this to have many more views and perhaps children view controllers.
- Before, all the properties could be non-optional. We can create them during initialization.
- But with our change, we have to make all of them optional, and now we need to manage all of those being nil in a lot of methods during the life-time of the view controller. That code gets really messy really quickly. I think Swift `Optional`s are great, but a lot of people actually dislike them. My theory is that, in practice, what's great about Swift `Optional`s is our ability to make things NOT `Optional`. And we should strive for that whenever we can.
- This is another place where Swift `enums` would excel. They allow us to express the state of our UI in a very explicit way.

----

# Example 10

```swift
final class ProfileViewController: UIViewController {
  private enum State {
    case pending
    case loading(spinner: UIActivityIndicatorView)
    case failed(retryButton: UIButton)
    case loaded(userInfo: UserInfo, headerView: ProfileHeaderView)
  }

  private var state: State = .pending
}
```

^ - I have started including something like this in a lot of the `ViewController`s that I work on.
- The `State` `enum` can use associated values to indicate that, when the UI is in those states, those associated views are available.

----

# Example 10

```swift
final class ProfileViewController: UIViewController {
  var state: State = .pending

  private func loadUserDetails() {
    state = .loading(spinner: UIActivityIndicatorView())

    api.requestUserDetails(userID) { [weak self] result in
      switch result {
      case let .success(userInfo):
        self?.state = .loaded(userInfo: userInfo, headerView: createHeaderView(userInfo))
      case let .failure:
        self?.state = .failed(createRetryButton())
      }
    }
  }
}
```

^ - Here we make the network request to load the user details. This function is responsible for updating the state, and setting the associated views for each of them.
- Now every other method in our class can concretely now in what state the UI is, and can pull out the views that are being used, without having to deal with `Optional`s.

----

# Example 10

```swift
final class ProfileViewController: UIViewController {
  var visibleView: UIView? {
    willSet { visibleView?.removeFromSuperview() }
    didSet  { if let visibleView = visibleView { view.addSubview(visibleView) } }
  }
  var state: State = .pending {
    didSet {
      switch state {
      case .pending: visibleView = nil
      case .loading(let spinner): visibleView = spinner
      case .loaded(_, let profileHeaderView): visibleView = profileHeaderView
      case .failed(let retryButton): visibleView = retryButton
      }
    }
  }
}
```

^ - And we can handle the `state` `var` like this. I'm a big fan of using the `didSet` part of variables that hold some "source of truth" to make sure that the state that depends on that value gets updated as a result of that value changing. So in this case, we update which view is visible in our hierarchy. And that `var` removes the old visible view, and adds the new one to the hierarchy.
- Similarly, updating the `state` value updates which view is visible. So when we're loading, we show the spinner, when we have loaded, we can display the profile view, and when we have failed, we can show the retry button.

----

# Summary

### - Value in optimizing readability in local scopes
### ローカルスコープの可読性の最適化には価値がある<br>
### - DRY (Don't Repeat Yourself)
### - Swift enums are awesome

^ - To summarize, we spend a lot of time reading code, so focusing on the local patterns that we use to make functions and classes readable and understandable can go a long way in making our overall codebase easier to work with.
- Finding things that we keep repeating over and over, and extracting them into a common API is useful because, in doing so, we can isolate the algorithms and implementation details, so the code that we read most of the time will just focus on *what* we're trying to do, and not so much on the specific details of how that's accomplished.
- And lastly, learn to love enums. They may be the most powerful tool in the whole Swift programming language.

----

# [fit] Happy Swifting!


## Thank you.

^ - Thank you! Have a great rest of the conference.
