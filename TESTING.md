# Running the Node.js tests in Node.js for iOS

This document describes how to run the Node.js tests for testing the node-ios runtime on iOS. Currently, the tests can only be run on physical devices, not simulators.

The Node.js tests expect to run the Node.js runtime as if it was a standalone executable running on the same machine. To get around this, iOS applications were developed to use the node-ios library and behave like a desktop standalone application, paired with "proxy" scripts that are called by `tools/test.py` as if they were the actual desktop node application and start the iOS applications to run the selected tests and return the results.

Some tests depend on the ability of node to spawn new processes / fork the current process, which is not supported in `node-ios`, so those tests are skipped, alongside tests for other functionalities not currently supported. Tests that are expected to fail are also currently skipped so we can use the current tests as a regression baseline.

## iOS

### iOS prerequisites

You'll need a macOS development machine, an iOS arm64 physical device running iOS 11.0 or greater and a valid iOS Development certificate installed.

iOS tests depend on the [`ios-deploy` tool](https://github.com/phonegap/ios-deploy) for installing and running the test app. You can install it by using npm:
```sh
npm install -g ios-deploy@latest
```

You'll need to build node-ios, so [its prerequisites should also be installed on your system.](./README.md#prerequisites-to-build-the-ios-framework-library-on-macos)

### Build and install the iOS test app

Build [node-ios](./README.md#building-the-ios-framework-library-on-macos):
```sh
./tools/ios_framework_prepare.sh
```

Connect the iOS device on which you intend to run tests, and make sure its screen stays unlocked.

Sign the `tools/mobile-test/ios/testnode/testnode.xcodeproj` in Xcode to be able to run on your target device. In the project settings (click on the project main node), in the `Signing` portion of the `General` tab, select a valid Team and handle the provisioning profile creation/update. If you get an error that the bundle identifier cannot be used, you can simply change the bundle identifier to a unique string by appending a few characters to it.

Run the helper script to build and install the iOS test application. It will also run the application on the device to copy the tests to the iOS application's documents path:
```sh
./tools/mobile-test/ios/prepare-ios-tests.sh
```

This should be done the first time you run the tests and be repeated any time you change any of the tests or rebuild node-ios.

If you have more than one device connected to the development machine you can use the environment variable `DEVICE_ID` to select the device you want to run the tests on. Start by listing the devices:
```sh
ios-deploy --detect
```
and then run the helper script setting `DEVICE_ID` to the device id you intend on using:
```sh
DEVICE_ID=1234567890abcdef123456789abcdef987654321 ./tools/mobile-test/ios/prepare-ios-tests.sh
```

### Run test suites on an iOS device

Connect the iOS device on which you intend to run tests, and make sure its screen stays unlocked.

You can run the Node.js test scripts in iOS by calling `./tools/test.py` with `--arch ios`. Here's an example to run the `parallel`, `sequential` and `message` test suites:
```sh
./tools/test.py --report --flaky-tests=skip --arch ios parallel sequential message
```

While the tests are running, you will see the test application being repeatedly restarted on your test device.

If you have more than one device connected to the development machine you can use the environment variable `DEVICE_ID` to select the device you want to run the tests on. Start by listing the devices:
```sh
ios-deploy --detect
```
and then run the tests setting `DEVICE_ID` to the device id you intend on using:
```sh
DEVICE_ID=1234567890abcdef123456789abcdef987654321 ./tools/test.py --report --flaky-tests=skip --arch ios parallel sequential message
```
