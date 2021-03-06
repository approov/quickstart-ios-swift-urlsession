// MIT License
//
// Copyright (c) 2016-present, Critical Blue Ltd.
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


class ViewController: UIViewController {
    
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusTextView: UILabel!
    
    var defaultSession = URLSession(configuration: .default)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // check unprotected hello endpoint

    @IBAction func checkHello() {
        let helloURL = URL(string: "https://shapes.approov.io/v1/hello")!
        
        // Display busy screen
        DispatchQueue.main.async {
            self.statusImageView.image = UIImage(named: "approov")
            self.statusTextView.text = "Checking connectivity..."
        }

        let task = defaultSession.dataTask(with: helloURL) { (data, response, error) in
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
                message = "Unknown networking error"
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
    
    // check Approov-protected shapes endpoint

    @IBAction func checkShape() {
        let shapesURL = URL(string: "https://shapes.approov.io/v2/shapes")!

        // Display busy screen
        DispatchQueue.main.async {
            self.statusImageView.image = UIImage(named: "approov")
            self.statusTextView.text = "Checking app authenticity..."
        }
        
        let task = defaultSession.dataTask(with: shapesURL) { (data, response, error) in
            var message: String
            let image: UIImage?
            
            // analyze response
            if (error == nil) {
                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    if code == 200 {
                        // successful http response
                        message = "\(code): Approoved!"
                        // unmarshal the JSON response
                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data!, options: [])
                            let jsonDict = jsonObject as? [String: Any]
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
                                message = "\(code): Approoved: unknown shape '\(shape)'"
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
