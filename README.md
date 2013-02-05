# MTStackableNavigationController

`MTStackableNavigationController` aims to be an API-compatible replacement for 
UINavigationController, with special sauce for Facebook / Path style stacked
navigation.

It does some cool things:

* The navigation bar framework works as it does inside a `UINavigationController`
* Your child view controllers don't require any modification to be used with
  this container (other than changing references to `self.navigationController`
  to `self.stackedNavigationController`)
* Because `MTStackableNavigationController` uses proper container view
  controller APIs, all relevant rotation, memory, and view lifecycle messages
  automatically get passed through to child controllers

`MTStackableNavigationController` isn't a panacea; a number of things aren't
perfect:

TBD

## Supported Platforms

iOS 5.0 is a minimum; any release since then is supported. ARC is required (if
you have a need for this project to not require ARC, let me know and I'll fix
you up; I just haven't has a need for it yet).

## Usage

Using `MTStackableNavigationController` is easy. Initialization is identical to
that of the system `UINavigationController` (with the exception that use inside
a storyboard or nib isn't well supported; you can thank Apple for that).

```
TBD

```

The relevant hooks are also in place to allow the placement of
`MTStackableNavigationController` instances in nib/storyboard files (though you
still have to insert child views programmatically; as with all non-system view
containers).

## Contributing

Contributions welcome! Fork this repo and submit a pull request (or just open up
a ticket and I'll see what I can do).
