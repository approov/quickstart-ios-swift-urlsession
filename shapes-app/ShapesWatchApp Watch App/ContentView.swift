//
//  ContentView.swift
//  ShapesApp Watch App
//
//  Created by ivo liondov on 01/02/2024.
//

import SwiftUI
//*** UNCOMMENT THE LINE BELOW FOR APPROOV
//import ApproovURLSession

//*** COMMENT THE LINE BELOW IF USING APPROOV
var defaultSession = URLSession(configuration: .default)

//*** UNCOMMENT THE LINE BELOW FOR APPROOV
//var defaultSession = ApproovURLSession(configuration: .default)

//*** COMMENT THE LINE BELOW TO USE APPROOV API PROTECTION
let currentShapesEndpoint = "v1"
//*** UNCOMMENT THE LINE BELOW TO USE APPROOV API PROTECTION
//let currentShapesEndpoint = "v3"

//*** COMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION
let apiSecretKey = "yXClypapWNHIifHUWmBIyPFAm"

//*** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION
//let apiSecretKey = "shapes_api_key_placeholder"

// The hello url
let helloURL = URL(string: "https://shapes.approov.io/v1/hello")

// The shapes endpoint: /v1/ is unprotected and /v3/ uses protection with Approov
let shapesURL = URL(string: "https://shapes.approov.io/" + currentShapesEndpoint + "/shapes")!

struct ContentView: View {
    
    init(mImage: String, mText: String) {
        self.mImage = mImage
        self.mText = mText
        //*** UNCOMMENT THE LINE BELOW TO USE APPROOV
        //try! ApproovService.initialize(config: "<enter-your-config-string-here>")
        
        //*** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION
        //ApproovService.addSubstitutionHeader(header: "Api-Key", prefix: nil)
    }
    
    @State var mImage: String
    @State var mText: String
    var body: some View {
        VStack {
            Image(mImage, bundle: nil)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200) // Adjust the maxHeight as needed
                            .foregroundStyle(.tint)
            Text(mText)
                .multilineTextAlignment(.center) // Set alignment as needed
                                .lineLimit(nil) // Allow multiline text
            Spacer(minLength: 10)
            HStack {
                Button("Hello", action: {
                    sayHello()
                })
                Spacer()
                Button("Shape", action: {
                    getShape()
                })
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.9), Color.cyan.opacity(0.5)]), startPoint: .top, endPoint: .bottom)) // Red gradient background for HStack
    }
    
    // Update background and message
    func updateBackgroundAndMessage(background: String, message: String, delay: TimeInterval) {
        // Update the UI on the main queue
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            mImage = background
            mText = message
        }
    }
    
    // Check hello endpoint
    func sayHello() {
        let request = URLRequest(url: helloURL!)
        
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            let message: String
            let image: String
            
            // analyze response
            if (error == nil) {
                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    if code == 200 {
                        // successful http response
                        message = "\(code): OK"
                        image = "hello"
                    } else {
                        // unexpected http response
                        let reason = HTTPURLResponse.localizedString(forStatusCode: code)
                        message = "\(code): \(reason)"
                        image = "confused"
                    }
                } else {
                    // not an http response
                    message = "Not an HTTP response"
                    image = "confused"
                }
            } else {
                // other networking failure
                message = "Networking error: \(error!.localizedDescription)"
                image = "confused"
            }
            
            print("\(String(describing: helloURL)): \(message)")
            
            updateBackgroundAndMessage(background: image, message: message, delay: 0)
        }
        
        task.resume()
    } // getHello
    
    // Get a shape
    func getShape() {
        updateBackgroundAndMessage(background: "approov", message: "Checking app ...", delay: 0)
        // We allways set the API key
        var request = URLRequest(url: shapesURL)
        request.setValue(apiSecretKey, forHTTPHeaderField: "Api-Key")
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            var message: String
            var image: String
            
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
                            let responseMessage = (jsonDict!["status"] as! String)
                            message = protectionType(from: responseMessage) ?? responseMessage
                            
                            let shape = (jsonDict!["shape"] as? String)!.lowercased()
                            switch shape {
                            case "circle":
                                image = "Circle"
                            case "rectangle":
                                image = "Rectangle"
                            case "square":
                                image = "Square"
                            case "triangle":
                                image = "Triangle"
                            default:
                                message = "\(code): unknown shape '\(shape)'"
                                image = "confused"
                            }
                        } catch {
                            message = "\(code): Invalid JSON from Shapes response"
                            image = "confused"
                        }
                    } else {
                        // unexpected http response
                        let reason = HTTPURLResponse.localizedString(forStatusCode: code)
                        message = "\(code): \(reason)"
                        image = "confused"
                    }
                } else {
                    // not an http response
                    message = "Not an HTTP response"
                    image = "confused"
                }
            } else {
                // other networking failure
                message = "Networking error: \(error!.localizedDescription)"
                image = "confused"
            }
            
            print("\(shapesURL): \(message)")
            updateBackgroundAndMessage(background: image, message: message, delay: 1)
        }
    
        task.resume()
    } // getShape

    // Extract protection type from return message
    func protectionType(from input: String) -> String? {
        if let startRange = input.range(of: "("), let endRange = input.range(of: ")", range: startRange.upperBound..<input.endIndex) {
            let textInsideParentheses = input[startRange.upperBound..<endRange.lowerBound].trimmingCharacters(in: .whitespaces)
            return textInsideParentheses
        }
        
        return nil
    }
} // Struct

#Preview {
    ContentView(mImage: "approov", mText: "Get Shape")
}











