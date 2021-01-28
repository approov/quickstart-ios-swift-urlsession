# Approov Quickstart: iOS Swift URLSession

This quickstart is written specifically for native iOS apps that are written in Swift for making the API calls that you wish to protect with Approov. If this is not your situation then check if there is a more relevant quickstart guide available.

## WHAT YOU WILL NEED
* Access to a trial or paid Approov account
* The `approov` command line tool [installed](https://approov.io/docs/latest/approov-installation/) with access to your account
* [Xcode](https://developer.apple.com/xcode/) version 11 installed (version 11.3.1 is used in this guide)
* The contents of the folder containing this README
* An Apple mobile device with iOS 10 or higher

## WHAT YOU WILL LEARN
* How to integrate Approov into a real app in a step by step fashion
* How to register your app to get valid tokens from Approov
* A solid understanding of how to integrate Approov into your own app that uses Swift
* Some pointers to other Approov features

## RUNNING THE SHAPES APP WITHOUT APPROOV

Open the `ApproovShapes.xcodeproj` project in the `shapes-app` folder using `File->Open` in Xcode. Ensure the `ApproovShapes` project is selected at the top of Xcode's project explorer panel.

Select your codesigning certificate in the `Signing & Capabilities` tab and run the application on your prefered device.

![Codesign App](readme-images/codesign-app.png)

Once the application is running you will see two buttons:

<p>
    <img src="readme-images/app-startup.png" width="256" title="Shapes App Startup">
</p>

Click on the `Hello` button and you should see this:

<p>
    <img src="readme-images/hello-okay.png" width="256" title="Hello Okay">
</p>

This checks the connectivity by connecting to the endpoint `https://shapes.approov.io/v1/hello`. Now press the `Shape` button and you will see this:

<p>
    <img src="readme-images/shapes-bad.png" width="256" title="Shapes Bad">
</p>

This contacts `https://shapes.approov.io/v2/shapes` to get the name of a random shape. It gets the status code 400 (`Bad Request`) because this endpoint is protected with an Approov token. Next, you will add Approov into the app so that it can generate valid Approov tokens and get shapes.

## ADD THE APPROOV SDK

Get the latest Approov SDK (if you are using Windows then substitute `approov` with `approov.exe` in all cases in this quickstart)
```
$ approov sdk -getLibrary approov-sdk.zip
$ unzip approov-sdk.zip
```
In Xcode select `File` and then `Add Files to "ApproovShapes"...` and select the unzipped Approov.framework folder from the previous command:

![Add Files to ApproovShapes](readme-images/add-files-to-approovshapes.png)

Make sure the `Copy items if needed` option and the target `ApproovShapes` are selected. Once the Approov framework appears in the project structure we have to ensure it is signed and embedded in the ApproovShapes binary. To do so, select the target `ApproovShapes` and in the `General` tab scroll to the `Frameworks, Libraries and Embedded Content` section where the `Approov.framework` entry must have `Embed & Sign` selected in the `Embed` column:

![Embed & Sign](readme-images/embed-and-sign.png)

The Approov SDK is now included as a dependency in your project.

## ADD THE APPROOV FRAMEWORK CODE

The `shapes-app`' folder's sub-folder `framework` contains an `ApproovURLSession.swift` file. This provides a wrapper around the Approov SDK itself to make it easier to use with swift's `URLSession` class. In Xcode select `File` and then `Add Files to "ApproovShapes"...` and select the `ApproovURLSession.swift` file:

![Add Swift File](readme-images/add-swift-file.png)

Make sure the `Copy items if needed` option and the target `ApproovShapes` are selected. Your project structure should look like this:

![Final Project View](readme-images/final-project-view.png)

## ENSURE THE SHAPES API IS ADDED

In order for Approov tokens to be generated for `https://shapes.approov.io/v2/shapes` it is necessary to inform Approov about it. If you are using a demo account this is unnecessary as it is already set up. For a trial account do:
```
$ approov api -add shapes.approov.io
```
Tokens for this domain will be automatically signed with the specific secret for this domain, rather than the normal one for your account.

## SETUP YOUR APPROOV CONFIGURATION

The Approov SDK needs a configuration string to identify the account associated with the app. Obtain it using:
```
$ approov sdk -getConfig approov-initial.config
```
We need to add the text file to our project and ensure it gets copied to the root directory of our app upon installation. In Xcode select `File`, then `Add Files to "ApproovShapes"...` and select the `approov-initial.config` file. Make sure the `Copy items if needed` option and the target `ApproovShapes` are selected. Your final project structure should look like this:

![Initial Config String](readme-images/initial-config.png)

 Verify that the `Copy Bundle Resources` phase of the `Build Phases` tab includes the `approov-initial.config` in its list, otherwise it will not get copied during installation.

## MODIFY THE APP TO USE APPROOV

Find the following line in `ViewController.swift` source file:
```swift
var defaultSession = URLSession(configuration: .default)
```
Replace `URLSession` with `ApproovURLSession`:
```swift
var defaultSession = ApproovURLSession(configuration: .default)
```

The `ApproovURLSession` class adds the `Approov-Token` header and also applies pinning for the connections to ensure that no Man-in-the-Middle can eavesdrop on any communication being made. 

## REGISTER YOUR APP WITH APPROOV

In order for Approov to recognize the app as being valid it needs to be registered with the service. This requires building an `.ipa` file either using the `Archive` option of Xcode (this option will not be avaialable if using the simulator) or building the app and then creating a compressed zip file and renaming it. We use the second option for which we have to make sure a `Generic iOS Device` is selected as build destination. This ensures an `embedded.mobileprovision` is included in the application package which is a requirement for the `approov` command line tool. 

![Target Device](readme-images/target-device.png)

We can now build the application by selecting `Product` and then `Build`. Allow the build to finish. In the project explorer panel of Xcode, under the `Products` folder right-click on `ApproovShapes.app` and select the option `Show in Finder` which will show the application in the build directory.

![Build app](readme-images/build-app.png)

The build folder will look something like this:

![Build Folder](readme-images/build-folder.png)

Create a new folder, name it `Payload` and move the `ApproovShapes` application to the newly created `Payload` directory:

![Payload Folder](readme-images/payload-folder.png)

Right-click on the `Payload` folder and select `Compress "Payload"`. This will produce a `Payload.zip` file. Rename the `Payload.zip` file to `ApproovShapes.ipa` (note the file extension change).

![Build IPA Result](readme-images/build-ipa-result.png)

Copy the `ApproovShapes.ipa` file to a convenient working directory. Register the app with Approov:
```
$ approov registration -add ApproovShapes.ipa
registering app Approov Shapes
SW3NvhtzHajAJIOT6vJyvww/KgORdIGaWqktE24a+as=ios.swift.shapes.demo.approov.io-1.0[1]-4289  SDK:iOS(2.2.3)
registration successful
```

## RUNNING THE SHAPES APP WITH APPROOV

Install the `ApproovShapes.ipa` that you just registered on the device. You will need to remove the old app from the device first.
If using Mac OS Catalina, simply drag the `ipa` file to the device. Alternatively you can select `Window`, then `Devices and Simulators` and after selecting your device click on the small `+` sign to locate the `ipa` archive you would like to install.

![Install IPA Xcode](readme-images/install-ipa.png)

Launch the app and press the `Shape` button. You should now see this (or another shape):

<p>
    <img src="readme-images/shapes-good.jpeg" width="256" title="Shapes Good">
</p>

This means that the app is getting a validly signed Approov token to present to the shapes endpoint.

## WHAT IF I DON'T GET SHAPES

If you still don't get a valid shape then there are some things you can try. Remember this may be because the device you are using has some characteristics that cause rejection for the currently set [Security Policy](https://approov.io/docs/latest/approov-usage-documentation/#security-policies) on your account:

* Ensure that the version of the app you are running is exactly the one you registered with Approov.
* If you running the app from a debugger then valid tokens are not issued.
* Look at the [`syslog`](https://developer.apple.com/documentation/os/logging) output from the device. Information about any Approov token fetched or an error is printed, e.g. `Approov: Approov token for host: https://approov.io : {"anno":["debug","allow-debug"],"did":"/Ja+kMUIrmd0wc+qECR0rQ==","exp":1589484841,"ip":"2a01:4b00:f42d:2200:e16f:f767:bc0a:a73c","sip":"YM8iTv"}`. You can easily [check](https://approov.io/docs/latest/approov-usage-documentation/#loggable-tokens) the validity.

If you have a trial (as opposed to demo) account you have some additional options:
* Consider using an [Annotation Policy](https://approov.io/docs/latest/approov-usage-documentation/#annotation-policies) during development to directly see why the device is not being issued with a valid token.
* Use `approov metrics` to see [Live Metrics](https://approov.io/docs/latest/approov-usage-documentation/#live-metrics) of the cause of failure.
* You can use a debugger and get valid Approov tokens on a specific device by [whitelisting](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy).

## CHANGING YOUR OWN APP TO USE APPROOV

### Configuration

This quick start guide has taken you through the steps of adding Approov to the shapes demonstration app. If you have you own app using Swift you can follow exactly the same steps to add Approov. Take note of the dependency discussion [here](https://approov.io/docs/v2.2/approov-usage-documentation/#importing-the-approov-sdk-into-ios-xcode).

### API Domains
Remember you need to [add](https://approov.io/docs/latest/approov-usage-documentation/#adding-api-domains) all of the API domains that you wish to send Approov tokens for. You can still use the Approov `swift` client for other domains, but no `Approov-Token` will be sent. 

### Preferences
An Approov app automatically downloads any new configurations of APIs and their pins that are available. These are stored in the [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) for the app in a preference key `approov-dynamic`. You can store the preferences differently by modifying or overriding the methods `storeDynamicConfig` and `readDynamicApproovConfig` in `ApproovURLSession.swift`.

### Changing Your API Backend
The Shapes example app uses the API endpoint `https://shapes.approov.io/v2/shapes` hosted on Approov's servers. If you want to integrate Approov into your own app you will need to [integrate](https://approov.io/docs/latest/approov-usage-documentation/#backend-integration) an Approov token check. Since the Approov token is simply a standard [JWT](https://en.wikipedia.org/wiki/JSON_Web_Token) this is usually straightforward. [Backend integration](https://approov.io/docs/latest/approov-integration-examples/backend-api/) examples provide a detailed walk-through for particular languages. Note that the default header name of `Approov-Token` can be modified by changing the variable `approovTokenPrefix`, i.e. in integrations that need to be prefixed with `Bearer`, like the `Authorization` header. It is also possible to change the `Approov-Token` header completely by overriding the contents of `kApproovTokenHeader` variable. 

### Token Prefetching
If you wish to reduce the latency associated with fetching the first Approov token, then a call to `ApproovSDK.prefetchApproovToken` can be made immediately after initialization of the Approov SDK. This initiates the process of fetching an Approov token as a background task, so that a cached token is available immediately when subsequently needed, or at least the fetch time is reduced. Note that if this feature is being used with [Token Binding](https://approov.io/docs/latest/approov-usage-documentation/#token-binding) then the binding must be set prior to the prefetch, as changes to the binding invalidate any cached Approov token.

## NEXT STEPS

This quick start guide has shown you how to integrate Approov with your existing app. Now you might want to explore some other Approov features:

* Managing your app [registrations](https://approov.io/docs/latest/approov-usage-documentation/#managing-registrations)
* Manage the [pins](https://approov.io/docs/latest/approov-usage-documentation/#public-key-pinning-configuration) on the API domains to ensure that no Man-in-the-Middle attacks on your app's communication are possible.
* Update your [Security Policy](https://approov.io/docs/latest/approov-usage-documentation/#security-policies) that determines the conditions under which an app will be given a valid Approov token.
* Learn how to [Manage Devices](https://approov.io/docs/latest/approov-usage-documentation/#managing-devices) that allows you to change the policies on specific devices.
* Understand how to issue and revoke your own [Management Tokens](https://approov.io/docs/latest/approov-usage-documentation/#management-tokens) to control access to your Approov account.
* Use the [Metrics Graphs](https://approov.io/docs/latest/approov-usage-documentation/#metrics-graphs) to see live and accumulated metrics of devices using your account and any reasons for devices being rejected and not being provided with valid Approov tokens. You can also see your billing usage which is based on the total number of unique devices using your account each month.
* Use [Service Monitoring](https://approov.io/docs/latest/approov-usage-documentation/#service-monitoring) emails to receive monthly (or, optionally, daily) summaries of your Approov usage.
* Consider using [Token Binding](https://approov.io/docs/latest/approov-usage-documentation/#token-binding). The property `ApproovSDK.bindHeader` takes the name of the header holding the value to be bound. This only needs to be called once but the header needs to be present on all API requests using Approov.
* Investigate other advanced features, such as [Offline Security Mode](https://approov.io/docs/latest/approov-usage-documentation/#offline-security-mode) and [DeviceCheck Integration](https://approov.io/docs/latest/approov-usage-documentation/#apple-devicecheck-integration).



