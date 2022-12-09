# Shapes Example

This quickstart is written specifically for native iOS apps that are written in Swift for making the API calls that you wish to protect with Approov. This quickstart provides a step-by-step example of integrating Approov into an app using a simple `Shapes` example that shows a geometric shape based on a request to an API backend that can be protected with Approov.

## WHAT YOU WILL NEED
* Access to a trial or paid Approov account
* The `approov` command line tool [installed](https://approov.io/docs/latest/approov-installation/) with access to your account
* [Xcode](https://developer.apple.com/xcode/) installed (version 13.4.1 is used in this guide)
* An iOS mobile device or simulator with iOS 10 or higher
* The contents of this repo

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

This checks the connectivity by connecting to the endpoint `https://shapes.approov.io/v1/hello`. Now press the `Shape` button and you will see this (or another shape):

<p>
    <img src="readme-images/shape.png" width="256" title="Shape">
</p>

This contacts `https://shapes.approov.io/v1/shapes` to get the name of a random shape. This endpoint is protected with an API key that is built into the code, and therefore can be easily extracted from the app.

The subsequent steps of this guide show you how to provide better protection, either using an Approov token or by migrating the API key to become an Approov managed secret.

## ADD THE APPROOV SERVICE URLSESSION

The Approov integration is available via the [`Swift Package Manager`](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app). This allows inclusion into the project by simply specifying a dependency in the `File -> Add Packages...` Xcode option if the project is selected:

![Add Packag Dependency](readme-images/AddPackage.png)

Enter the repository`https://github.com/approov/approov-service-urlsession.git` into the search box. You will then have to select the relevant version you wish to use. To do so, select the `Exact Version` option and enter `3.0.3`.

Once you click `Add Package` the last step will confirm the package product and target selection:

![Target Selection](readme-images/target-selection.png)

 The `approov-service-urlsession` is actually an open source wrapper layer that allows you to easily use Approov with `URLSession`. This has a further dependency to the closed source [Approov SDK](https://github.com/approov/approov-ios-sdk).

## ENSURE THE SHAPES API IS ADDED

In order for Approov tokens to be generated for `https://shapes.approov.io/v2/shapes` it is necessary to inform Approov about it:

```
approov api -add shapes.approov.io
```

Tokens for this domain will be automatically signed with the specific secret for this domain, rather than the normal one for your account.

## MODIFY THE APP TO USE APPROOV

Before using Approov you need to import the `ApproovURLSession` Service. In the `ViewController.swift` source file import the service module:

```swift
import ApproovURLSession
```

Find the following line in `ViewController.swift` source file and uncomment it (commenting the previous definition):

```swift
//*** UNCOMMENT THE LINE BELOW FOR APPROOV
var defaultSession = ApproovURLSession(configuration: .default)
```

Now locate and uncomment the line inside the `viewDidLoad` function that initializes the `ApproovService` and remember to add the `config` parameter. The `approov-service-urlsession` needs a configuration string to identify the account associated with the app. You will have received this in your Approov onboarding email (it will be something like `#123456#K/XPlLtfcwnWkzv99Wj5VmAxo4CrU267J1KlQyoz8Qo=`):

```swift
try! ApproovService.initialize(config: "<enter-your-config-string-here>")
```

The `ApproovURLSession` class adds the `Approov-Token` header and also applies pinning for the connections to ensure that no Man-in-the-Middle can eavesdrop on any communication being made.

Lastly, make sure we are using the Approov protected endpoint for the shapes server. Find this line and uncomment it to point to `v3` (commenting the previous definition):

```swift
//*** UNCOMMENT THE LINE BELOW TO USE APPROOV API PROTECTION
let currentShapesEndpoint = "v3"
```

## REGISTER YOUR APP WITH APPROOV

In order for Approov to recognize the app as being valid it needs to be registered with the service. This requires building an `.ipa` file using the `Archive` option of Xcode (this option will not be available if using the simulator). Make sure a `Generic iOS Device` is selected as build destination. This ensures an `embedded.mobileprovision` is included in the application package which is a requirement for the `approov` command line tool. 

![Target Device](readme-images/target-device.png)

We can now build the application by selecting `Product` and then `Archive`. Select the appropriate code signing options and eventually a destination to save the `.ipa` file.

Copy the `ApproovShapes.ipa` file to a convenient working directory. Register the app with Approov:

```
approov registration -add ApproovShapes.ipa
```

## RUNNING THE SHAPES APP WITH APPROOV

Install the `ApproovShapes.ipa` that you just registered on the device. You will need to remove the old app from the device first.

If you are using a simulator you will need to ensure it [always passes](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy) since the simulators are not real devices and you will ne rejected by Approov.

Simply drag the `ipa` file to the device. Alternatively you can select `Window`, then `Devices and Simulators` and after selecting your device click on the small `+` sign to locate the `ipa` archive you would like to install.

![Install IPA Xcode](readme-images/install-ipa.png)

Launch the app and press the `Shape` button. You should now see this (or another shape):

<p>
    <img src="readme-images/shape-approoved.png" width="256" title="Shape Approoved">
</p>

This means that the app is getting a validly signed Approov token to present to the shapes endpoint.

## WHAT IF I DON'T GET SHAPES

If you still don't get a valid shape then there are some things you can try. Remember this may be because the device you are using has some characteristics that cause rejection for the currently set [Security Policy](https://approov.io/docs/latest/approov-usage-documentation/#security-policies) on your account:

* Ensure that the version of the app you are running is exactly the one you registered with Approov.
* If you running the app from a debugger then valid tokens are not issued unless you have ensure your device [always passes](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy).
* Look at the console output from the device using the [Console](https://support.apple.com/en-gb/guide/console/welcome/mac) app from MacOS. This provides console output for a connected simulator or physical device. Select the device and search for `ApproovService` to obtain specific logging related to Approov. This will show lines including the loggable form of any tokens obtained by the app. You can easily [check](https://approov.io/docs/latest/approov-usage-documentation/#loggable-tokens) the validity and find out any reason for a failure.
* You can use a debugger or simulator and get valid Approov tokens on a specific device by ensuring it [always passes](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy). As a shortcut, when you are first setting up, you can add a [device security policy](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy) using the `latest` shortcut as discussed so that the `device ID` doesn't need to be extracted from the logs or an Approov token.
* Consider using an [Annotation Policy](https://approov.io/docs/latest/approov-usage-documentation/#annotation-policies) during development to directly see why the device is not being issued with a valid token.
* Use `approov metrics` to see [Live Metrics](https://approov.io/docs/latest/approov-usage-documentation/#live-metrics) of the cause of failure.
* Inspect any exceptions for additional information

## SHAPES APP WITH SECRETS PROTECTION

This section provides an illustration of an alternative option for Approov protection if you are not able to modify the backend to add an Approov Token check. We are still going to be using `https://shapes.approov.io/v1/shapes/` that simply checks for an API key, so please change back the code so it points to `https://shapes.approov.io/v1/shapes/`.

The `apiSecretKey` variable also needs to be changed as follows, removing the actual API key out of the code. Find this line and uncomment it (commenting the previosu definition):

```swift
//*** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION
let apiSecretKey = "shapes_api_key_placeholder"
```

Next we enable the [Secure Strings](https://approov.io/docs/latest/approov-usage-documentation/#secure-strings) feature:

```
approov secstrings -setEnabled
```

> Note that this command requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

You must inform Approov that it should map `shapes_api_key_placeholder` to `yXClypapWNHIifHUWmBIyPFAm` (the actual API key) in requests as follows:

```
approov secstrings -addKey shapes_api_key_placeholder -predefinedValue yXClypapWNHIifHUWmBIyPFAm
```

> Note that this command also requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

Next we need to inform Approov that it needs to substitute the placeholder value for the real API key on the `Api-Key` header. Find the line below and uncomment it:

```swift
// *** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION
ApproovService.addSubstitutionHeader(header: "Api-Key", prefix: nil)
```

This processes the headers and replaces in the actual API key as required.

Build and run the app again to ensure that the `ApproovShapes.ipa` in the generated build outputs is up to date. You need to register the updated app with Approov. Using the command line register the app with:

```
approov registration -add ApproovShapes.ipa
```
Run the app again without making any changes to the app and press the `Get Shape` button. You should now see this (or another shape):

<p>
    <img src="readme-images/shape.png" width="256" title="Shape">
</p>

This means that the registered app is able to access the API key, even though it is no longer embedded in the app code, and provide it to the shapes request.
