# SHNUrlRouter
Simple Router for Swift based on Laravel’s Router, though it’s lacking Laravel’s advanced features like groups and everything that comes with them.

## Swift 2.3 support

Switch to the `swift23` branch.

## Swift 3 support

Switch to the `swift3` branch.

## Installation

> _Note:_ SHNUrlRouter requires Swift 2.0 or later.
>
> In order to use SHNUrlRouter with CocoaPods, you must have a minimum
> deploy target of iOS 8 and using CocoaPods frameworks.
>
> If you need to support iOS 7, you’ll need to install without CocoaPods

### CocoaPods

```
use_frameworks!
pod 'SHNUrlRouter', '~> 1.1'
```

### Without CocoaPods

If you’re not using Cocoapods, you can instead drag the `*.swift` files from this repository into your project.

### Swift 1.2

If you’re using this with Swift 1.2, you’ll need to use the 1.0 tag

```
use_frameworks!
pod 'SHNUrlRouter', '1.0'
```

## Basic Routing

Setting up the router is as simple as defining a couple of routes and providing a handler to be triggered when they’re dispatched.

```
let router = SHNUrlRouter()

router.register("feed") { [weak self] (parameters) in
	self?.tabBarController.selectedIndex = 0
}
```

This will create a router and register a handler that switches to the first tab when the feed URL is dispatched.


### Route Parameters

You can specify route parameters to support more advanced routing:

```swift
router.register("user/{id}/{section?}") { [weak self] (parameters) in
	// Non-optional parameters are guaranteed to be in the parameters
	// dictionary, or the route won’t dispatch, so you can skip the
	// usual guard let block if you’d like
	let id = parameters["id"]!

	let viewController = UserViewController(identifier: id)

	// Optional parameters are not guaranteed, so you should handle
	// their presence conditionally
	if let section = parameters["section"] {
		viewController.section = section
	}

	self?.tabBarController.presentViewController(viewController, animated: true, completion: nil)
}
```

### Route Aliases

Above we use the `id` and `section` parameters, however at this point they’re completely unconstrained and any path segment will match.  You can use route aliases to specify a regex pattern that the parameters need to match:

```swift
// If your user IDs are numeric, you can use a numeric pattern to ensure you’ll always
// get a numeric id, otherwise the route won’t be dispatch
router.add("id", pattern: "[0-9]+")

// Similarly, if you want to ensure only specific sections dispatch, you can do that too
router.add("section", pattern: "profile|activity")
```

## Dispatching Routes

Dispatching routes is as simple as passing a URL to the router.

```swift
func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
	return self.router.dispatch(url)
}
```

#### Heads up

SHNUrlRouter was built with support for full `http://` links, with an eye towards iOS 9 and deep app linking.  This means router is matching based on the path part of the URL and nothing else.

Prior to iOS 9, it was common for app’s to use a URL format like `myapp://profile`.  This won’t work with the router out of the box because the `host` value is set to "profile" and not the `path` value.

If you’re using a similar URL format for your app, you could use a quick/crude workaround as seen below until you’re ready to adopt full http linking:

```swift
func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
	if url.scheme == "myapp" {
		if let url = url.absoluteString?.stringByReplacingOccurrencesOfString("://", withString: "://host/") {
			return self.router.dispatch(url)
		}
	}

	return false
}
```

## Full Implementation

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
	private let router = SHNUrlRouter()

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		self.router.add("id", pattern: "[0-9]+")
		self.router.add("section", pattern: "profile|activity")

		self.router.register("feed") { [weak self] (parameters) in
			self?.tabBarController.selectedIndex = 0
		}

		self.router.register("user/{id}/{section?}") { [weak self] (parameters) in
			guard let stringId = parameters["id"], let id = Int(stringId) else {
				return
			}

			let viewController = UserViewController(identifier: id)

			if let section = parameters["section"] {
				viewController.section = section
			}

			self?.tabBarController.presentViewController(viewController, animated: true, completion: nil)
		}

	}

	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		return self.router.dispatch(url)
	}

}
```

## License

MIT -- see the LICENSE file for more information.
