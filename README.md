# MTStackableNavigationController

`MTStackableNavigationController` aims to be an API-compatible replacement for 
`UINavigationController`, with special sauce for Facebook / Path style stacked
navigation. In contrast to most of the other view controller projects based on
this paradigm, `MTStackableNavigationController` is targeted exclusively for use
as a direct replacement for `UINavigationController`; layered navigation and
deck style interaction are already done well by other controllers.

`MTStackableNavigationController` does some cool things:

* The navigation bar framework works as it does inside
  a `UINavigationController`. You can define bar button items, titles, and other
  properties on your controller's `navigationItem` just as you do with
  a conventional `UINavigationController` and they'll be presented
  appropriately.
* Your child view controllers don't require any modification to be used with
  this container (other than changing references to `self.navigationController`
  to `self.stackedNavigationController`). The API methods (and the calling sequence of
  the various view lifecycle messages such as `viewWillAppear` et al.) are
  identical to those of `UINavigationController`.
* View controllers can customize their presentation by configuring their `stackableNavigationItem` property.

`MTStackableNavigationController` is still under active development and
a number of features aren't done yet (but they will be soon). A rough plan of
the near future looks like this:

### Planned for 0.2

* Gesture support (along with configuration parameters to control it)

### Planned for 0.3

* Better support for toolbars on contained view controllers
* More complete support for seldom used properties of `navigationItem`
* Comprehensive test suite to stay in lock-step with subtle timing changes of
  view lifecycle messages in `UINavigationController`

### Planned for 0.4

* Support for subview layouts and reizing on rotation (currently, only portrait
  is supported)
* Proper resizing of navigation bars and tool bars on rotation
* iPad support (this is a low priority for me and may get bumped. There are
  plenty of other view controller projects out there that are probably better
  choices for iPad development anyway)

### Planned for 0.5

* Closer adherence to off-screen call semantics of `UINavigationController`,
  which does some fanciness to ensure that lifecycle messages aren't improperly sent
  during controller setup while the controller hasn't been added to the
  on-screen hierarchy yet. Implementing this isn't entirely trivial (and is
  a low priority for me ATM) so I'm holding off on it until later.

## Supported Platforms

iOS 5.0 is a minimum; any release since then is supported. ARC is required (if
you have a need for this project to not require ARC, let me know and I'll fix
you up; I just haven't has a need for it yet). Note that `UINavigationController`
has slightly changed which lifecycle messages are sent (and in which order) since
iOS 5.0; `MTStackableNavigationController` mimics the semantics of iOS 6.1 in this
regard.

## Usage

Using `MTStackableNavigationController` is easy. Initialization is identical to
that of the system `UINavigationController` (with the exception that use inside
a storyboard or nib isn't perfectly supported; see below for more info). See the
included `MTStackableNavigationControllerDemo` project to see a usage example of
using `MTStackableNavigationController` without storyboards.

### Using MTStackableNavigationController with storyboards

You're free to create instances of `MTStackableNavigationController` from inside
a storyboard, with some limitations. Most notably, you'll need to wire up your root view controller in code,
since Apple doesn't allow third party view controllers to declare Relationship
segues inside storyboards. 

This project includes a custom segue (`MTStackableNavigationPushSegue`) which
performs the equivalent of a `UINavigationController`'s push segue. Using this
custom segue, you can realize most of the navigational benefit of storyboards
while still using `MTStackableNavigationController`. Here's how:

1. Create your storyboard as normal, making your storyboard's initial view
controller be your top-level **contained** view (instead of the typical approach of
your initial view controller being an instance of the **container** `UINavigationController`).

2. Remove any `Main Storyboard` entires from your application's `Info.plist`
file. We'll be creating your `UIWindow` and initial view controller in our delegate.

3. Create an instance of `MTStackableNavigationController` inside your app
delegate and populate it with your storyboard's initial view controller like so:

        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
          self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

          UIViewController *topLevelController = [[UIStoryboard storyboardWithName:@"YourStoryboardFile" bundle:[NSBundle mainBundle]] instantiateInitialViewController];

          MTStackableNavigationController *stackableNavigationController = [[MTStackableNavigationController alloc] initWithRootViewController:topLevelController];

          self.window.rootViewController = stackableNavigationController;
          [self.window makeKeyAndVisible];
          return YES;
        }

4. Within your storyboard, use custom segues based on `MTStackableNavigationPushSegue` to navigate between scenes.

## Contributing

Contributions welcome! Fork this repo and submit a pull request (or just open up
a ticket and I'll see what I can do).
