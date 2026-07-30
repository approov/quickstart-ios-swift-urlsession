// MIT License
//
// Copyright (c) 2016-present, Approov Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
// (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
// THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

// Note there is NO Approov import and NO Approov-specific session type here: the app uses a
// completely standard URLSession. The Approov auto service layer (initialized in AppDelegate)
// intercepts and protects this traffic automatically.

class ViewController: UIViewController {
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusTextView: UILabel!

    // a plain URLSession — unchanged when adopting Approov with the auto service layer.
    // `lazy` matters: with a main storyboard the view controller (and any stored property
    // initializers) are created BEFORE application(_:didFinishLaunchingWithOptions:) runs, so a
    // non-lazy session would be built before Approov activation and escape interception.
    lazy var defaultSession = URLSession(configuration: .default)

    private let environment = ProcessInfo.processInfo.environment
    private var didRunAutomaticCheck = false

    // A clean checkout uses the public v1 flow and contains no live key. Instrumented runs can
    // select v3/v5 and supply either a test API key or the secure-string placeholder at launch.
    private var currentShapesEndpoint: String {
        environment["SHAPES_ENDPOINT"] ?? "v1"
    }

    private var apiSecretKey: String {
        environment["SHAPES_API_KEY"] ?? "shapes_api_key_placeholder"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Approov initialization and configuration live in AppDelegate: it must run before any
        // URLSession is created so the session's configuration picks up the interception.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Automation hook for headless testing. "hello" exercises a credential-free smoke path;
        // "shape" exercises the configured protected endpoint and key/placeholder.
        guard !didRunAutomaticCheck, let automaticCheck = environment["SHAPES_AUTO_CHECK"] else {
            return
        }
        didRunAutomaticCheck = true
        if automaticCheck.lowercased() == "shape" {
            checkShape()
        } else {
            checkHello()
        }
    }
    
    // Check hello endpoint
    @IBAction func checkHello() {
        DispatchQueue.main.async {
            self.statusImageView.image = UIImage(named: "approov")
            self.statusTextView.text = "Checking connectivity..."
        }
        let helloURL = URL(string: "https://shapes.approov.io/v1/hello")!
        let request = URLRequest(url: helloURL)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            let message: String
            let image: UIImage?
            
            // analyze response
            if (error == nil) {
                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    if code == 200 {
                        // successful http response
                        message = "\(code): OK"
                        image = UIImage(named: "hello")
                    } else {
                        // unexpected http response
                        let reason = HTTPURLResponse.localizedString(forStatusCode: code)
                        message = "\(code): \(reason)"
                        image = UIImage(named: "confused")
                    }
                } else {
                    // not an http response
                    message = "Not an HTTP response"
                    image = UIImage(named: "confused")
                }
            } else {
                // other networking failure
                message = "Networking error: \(error!.localizedDescription)"
                image = UIImage(named: "confused")
            }
            
            NSLog("\(helloURL): \(message)")
            
            // Display the image on screen using the main queue
            DispatchQueue.main.async {
                self.statusImageView.image = image
                self.statusTextView.text = message
            }
        }
        
        task.resume()
    }
    
    
    // Check Approov-protected shapes endpoint
    @IBAction func checkShape() {
        DispatchQueue.main.async {
            self.statusImageView.image = UIImage(named: "approov")
            self.statusTextView.text = "Checking app authenticity..."
        }
        let shapesURL = URL(string: "https://shapes.approov.io/" + currentShapesEndpoint + "/shapes")!
        var request = URLRequest(url: shapesURL)
        request.setValue(apiSecretKey, forHTTPHeaderField: "Api-Key")
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            var message: String
            let image: UIImage?
            
            // analyze response
            if (error == nil) {
                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    if code == 200 {
                        // successful http response
                        message = "\(code)"
                        // unmarshal the JSON response
                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data!, options: [])
                            let jsonDict = jsonObject as? [String: Any]
                            message = (jsonDict!["status"] as! String)
                            let shape = (jsonDict!["shape"] as? String)!.lowercased()
                            switch shape {
                            case "circle":
                                image = UIImage(named: "Circle")
                            case "rectangle":
                                image = UIImage(named: "Rectangle")
                            case "square":
                                image = UIImage(named: "Square")
                            case "triangle":
                                image = UIImage(named: "Triangle")
                            default:
                                message = "\(code): unknown shape '\(shape)'"
                                image = UIImage(named: "confused")
                            }
                        } catch {
                            message = "\(code): Invalid JSON from Shapes response"
                            image = UIImage(named: "confused")
                        }
                    } else {
                        // unexpected http response
                        let reason = HTTPURLResponse.localizedString(forStatusCode: code)
                        message = "\(code): \(reason)"
                        image = UIImage(named: "confused")
                    }
                } else {
                    // not an http response
                    message = "Not an HTTP response"
                    image = UIImage(named: "confused")
                }
            } else {
                // other networking failure
                message = "Networking error: \(error!.localizedDescription)"
                image = UIImage(named: "confused")
            }
            
            NSLog("\(shapesURL): \(message)")

            // Display the image on screen using the main queue
            DispatchQueue.main.async {
                self.statusImageView.image = image
                self.statusTextView.text = message
            }
        }
    
        task.resume()
    }
}
