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


import Foundation
import Approov
import CommonCrypto

fileprivate enum ApproovTokenNetworkFetchDecision {
    case ShouldProceed
    case ShouldRetry
    case ShouldFail
}
fileprivate struct ApproovData {
    var request:URLRequest
    var decision:ApproovTokenNetworkFetchDecision
    var sdkMessage:String
    var error:Error?
}

public class ApproovURLSession: NSObject {
    
    // URLSession
    var urlSession:URLSession
    // URLSessionConfiguration
    var urlSessionConfiguration:URLSessionConfiguration
    // URLSessionDelegate
    var urlSessionDelegate:URLSessionDelegate?
    // The delegate queue
    var delegateQueue:OperationQueue?
    // The ApproovSDK handle
    let approovSDK = ApproovSDK.sharedInstance
    
    /*
     *  URLSession initializer
     *  https://developer.apple.com/documentation/foundation/urlsession/1411597-init
     */
    public init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) {
        self.urlSessionConfiguration = configuration
        self.urlSessionDelegate = ApproovURLSessionDataDelegate(with: delegate)
        self.delegateQueue = delegateQueue
        // Set as URLSession delegate our implementation
        self.urlSession = URLSession(configuration: configuration, delegate: urlSessionDelegate, delegateQueue: delegateQueue)
        super.init()
    }
    
    /*
     *  URLSession initializer
     *   https://developer.apple.com/documentation/foundation/urlsession/1411474-init
     */
    public convenience init(configuration: URLSessionConfiguration) {
        self.init(configuration: configuration, delegate: nil, delegateQueue: nil)
    }
    
    // MARK: URLSession dataTask
    /*  Creates a task that retrieves the contents of the specified URL
     *  https://developer.apple.com/documentation/foundation/urlsession/1411554-datatask
     */
    func dataTask(with url: URL) -> URLSessionDataTask {
        return dataTask(with: URLRequest(url: url))
    }
    
    /*  Creates a task that retrieves the contents of a URL based on the specified URL request object
     *  https://developer.apple.com/documentation/foundation/urlsession/1410592-datatask
     */
    func dataTask(with request: URLRequest) -> URLSessionDataTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        var sessionDataTask:URLSessionDataTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                sessionDataTask = self.urlSession.dataTask(with: approovData.request)
            case .ShouldRetry:
                 // We create a task and cancel it immediately
                 sessionDataTask = self.urlSession.dataTask(with: approovData.request)
                 sessionDataTask!.cancel()
                // We should retry doing a fetch after a user driven event
                // Tell the delagate we are marking the session as invalid
                 self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
            default:
                // We create a task and cancel it immediately
                 sessionDataTask = self.urlSession.dataTask(with: approovData.request)
                 sessionDataTask!.cancel()
                // Tell the delagate we are marking the session as invalid
                 self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
        }// switch
        return sessionDataTask!
    }
    
    /*  Creates a task that retrieves the contents of the specified URL, then calls a handler upon completion
     *  https://developer.apple.com/documentation/foundation/urlsession/1410330-datatask
     */
    public func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return dataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    /*  Creates a task that retrieves the contents of a URL based on the specified URL request object, and calls a handler upon completion
     *  https://developer.apple.com/documentation/foundation/urlsession/1407613-datatask
     */
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        // The returned task
        var task:URLSessionDataTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                task = self.urlSession.dataTask(with: approovData.request) { (data, response, error) -> Void in
                    // Invoke completition handler
                    completionHandler(data,response,error)
                }
            case .ShouldRetry:
                // We should retry doing a fetch after a user driven event
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.dataTask(with: approovData.request) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
            default:
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.dataTask(with: approovData.request) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
        }// switch
    return task!
    }// func
    
    // MARK: URLSession downloadTask
    /*  Creates a download task that retrieves the contents of the specified URL and saves the results to a file
     *  https://developer.apple.com/documentation/foundation/urlsession/1411482-downloadtask
     */
    func downloadTask(with url: URL) -> URLSessionDownloadTask {
        return downloadTask(with: URLRequest(url: url))
    }
    
    /*  Creates a download task that retrieves the contents of a URL based on the specified URL request object
     *  and saves the results to a file
     *  https://developer.apple.com/documentation/foundation/urlsession/1411481-downloadtask
     */
    func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        var sessionDownloadTask:URLSessionDownloadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                sessionDownloadTask = self.urlSession.downloadTask(with: approovData.request)
            case .ShouldRetry:
                 // We create a task and cancel it immediately
                 sessionDownloadTask = self.urlSession.downloadTask(with: approovData.request)
                 sessionDownloadTask!.cancel()
                // We should retry doing a fetch after a user driven event
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
            default:
                // We create a task and cancel it immediately
                 sessionDownloadTask = self.urlSession.downloadTask(with: approovData.request)
                 sessionDownloadTask!.cancel()
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
        }// switch
        return sessionDownloadTask!
    }
    
    /*  Creates a download task that retrieves the contents of the specified URL, saves the results to a file,
     *  and calls a handler upon completion
     *  https://developer.apple.com/documentation/foundation/urlsession/1411608-downloadtask
     */
    func downloadTask(with: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return downloadTask(with: URLRequest(url: with), completionHandler: completionHandler)
    }
    
    /*  Creates a download task that retrieves the contents of a URL based on the specified URL request object,
     *  saves the results to a file, and calls a handler upon completion
     *
     */
    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        // The returned task
        var task:URLSessionDownloadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                task = self.urlSession.downloadTask(with: approovData.request) { (data, response, error) -> Void in
                    // Invoke completition handler
                    completionHandler(data,response,error)
                }
            case .ShouldRetry:
                // We should retry doing a fetch after a user driven event
                // Create the early response and invoke callback with custom error
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.downloadTask(with: approovData.request) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
            default:
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.downloadTask(with: approovData.request) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
        }// switch
    return task!
    }
    
    /*  Creates a download task to resume a previously canceled or failed download
     *  https://developer.apple.com/documentation/foundation/urlsession/1409226-downloadtask
     *  NOTE: this call is not protected by Approov
     */
    func downloadTask(withResumeData: Data) -> URLSessionDownloadTask {
        return self.urlSession.downloadTask(withResumeData: withResumeData)
    }
    
    /*  Creates a download task to resume a previously canceled or failed download and calls a handler upon completion
     *  https://developer.apple.com/documentation/foundation/urlsession/1411598-downloadtask
     *  NOTE: this call is not protected by Approov
     */
    func downloadTask(withResumeData: Data, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return self.urlSession.downloadTask(withResumeData: withResumeData, completionHandler: completionHandler)
    }
    
    // MARK: Upload Tasks
    /*  Creates a task that performs an HTTP request for the specified URL request object and uploads the provided data
     *  https://developer.apple.com/documentation/foundation/urlsession/1409763-uploadtask
     */
    func uploadTask(with request: URLRequest, from: Data) -> URLSessionUploadTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        var sessionUploadTask:URLSessionUploadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                sessionUploadTask = self.urlSession.uploadTask(with: approovData.request, from: from)
            case .ShouldRetry:
                 // We create a task and cancel it immediately
                 sessionUploadTask = self.urlSession.uploadTask(with: approovData.request, from: from)
                 sessionUploadTask!.cancel()
                // We should retry doing a fetch after a user driven event
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
            default:
                // We create a task and cancel it immediately
                 sessionUploadTask = self.urlSession.uploadTask(with: approovData.request, from: from)
                 sessionUploadTask!.cancel()
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
        }// switch
        return sessionUploadTask!
    }
    
    /*  Creates a task that performs an HTTP request for the specified URL request object, uploads the provided data,
     *  and calls a handler upon completion
     *  https://developer.apple.com/documentation/foundation/urlsession/1411518-uploadtask
     */
    func uploadTask(with request: URLRequest, from: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        // The returned task
        var task:URLSessionUploadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                task = self.urlSession.uploadTask(with: approovData.request, from: from) { (data, response, error) -> Void in
                    // Invoke completition handler
                    completionHandler(data,response,error)
                }
            case .ShouldRetry:
                // We should retry doing a fetch after a user driven event
                // Create the early response and invoke callback with custom error
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.uploadTask(with: approovData.request, from: from) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
            default:
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.uploadTask(with: approovData.request, from: from) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
        }// switch
        return task!
    }
    
    /*  Creates a task that performs an HTTP request for uploading the specified file
     *  https://developer.apple.com/documentation/foundation/urlsession/1411550-uploadtask
     */
    func uploadTask(with request: URLRequest, fromFile: URL) -> URLSessionUploadTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        var sessionUploadTask:URLSessionUploadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                sessionUploadTask = self.urlSession.uploadTask(with: approovData.request, fromFile: fromFile)
            case .ShouldRetry:
                 // We create a task and cancel it immediately
                 sessionUploadTask = self.urlSession.uploadTask(with: approovData.request, fromFile: fromFile)
                 sessionUploadTask!.cancel()
                // We should retry doing a fetch after a user driven event
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
            default:
                // We create a task and cancel it immediately
                 sessionUploadTask = self.urlSession.uploadTask(with: approovData.request, fromFile: fromFile)
                 sessionUploadTask!.cancel()
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
        }// switch
        return sessionUploadTask!
    }
    
    /*  Creates a task that performs an HTTP request for the specified URL request object, uploads the provided data,
     *  and calls a handler upon completion
     *  https://developer.apple.com/documentation/foundation/urlsession/1411518-uploadtask
     */
    func uploadTask(with request: URLRequest, fromFile: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        let userRequest = addUserHeadersToRequest(request: request)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        // The returned task
        var task:URLSessionUploadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                task = self.urlSession.uploadTask(with: approovData.request, fromFile: fromFile) { (data, response, error) -> Void in
                    // Invoke completition handler
                    completionHandler(data,response,error)
                }
            case .ShouldRetry:
                // We should retry doing a fetch after a user driven event
                // Create the early response and invoke callback with custom error
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.uploadTask(with: approovData.request, fromFile: fromFile) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
            default:
                completionHandler(nil,nil,approovData.error)
                // Initialize a URLSessionDataTask object
                task = self.urlSession.uploadTask(with: approovData.request, fromFile: fromFile) { (data, response, error) -> Void in
                }
                // We cancel the connection and return the task object at end of function
                task?.cancel()
        }// switch
        return task!
    }
    
    /*  Creates a task that performs an HTTP request for uploading data based on the specified URL request
     *  https://developer.apple.com/documentation/foundation/urlsession/1410934-uploadtask
     */
    func uploadTask(withStreamedRequest: URLRequest) -> URLSessionUploadTask {
        let userRequest = addUserHeadersToRequest(request: withStreamedRequest)
        let approovData = approovSDK.fetchApproovToken(request: userRequest)
        var sessionUploadTask:URLSessionUploadTask?
        switch approovData.decision {
            case .ShouldProceed:
                // Go ahead and make the API call with the provided request object
                sessionUploadTask = self.urlSession.uploadTask(withStreamedRequest: approovData.request)
            case .ShouldRetry:
                 // We create a task and cancel it immediately
                 sessionUploadTask = self.urlSession.uploadTask(withStreamedRequest: approovData.request)
                 sessionUploadTask!.cancel()
                // We should retry doing a fetch after a user driven event
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
            default:
                // We create a task and cancel it immediately
                 sessionUploadTask = self.urlSession.uploadTask(withStreamedRequest: approovData.request)
                 sessionUploadTask!.cancel()
                // Tell the delagate we are marking the session as invalid
                self.urlSessionDelegate?.urlSession?(self.urlSession, didBecomeInvalidWithError: approovData.error)
        }// switch
        return sessionUploadTask!
    }
    
    
    // MARK: Managing the Session
    /*  Invalidates the session, allowing any outstanding tasks to finish
     *  https://developer.apple.com/documentation/foundation/urlsession/1407428-finishtasksandinvalidate
     */
    func finishTasksAndInvalidate(){
        self.urlSession.finishTasksAndInvalidate()
    }
    
    /*  Flushes cookies and credentials to disk, clears transient caches, and ensures that future requests
     *  occur on a new TCP connection
     *  https://developer.apple.com/documentation/foundation/urlsession/1411622-flush
     */
    func flush(completionHandler: @escaping () -> Void){
        self.urlSession.flush(completionHandler: completionHandler)
    }
    
    /*  Asynchronously calls a completion callback with all data, upload, and download tasks in a session
     *  https://developer.apple.com/documentation/foundation/urlsession/1411578-gettaskswithcompletionhandler
     */
    func getTasksWithCompletionHandler(_ completionHandler: @escaping ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask]) -> Void) {
        self.urlSession.getTasksWithCompletionHandler(completionHandler)
    }
    
    /*  Asynchronously calls a completion callback with all tasks in a session
     *  https://developer.apple.com/documentation/foundation/urlsession/1411618-getalltasks
     */
    func getAllTasks(completionHandler: @escaping ([URLSessionTask]) -> Void) {
        self.urlSession.getAllTasks(completionHandler: completionHandler)
    }
    
    /*  Cancels all outstanding tasks and then invalidates the session
     *  https://developer.apple.com/documentation/foundation/urlsession/1411538-invalidateandcancel
     */
    func invalidateAndCancel() {
        self.urlSession.invalidateAndCancel()
    }
    
    /*  Empties all cookies, caches and credential stores, removes disk files, flushes in-progress downloads to disk,
     *  and ensures that future requests occur on a new socket
     *  https://developer.apple.com/documentation/foundation/urlsession/1411479-reset
     */
    func reset(completionHandler: @escaping () -> Void) {
        self.urlSession.reset(completionHandler: completionHandler)
    }
    
    // MARK: Instance methods
    
    /*  Creates a WebSocket task for the provided URL
     *  https://developer.apple.com/documentation/foundation/urlsession/3181171-websockettask
     */
    @available(iOS 13.0, *)
    func webSocketTask(with: URL) -> URLSessionWebSocketTask {
        self.urlSession.webSocketTask(with: with)
    }
    
    /*  Creates a WebSocket task for the provided URL request
     *  https://developer.apple.com/documentation/foundation/urlsession/3235750-websockettask
     */
    @available(iOS 13.0, *)
    func webSocketTask(with: URLRequest) -> URLSessionWebSocketTask {
        self.urlSession.webSocketTask(with: with)
    }
    
    /*  Creates a WebSocket task given a URL and an array of protocols
     *  https://developer.apple.com/documentation/foundation/urlsession/3181172-websockettask
     */
    @available(iOS 13.0, *)
    func webSocketTask(with: URL, protocols: [String]) -> URLSessionWebSocketTask {
        self.urlSession.webSocketTask(with: with, protocols: protocols)
    }
    
    /*  Add any user defined headers to a URLRequest object
     *  @param  request URLRequest
     *  @return URLRequest the input request including any user defined configuration headers
     */
    func addUserHeadersToRequest( request: URLRequest) -> URLRequest{
        var returnRequest = request
        if let allHeaders = urlSessionConfiguration.httpAdditionalHeaders {
            for key in allHeaders.keys {
                returnRequest.addValue(allHeaders[key] as! String, forHTTPHeaderField: key as! String)
            }
        }
        return returnRequest
    }
}// class


/*
 *  Delegate class implementing all available URLSessionDelegate types
 */
class ApproovURLSessionDataDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    var approovURLDelegate:URLSessionDelegate?
    
    struct Constants {
        static let rsa2048SPKIHeader:[UInt8] = [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05,
            0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ]
        static let rsa4096SPKIHeader:[UInt8]  = [
            0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05,
            0x00, 0x03, 0x82, 0x02, 0x0f, 0x00
        ]
        static let ecdsaSecp256r1SPKIHeader:[UInt8]  = [
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48,
            0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00
        ]
        static let ecdsaSecp384r1SPKIHeader:[UInt8]  = [
            0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x05, 0x2b, 0x81, 0x04,
            0x00, 0x22, 0x03, 0x62, 0x00
        ]
    }
    
    // PKI headers for both RSA and ECC
    private static var pkiHeaders = [String:[Int:Data]]()
    /*
     *  Initialize PKI dictionary
     */
    private static func initializePKI() {
        var rsaDict = [Int:Data]()
        rsaDict[2048] = Data(Constants.rsa2048SPKIHeader)
        rsaDict[4096] = Data(Constants.rsa4096SPKIHeader)
        var eccDict = [Int:Data]()
        eccDict[256] = Data(Constants.ecdsaSecp256r1SPKIHeader)
        eccDict[384] = Data(Constants.ecdsaSecp384r1SPKIHeader)
        pkiHeaders[kSecAttrKeyTypeRSA as String] = rsaDict
        pkiHeaders[kSecAttrKeyTypeECSECPrimeRandom as String] = eccDict
    }
    init(with delegate: URLSessionDelegate?){
        ApproovURLSessionDataDelegate.initializePKI()
        self.approovURLDelegate = delegate
    }
    
    // MARK: URLSessionDelegate
    
    /*  URLSessionDelegate
     *  A protocol that defines methods that URL session instances call on their delegates to handle session-level events,
     *  like session life cycle changes
     *  https://developer.apple.com/documentation/foundation/urlsessiondelegate
     */
    
    /*  Tells the URL session that the session has been invalidated
     *  https://developer.apple.com/documentation/foundation/urlsessiondelegate/1407776-urlsession
     */
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        approovURLDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
    }
    
    /*  Tells the delegate that all messages enqueued for a session have been delivered
     *  https://developer.apple.com/documentation/foundation/urlsessiondelegate/1617185-urlsessiondidfinishevents
     */
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        approovURLDelegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
    }
    
    /*  Requests credentials from the delegate in response to a session-level authentication request from the remote server
     *  https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession
     */
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // We are only interested in server trust requests
        if !challenge.protectionSpace.authenticationMethod.isEqual(NSURLAuthenticationMethodServerTrust) {
            approovURLDelegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
            return
        }
        do {
            if let serverTrust = try shouldAcceptAuthenticationChallenge(challenge: challenge){
                completionHandler(.useCredential,
                                  URLCredential.init(trust: serverTrust));
                approovURLDelegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
                return
            }
        } catch {
            NSLog("Approov: \(error)")
        }
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge,nil)
    }
    
    // MARK: URLSessionTaskDelegate
    
    /*  URLSessionTaskDelegate
     *  A protocol that defines methods that URL session instances call on their delegates to handle task-level events
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate
     */
    
    /*  Requests credentials from the delegate in response to an authentication request from the remote server
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            // We are only interested in server trust requests
            if !challenge.protectionSpace.authenticationMethod.isEqual(NSURLAuthenticationMethodServerTrust) {
                delegate.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler)
                return
            }
            do {
                if let serverTrust = try shouldAcceptAuthenticationChallenge(challenge: challenge){
                    completionHandler(.useCredential,
                                      URLCredential.init(trust: serverTrust));
                    delegate.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler)
                    return
                }
            } catch {
                NSLog("Approov: \(error)")
            }
            
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge,nil)
        }
    }
    
    /*  Tells the delegate that the task finished transferring data
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411610-urlsession
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, didCompleteWithError: error)
        }
    }
    
    /*  Tells the delegate that the remote server requested an HTTP redirect
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411626-urlsession
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
        }
    }
    
    /*  Tells the delegate when a task requires a new request body stream to send to the remote server
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1410001-urlsession
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, needNewBodyStream: completionHandler)
        }
    }
    
    /*  Periodically informs the delegate of the progress of sending body content to the server
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1408299-urlsession
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
    
    /*  Tells the delegate that a delayed URL session task will now begin loading
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/2873415-urlsession
     */
    @available(iOS 11.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task:task, willBeginDelayedRequest: request, completionHandler: completionHandler)
        }
    }
    
    /*  Tells the delegate that the session finished collecting metrics for the task
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1643148-urlsession
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, didFinishCollecting: metrics)
        }
    }
    
    /*  Tells the delegate that the task is waiting until suitable connectivity is available before beginning the network load
     *  https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/2908819-urlsession
     */
    @available(iOS 11.0, *)
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        if let delegate =  approovURLDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, taskIsWaitingForConnectivity: task)
        }
    }
    
    // MARK: URLSessionDataDelegate
    
    /*  URLSessionDataDelegate
     *  A protocol that defines methods that URL session instances call on their delegates to handle task-level events
     *  specific to data and upload tasks
     *  https://developer.apple.com/documentation/foundation/urlsessiondatadelegate
     */
    
    /*  Tells the delegate that the data task received the initial reply (headers) from the server
     *  https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1410027-urlsession
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        if let delegate =  approovURLDelegate as? URLSessionDataDelegate {
            delegate.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    /*  Tells the delegate that the data task was changed to a download task
     *  https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1409936-urlsession
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        if let delegate =  approovURLDelegate as? URLSessionDataDelegate {
            delegate.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
        }
    }
    
    /*  Tells the delegate that the data task was changed to a stream task
     *  https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1411648-urlsession
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        if let delegate =  approovURLDelegate as? URLSessionDataDelegate {
            delegate.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
        }
    }
    
    /*  Tells the delegate that the data task has received some of the expected data
     *  https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1411528-urlsession
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let delegate =  approovURLDelegate as? URLSessionDataDelegate {
            delegate.urlSession?(session,dataTask: dataTask, didReceive: data)
        }
    }
    
    /*  Asks the delegate whether the data (or upload) task should store the response in the cache
     *  https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1411612-urlsession
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if let delegate =  approovURLDelegate as? URLSessionDataDelegate {
            delegate.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
    }
    
    // MARK: URLSessionDownloadDelegate
    
    /*  A protocol that defines methods that URL session instances call on their delegates to handle
     *  task-level events specific to download tasks
     *  https://developer.apple.com/documentation/foundation/urlsessiondownloaddelegate
     */
    
    /*  Tells the delegate that a download task has finished downloading
     *  https://developer.apple.com/documentation/foundation/urlsessiondownloaddelegate/1411575-urlsession
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let delegate =  approovURLDelegate as? URLSessionDownloadDelegate {
            delegate.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    
    /*  Tells the delegate that the download task has resumed downloading
     *  https://developer.apple.com/documentation/foundation/urlsessiondownloaddelegate/1408142-urlsession
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset: Int64, expectedTotalBytes: Int64) {
        if let delegate =  approovURLDelegate as? URLSessionDownloadDelegate {
            delegate.urlSession?(session, downloadTask: downloadTask, didResumeAtOffset: didResumeAtOffset, expectedTotalBytes: expectedTotalBytes)
        }
    }
    
    /*  Periodically informs the delegate about the download’s progress
     *  https://developer.apple.com/documentation/foundation/urlsessiondownloaddelegate/1409408-urlsession
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let delegate =  approovURLDelegate as? URLSessionDownloadDelegate {
            delegate.urlSession?(session, downloadTask: downloadTask, didWriteData: didWriteData, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    
    
    // MARK: Utilities
    
    /*  Evaluates a URLAuthenticationChallenge deciding if to proceed further
     *  @param  challenge: URLAuthenticationChallenge
     *  @return SecTrust?: valid SecTrust if authentication should proceed, nil otherwise
     */
    func shouldAcceptAuthenticationChallenge(challenge: URLAuthenticationChallenge) throws -> SecTrust? {
        // Check we have a server trust, ignore any other challenges
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return nil
        }
        
        // Check the validity of the server cert
        var trustType = SecTrustResultType.invalid
        if (SecTrustEvaluate(serverTrust, &trustType) != errSecSuccess) {
            throw ApproovError.runtimeError(message: "Error during Certificate Trust Evaluation for host \(challenge.protectionSpace.host)")
        } else if (trustType != SecTrustResultType.proceed) && (trustType != SecTrustResultType.unspecified) {
            throw ApproovError.runtimeError(message: "Error: Certificate Trust Evaluation failure for host \(challenge.protectionSpace.host)")
        }
        // Get the certificate chain count
        let certCountInChain = SecTrustGetCertificateCount(serverTrust);
        var indexCurrentCert = 0;
        while(indexCurrentCert < certCountInChain){
            // get the current certificate from the chain
            guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, indexCurrentCert) else {
                throw ApproovError.runtimeError(message: "Error getting certificate at index \(indexCurrentCert) from chain for host \(challenge.protectionSpace.host)")
            }
            
            // get the subject public key info from the certificate
            guard let publicKeyInfo = publicKeyInfoOfCertificate(certificate: serverCert) else {
                /* Throw to indicate we could not parse SPKI header */
                throw ApproovError.runtimeError(message: "Error parsing SPKI header for host \(challenge.protectionSpace.host) Unsupported certificate type, SPKI header cannot be created")
            }
            
            // compute the SHA-256 hash of the public key info and base64 encode the result
            let publicKeyHash = sha256(data: publicKeyInfo)
            let publicKeyHashBase64 = String(data:publicKeyHash.base64EncodedData(), encoding: .utf8)
            
            // check that the hash is the same as at least one of the pins
            guard let approovCertHashes = Approov.getPins("public-key-sha256") else {
                throw ApproovError.runtimeError(message: "Approov SDK getPins() call failed")
            }
            // Get the receivers host
            let host = challenge.protectionSpace.host
            if let certHashList = approovCertHashes[host] {
                // We have on or more cert hashes matching the receivers host, compare them
                for certHash in certHashList {
                    if publicKeyHashBase64 == certHash {
                        return serverTrust
                    }
                }
            }
            indexCurrentCert += 1
        }
        // We return nil if no match in current set of pins from Approov SDK and certificate chain seen during TLS handshake
        return nil
    }
    /*
    * gets a certificate's subject public key info (SPKI)
    */
    func publicKeyInfoOfCertificate(certificate: SecCertificate) -> Data? {
        var publicKey:SecKey?
        if #available(iOS 12.0, *) {
            publicKey = SecCertificateCopyKey(certificate)
        } else {
            // Fallback on earlier versions
            // from TrustKit https://github.com/datatheorem/TrustKit/blob/master/TrustKit/Pinning/TSKSPKIHashCache.m lines
            // 221-234:
            // Create an X509 trust using the certificate
            let secPolicy = SecPolicyCreateBasicX509()
            var secTrust:SecTrust?
            if SecTrustCreateWithCertificates(certificate, secPolicy, &secTrust) != errSecSuccess {
                return nil
            }
            // get a public key reference for the certificate from the trust
            var secTrustResultType = SecTrustResultType.invalid
            if SecTrustEvaluate(secTrust!, &secTrustResultType) != errSecSuccess {
                return nil
            }
            publicKey = SecTrustCopyPublicKey(secTrust!)
            
        }
        if publicKey == nil {
            return nil
        }
        // get the SPKI header depending on the public key's type and size
        guard var spkiHeader = publicKeyInfoHeaderForKey(publicKey: publicKey!) else {
            return nil
        }
        // combine the public key header and the public key data to form the public key info
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, nil) else {
            return nil
        }
        spkiHeader.append(publicKeyData as Data)
        return spkiHeader
    }

    /*
    * gets the subject public key info (SPKI) header depending on a public key's type and size
    */
    func publicKeyInfoHeaderForKey(publicKey: SecKey) -> Data? {
        guard let publicKeyAttributes = SecKeyCopyAttributes(publicKey) else {
            return nil
        }
        if let keyType = (publicKeyAttributes as NSDictionary).value(forKey: kSecAttrKeyType as String) {
            if let keyLength = (publicKeyAttributes as NSDictionary).value(forKey: kSecAttrKeySizeInBits as String) {
                // Find the header
                if let spkiHeader:Data = ApproovURLSessionDataDelegate.pkiHeaders[keyType as! String]?[keyLength as! Int] {
                    return spkiHeader
                }
            }
        }
        return nil
    }
    
    /*  SHA256 of given input bytes
     *
     */
    func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}// class


class ApproovSDK {
    /* Dynamic configuration string key in user default database */
    public static let kApproovDynamicKey = "approov-dynamic"
    /* Initial configuration string/filename for Approov SDK */
    public static let kApproovInitialKey = "approov-initial"
    /* Initial configuration file extention for Approov SDK */
    public static let kConfigFileExtension = "config"
    /* Approov token default header */
    private static let kApproovTokenHeader = "Approov-Token"
    /* Approov token custom prefix: any prefix to be added such as "Bearer " */
    private static var approovTokenPrefix = ""
    /* Private initializer */
    fileprivate init(){}
    /* Status of Approov SDK initialisation */
    private static var approovSDKInitialised = false
    /* Singleton */
    fileprivate static let sharedInstance: ApproovSDK = {
        let instance = ApproovSDK()
        /* Read initial config */
        if let configString = readInitialApproovConfig() {
            /* Read dynamic config  */
            let dynamicConfigString = readDynamicApproovConfig()
            /* Initialise Approov SDK */
            do {
                try Approov.initialize(configString, updateConfig: dynamicConfigString, comment: nil)
                approovSDKInitialised = true
                /* Save updated SDK config if this is the first ever app launch */
                if dynamicConfigString == nil {
                    storeDynamicConfig(newConfig: Approov.fetchConfig()!)
                }
            } catch let error {
                print("Error initilizing Approov SDK: \(error.localizedDescription)")
            }
        } else {
            print("FATAL: Unable to initialize Approov SDK")
        }
        return instance
    }()
    
    // Dispatch queue to manage concurrent access to bindHeader variable
    private static let bindHeaderQueue = DispatchQueue(label: "ApproovSDK.bindHeader", qos: .default, attributes: .concurrent, autoreleaseFrequency: .never, target: DispatchQueue.global())
    private static var _bindHeader = ""
    // Bind Header string
    public static var bindHeader: String {
        get {
            var bindHeader = ""
            bindHeaderQueue.sync {
                bindHeader = _bindHeader
            }
            return bindHeader
        }
        set {
            bindHeaderQueue.async(group: nil, qos: .default, flags: .barrier, execute: {self._bindHeader = newValue})
        }
    }
    
    /**
    * Reads any previously-saved dynamic configuration for the Approov SDK. May return 'nil' if a
    * dynamic configuration has not yet been saved by calling saveApproovDynamicConfig().
    */
    static public func readDynamicApproovConfig() -> String? {
        return UserDefaults.standard.object(forKey: kApproovDynamicKey) as? String
    }
    
    /*
     *  Reads the initial configuration file for the Approov SDK
     *  The file defined as kApproovInitialKey.kConfigFileExtension
     *  is read from the app bundle main directory
     */
    static public func readInitialApproovConfig() -> String? {
        // Attempt to load the initial config from the app bundle directory
        guard let originalFileURL = Bundle.main.url(forResource: kApproovInitialKey, withExtension: kConfigFileExtension) else {
            /*  This is fatal since we can not load the initial configuration file */
            print("FATAL: unable to load Approov SDK config file from app bundle directories")
            return nil
        }
        
        // Read file contents
        do {
            let fileExists = try originalFileURL.checkResourceIsReachable()
            if !fileExists {
                print("FATAL: No initial Approov SDK config file available")
                return nil
            }
            let configString = try String(contentsOf: originalFileURL)
            return configString
        } catch let error {
            print("FATAL: Error attempting to read inital configuration for Approov SDK from \(originalFileURL): \(error)")
            return nil
        }
    }
    
    /**
    * Saves the Approov dynamic configuration to the user defaults database which is persisted
    * between app launches. This should be called after every Approov token fetch where
    * isConfigChanged is set. It saves a new configuration received from the Approov server to
    * the user defaults database so that it is available on app startup on the next launch.
    */
    static public func storeDynamicConfig(newConfig: String){
        if let updateConfig = Approov.fetchConfig() {
            UserDefaults.standard.set(updateConfig, forKey: kApproovDynamicKey)
        }
    }
    
    
    /*
     *  Allows token prefetch operation to be performed as early as possible. This
     *  permits a token to be available while an application might be loading resources
     *  or is awaiting user input. Since the initial token fetch is the most
     *  expensive the prefetch seems reasonable.
     */
    public static let prefetchApproovToken: Void = {
        let _ = ApproovSDK.sharedInstance
        if approovSDKInitialised {
            // We succeeded initializing Approov SDK, fetch a token
            Approov.fetchToken({(approovResult: ApproovTokenFetchResult) in
                // Prefetch done, no need to process response
            }, "approov.io")
        }
    }()
    
    
    /*
     *  Convenience function fetching the Approov token
     *
     */
    fileprivate func fetchApproovToken(request: URLRequest) -> ApproovData {
        var returnData = ApproovData(request: request, decision: .ShouldFail, sdkMessage: "", error: nil)
        // Get the sahred instance handle, which initializes the Approov SDK
        if !ApproovSDK.approovSDKInitialised {
            let _ = ApproovSDK.sharedInstance
        }
        // Check if Bind Header is set to a non empty String
        if ApproovSDK.bindHeader != "" {
            /*  Query the URLSessionConfiguration for user set headers. They would be set like so:
             *  config.httpAdditionalHeaders = ["Authorization Bearer" : "token"]
             *  Since the URLSessionConfiguration is part of the init call and we store its reference
             *  we check for the presence of a user set header there.
             */
            if let aValue = request.value(forHTTPHeaderField: ApproovSDK.bindHeader) {
                // Add the Bind Header as a data hash to Approov token
                Approov.setDataHashInToken(aValue)
            } else {
                // We fail since required binding header is missing
                let error = ApproovError.runtimeError(message: "Approov: Approov SDK missing token binding header \(ApproovSDK.bindHeader)")
                returnData.error = error
                return returnData
            }
        }
        // Invoke fetch token sync
        let approovResult = Approov.fetchTokenAndWait(request.url!.absoluteString)
        // Log result of token fetch
        NSLog("Approov: Approov token for host: %@ : %@", request.url!.absoluteString, approovResult.loggableToken())
        if approovResult.isConfigChanged {
            // Store dynamic config file if a change has occurred
            if let newConfig = Approov.fetchConfig() {
                ApproovSDK.storeDynamicConfig(newConfig: newConfig)
            }
        }
        // Update the message
        returnData.sdkMessage = Approov.string(from: approovResult.status)
        switch approovResult.status {
            case ApproovTokenFetchStatus.success:
                // Can go ahead and make the API call with the provided request object
                returnData.decision = .ShouldProceed
                // Set Approov-Token header
                returnData.request.setValue(ApproovSDK.approovTokenPrefix + approovResult.token, forHTTPHeaderField: ApproovSDK.kApproovTokenHeader)
            case ApproovTokenFetchStatus.noNetwork,
                 ApproovTokenFetchStatus.poorNetwork,
                 ApproovTokenFetchStatus.mitmDetected:
                 // Must not proceed with network request and inform user a retry is needed
                returnData.decision = .ShouldRetry
                let error = ApproovError.runtimeError(message: returnData.sdkMessage)
                returnData.error = error
            case ApproovTokenFetchStatus.unprotectedURL,
                 ApproovTokenFetchStatus.unknownURL,
                 ApproovTokenFetchStatus.noApproovService:
                // We do NOT add the Approov-Token header to the request headers
                returnData.decision = .ShouldProceed
            default:
                let error = ApproovError.runtimeError(message: returnData.sdkMessage)
                returnData.error = error
                returnData.decision = .ShouldFail
        }// switch
        
        return returnData
    }
}

/*
 *  Approov error conditions
 */
public enum ApproovError: Error {
    case initializationFailure(message: String)
    case configurationFailure(message: String)
    case runtimeError(message: String)
    var localizedDescription: String? {
        switch self {
        case let .initializationFailure(message), let .configurationFailure(message) , let .runtimeError(message):
            return message
        }
    }
}



