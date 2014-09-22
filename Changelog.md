## 0.4.7

* Quell Xcode 6 warning

## 0.4.6

* Pops now pop reveals (if one is in progress). Note that this implies that
  pops set isRevealing to NO
* Pops done via a back button now pop the stack to that controllers parent
  (for example, in the case where a revealed view controller's back button
  is pushed, the stack is popped to the revealed controller's parent, popping
  both the top and the revealed view controller).

## 0.4.5

* Add a flag to make the display of navigation bar optional on a per VC basis

## 0.4.4

* Lower the amount of pan required to end a reveal
* Ensure that a view controller has its frame set before calling viewWillAppear
  on it

## 0.4.3

* Changes to work better with UAppearance defaults on UINavigationBar
* Resize content view if navigation bar is translucent
* Embed content inside a contentView, to align with frame behaviour of
  UINavigationController

## 0.4.2

* Fix appearance issues when new view controllers have exising frames

## 0.4.1

* Add support for popping and replacing child controller in expose mode
* Shadow tweaks during transitions

## 0.4.0

* Clamp attempts to pan views offscreen
* Exposed controllers now resize to their exposed widths
* Shadow visual tweaks
* Add support for nav bar tinting and styling

## 0.3.0

* Add ability to reveal the next-to-top controller in the stack
* Tweak how far controllers need to be panned to pop / end a reveal
* Start using MTCollectionOperators for set operations internally

## 0.2.0

* Switch to MIT license
* Gesture support
* Lots of internal refactoring to more clearly separate maintenance of the view
  controller hierarchy from the on-screen view hierarchy. The code should be
  much cleaner, easier to read, and easier to keep in sync with
  UINavigationController as a result

## 0.1.0

* Initial release
