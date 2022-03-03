Node.js for iOS
====================================

This is the main repository for Node.js for iOS, a toolkit for integrating Node.js into iOS applications. It was heavily inspired by [Node.js for Mobile Apps](https://code.janeasystems.com/nodejs-mobile).

## Project Goals

1. To provide the fixes necessary to run Node.js on iOS devices.
1. To diverge as little as possible from nodejs/node, while fulfilling goal (1).

## Download
Binaries for iOS are available at https://github.com/agarcia17/node-ios/releases.

## Documentation
***Disclaimer:***  documentation found in this repository is currently unchanged from the parent repository and may only be applicable to upstream node.

## Build Instructions

### Prerequisites to build the iOS .framework library on macOS:

#### Xcode 11 with Command Line Tools

Install Xcode 11 or higher, from the App Store, and then install the Command Line Tools by running the following command:

```sh
xcode-select --install
```

That installs `git`, as well.

#### CMake

To install `CMake`, you can use a package installer like [Homebrew](https://brew.sh/).

First, install `HomeBrew`, if you don't have it already.

```sh
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, use it to install `CMake`:

```sh
brew install cmake
```

### Building the iOS .framework library on macOS:

#### 1) Clone this repo and check out the `mobile-master` branch:

```sh
git clone https://github.com/agarcia17/node-ios.git
cd node-ios
git checkout ios/master
```

#### 2) Run the helper script:

```sh
./tools/ios_framework_prepare.sh
```

That will configure `gyp` to build Node.js and its dependencies as static libraries for iOS on the arm64 and x64 architectures, using the `V8` engine with JIT disabled. The script copies those libraries to `tools/ios-framework/bin/arm64` and `tools/ios-framework/bin/x64`, respectively. It also merges them into static libraries that contain strips for both architectures, which will be placed in `tools/ios-framework/bin` and used by the `tools/ios-framework/NodeMobile.xcodeproj` Xcode project.

The helper script builds the `tools/ios-framework/NodeMobile.xcodeproj` Xcode project into three frameworks:
  - The framework to run on iOS devices: `out_ios/Release-iphoneos/NodeMobile.framework`
  - The framework to run on the iOS simulator: `out_ios/Release-iphonesimulator/NodeMobile.framework`
  - The universal framework, that runs on iOS devices and simulators: `out_ios/Release-universal/NodeMobile.framework`

While the universal framework is useful for faster Application development, due to supporting both iOS devices and simulators, frameworks containing simulator strips will not be accepted on the App Store. Before trying to submit your application, it would be advisable to use the `Release-iphoneos/NodeMobile.framework` in your submission archive or strip the x64 slices from the universal framework's binaries before submitting.

## Running tests
Please see [TESTING.md](./TESTING.md).
