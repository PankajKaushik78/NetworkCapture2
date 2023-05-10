import Foundation

@objc
public class NetworkCapture: URLProtocol {

    
    public var text = "Hello, World!"
    
    private lazy var session: URLSession = { [unowned self] in
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    private var response: URLResponse?
    private var responseData: NSMutableData?
    private var requestDate: Date?
    private var responseDate: Date?
    private var timeInterval: Float?
    
    override public class func canInit(with request: URLRequest) -> Bool {
        return canServeRequest(request)
    }
    
    override public class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }
    
    private class func canServeRequest(_ request: URLRequest) -> Bool {
        return true
    }
    
    override public func startLoading() {
        requestDate = Date()
//        print(request)
        
//        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
//        URLProtocol.setProperty(true, forKey: "123", in: mutableRequest)
        session.dataTask(with: request as URLRequest).resume()
    }
    
    override public func stopLoading() {
        session.getTasksWithCompletionHandler { dataTasks, _, _ in
            dataTasks.forEach { $0.cancel() }
            self.session.invalidateAndCancel()
        }
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
}

extension NetworkCapture: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData?.append(data)
        client?.urlProtocol(self, didLoad: data)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        responseData = NSMutableData()
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        guard let request = task.originalRequest else {
            return
        }
        print("****************************** Request: \(request.httpMethod!) \(request.url!)***************************")
        if let httpResponse = response as? HTTPURLResponse {
            print("****************************** StatusCode: \(httpResponse.statusCode) ******************************")
        }
        if error != nil {
//            Capture error
        } else if let response = response {
            responseDate = Date()
        }
        
        if (responseDate != nil && requestDate != nil) {
            timeInterval = Float(responseDate!.timeIntervalSince(requestDate!))
        }
        print("****************************** Time interval: \(timeInterval)")
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        let updatedRequest: URLRequest
        if URLProtocol.property(forKey: "123", in: request) != nil {
            let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
            URLProtocol.removeProperty(forKey: "123", in: mutableRequest)
            
            updatedRequest = mutableRequest as URLRequest
        } else {
            updatedRequest = request
        }
        
        client?.urlProtocol(self, wasRedirectedTo: updatedRequest, redirectResponse: response)
        completionHandler(updatedRequest)
    }
    
//    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        let wrappedChallenge = URLAuthenticationChallenge(authenticationChallenge: challenge, sender: NFXAuthenticationChallengeSender(handler: completionHandler))
//        client?.urlProtocol(self, didReceive: wrappedChallenge)
//    }
    
    #if !os(OSX)
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
    #endif
}
