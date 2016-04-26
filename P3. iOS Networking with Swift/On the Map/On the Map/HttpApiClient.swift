//
//  LoginViewController.swift
//  On the Map
//
//  Created by Ivan Magda on 20.03.16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

typealias TaskCompletionHandler = (data: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void

//-------------------------------------
// MARK: - HttpApiClient
//-------------------------------------

class HttpApiClient {
    
    //---------------------------------
    // MARK: - Properties -
    //---------------------------------
    
    let configuration: NSURLSessionConfiguration
    
    lazy var session: NSURLSession = {
        return NSURLSession(configuration: self.configuration)
    }()
    
    var currentTasks: Set<NSURLSessionDataTask> = []
    
    /// If value is `true` then debug messages will be logged.
    var loggingEnabled = false
    
    //---------------------------------
    // MARK: - Initializers -
    //---------------------------------
    
    init(configuration: NSURLSessionConfiguration) {
        self.configuration = configuration
    }
    
    //---------------------------------
    // MARK: - Network -
    //---------------------------------
    
    func cancelAllRequests() {
        for task in self.currentTasks {
            task.cancel()
        }
        self.currentTasks = []
    }
    
    //---------------------------------
    // MARK: Data Tasks
    //---------------------------------
    
    func fetchRawData(request: NSURLRequest, completion: TaskCompletionHandler) {
        let task = dataTaskWithRequest(request, completion: completion)
        task.resume()
    }
    
    func dataTaskWithRequest(request: NSURLRequest, completion: TaskCompletionHandler) -> NSURLSessionDataTask {
        var task: NSURLSessionDataTask?
        task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            self.currentTasks.remove(task!)
            let httpResponse = response as! NSHTTPURLResponse
            
            self.debugLog("Received HTTP \(httpResponse.statusCode) from \(request.HTTPMethod!) to \(request.URL!)")
            
            /* GUARD: Was there an error? */
            guard error == nil else {
                self.debugLog("Received an error from HTTP \(request.HTTPMethod!) to \(request.URL!)")
                self.debugLog("Error: \(error)")
                completion(data: nil, response: httpResponse, error: error)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                self.debugLog("Received an empty response")
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request"]
                completion(data: nil, response: httpResponse, error: NSError(domain: "com.ivanmagda.On-the-Map.emptyresponse", code: 12, userInfo: userInfo))
                return
            }
            
            completion(data: data, response: httpResponse, error: nil)
        })
        
        currentTasks.insert(task!)
        
        return task!
    }
    
    //---------------------------------
    // MARK: Debug Logging
    //---------------------------------
    
    func debugLog(msg: String) {
        guard loggingEnabled else { return }
        print(msg)
    }
    
    func debugResponseData(data: NSData) {
        guard loggingEnabled else { return }
        if let body = String(data: data, encoding: NSUTF8StringEncoding) {
            print(body)
        } else {
            print("<empty response>")
        }
    }
    
}