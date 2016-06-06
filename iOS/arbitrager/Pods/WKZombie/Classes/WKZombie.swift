//
// WKZombie.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import WebKit

public class WKZombie : NSObject {
    
    /// A shared instance of `Manager`, used by top-level WKZombie methods,
    /// and suitable for multiple web sessions.
    public class var sharedInstance: WKZombie {
        dispatch_once(&Static.token) {  Static.instance = WKZombie() }
        return Static.instance!
    }
    
    internal struct Static {
        static var token : dispatch_once_t = 0
        static var instance : WKZombie?
    }
    
    private var _renderer : Renderer!
    private var _fetcher : ContentFetcher!
    
    /// Returns the name of this WKZombie session.
    public private(set) var name : String!
    
    /// If false, the loading progress will finish once the 'raw' HTML data
    /// has been transmitted. Media content such as videos or images won't
    /// be loaded.
    public var loadMediaContent : Bool = true {
        didSet {
            _renderer.loadMediaContent = loadMediaContent
        }
    }
    
    /// The custom user agent string or nil if no custom user agent string has been set.
    public var userAgent : String? {
        get {
            return self._renderer.userAgent
        }
        set {
            self._renderer.userAgent = newValue
        }
    }
    
    #if os(iOS)
    /// Snapshot Handler
    public var snapshotHandler : SnapshotHandler?
    #endif
    
    /**
     The designated initializer.
     
     - parameter name: The name of the WKZombie session.
     
     - returns: A WKZombie instance.
     */
    public init(name: String? = "WKZombie", processPool: WKProcessPool? = nil) {
        super.init()
        self.name = name
        self._renderer = Renderer(processPool: processPool)
        self._fetcher = ContentFetcher()
    }
    
    //========================================
    // MARK: Response Handling
    //========================================
    
    private func _handleResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> Result<NSData> {
        var statusCode : Int = (error == nil) ? ActionError.Static.DefaultStatusCodeSuccess : ActionError.Static.DefaultStatusCodeError
        if let response = response as? NSHTTPURLResponse {
            statusCode = response.statusCode
        }
        let errorDomain : ActionError? = (error == nil) ? nil : .NetworkRequestFailure
        let responseResult: Result<Response> = Result(errorDomain, Response(data: data, statusCode: statusCode))
        return responseResult >>> parseResponse
    }
}


//========================================
// MARK: Get Page
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will load and return a HTML or JSON page for the specified URL.
     
     - parameter url: An URL referencing a HTML or JSON page.
     
     - returns: The WKZombie Action.
     */
    public func open<T: Page>(url: NSURL) -> Action<T> {
        return open(then: .None)(url: url)
    }
    
    /**
     The returned WKZombie Action will load and return a page for the specified URL.
     
     - parameter postAction: An wait/validation action that will be performed after the page has finished loading.
     - parameter url: An URL referencing a HTML or JSON page.
     
     - returns: The WKZombie Action.
     */
    public func open<T: Page>(then postAction: PostAction) -> (url: NSURL) -> Action<T> {
        return { (url: NSURL) -> Action<T> in
            return Action() { [unowned self] completion in
                let request = NSURLRequest(URL: url)
                self._renderer.renderPageWithRequest(request, postAction: postAction, completionHandler: { data, response, error in
                    let data = self._handleResponse(data as? NSData, response: response, error: error)
                    completion(data >>> decodeResult(response?.URL))
                })
            }
        }
    }
    
    /**
     The returned WKZombie Action will return the current page.
     
     - returns: The WKZombie Action.
     */
    public func inspect<T: Page>() -> Action<T> {
        return Action() { [unowned self] completion in
            self._renderer.currentContent({ (result, response, error) in
                let data = self._handleResponse(result as? NSData, response: response, error: error)
                completion(data >>> decodeResult(response?.URL))
            })
        }
    }
}


//========================================
// MARK: Submit Form
//========================================

extension WKZombie {
    /**
     Submits the specified HTML form.
     
     - parameter form: A HTML form.
     
     - returns: The WKZombie Action.
     */
    public func submit<T: Page>(form: HTMLForm) -> Action<T> {
        return submit(then: .None)(form: form)
    }
    
    /**
     Submits the specified HTML form.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter url: An URL referencing a HTML or JSON page.
     
     - returns: The WKZombie Action.
     */
    public func submit<T: Page>(then postAction: PostAction) -> (form: HTMLForm) -> Action<T> {
        return { (form: HTMLForm) -> Action<T> in
            return Action() { [unowned self] completion in
                if let script = form.actionScript() {
                    self._renderer.executeScript(script, willLoadPage: true, postAction: postAction, completionHandler: { result, response, error in
                        let data = self._handleResponse(result as? NSData, response: response, error: error)
                        completion(data >>> decodeResult(response?.URL))
                    })
                } else {
                    completion(Result.Error(.NetworkRequestFailure))
                }
            }
        }
    }
}


//========================================
// MARK: Click Event
//========================================

extension WKZombie {
    /**
     Simulates the click of a HTML link.
     
     - parameter link: The HTML link.
     
     - returns: The WKZombie Action.
     */
    public func click<T: Page>(link : HTMLLink) -> Action<T> {
        return click(then: .None)(link: link)
    }
    
    /**
     Simulates the click of a HTML link.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter link: The HTML link.
     
     - returns: The WKZombie Action.
     */
    public func click<T: Page>(then postAction: PostAction) -> (link : HTMLLink) -> Action<T> {
        return { [unowned self] (link: HTMLLink) -> Action<T> in
            return self._touch(then: postAction)(clickable: link)
        }
    }
    
    /**
     Simulates HTMLButton press.
     
     - parameter button: The HTML button.
     
     - returns: The WKZombie Action.
     */
    public func press<T: Page>(button : HTMLButton) -> Action<T> {
        return press(then: .None)(button: button)
    }
    
    /**
     Simulates HTMLButton press.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter button: The HTML button.
     
     - returns: The WKZombie Action.
     */
    public func press<T: Page>(then postAction: PostAction) -> (button : HTMLButton) -> Action<T> {
        return { [unowned self] (button: HTMLButton) -> Action<T> in
            return self._touch(then: postAction)(clickable: button)
        }
    }
    
    // Private
    private func _touch<T: Page, U: HTMLClickable>(then postAction: PostAction = .None) -> (clickable : U) -> Action<T> {
        return { (clickable: U) -> Action<T> in
            return Action() { [unowned self] completion in
                if let script = clickable.actionScript() {
                    self._renderer.executeScript(script, willLoadPage: true, postAction: postAction, completionHandler: { result, response, error in
                        let data = self._handleResponse(result as? NSData, response: response, error: error)
                        completion(data >>> decodeResult(response?.URL))
                    })
                } else {
                    completion(Result.Error(.NetworkRequestFailure))
                }
            }
        }
    }
}

//========================================
// MARK: DOM Modification Methods
//========================================

extension WKZombie {
    
    /**
     The returned WKZombie Action will set or update a attribute/value pair on the specified HTMLElement.
     
     - parameter key:   A Attribute Name.
     - parameter value: A Value.
     - parameter element: A HTML element.
     
     - returns: The WKZombie Action.
     */
    public func setAttribute<T: HTMLElement>(key: String, value: String?) -> (element: T) -> Action<HTMLPage> {
        return { (element: T) -> Action<HTMLPage> in
            return Action() { [unowned self] completion in
                if let script = element.createSetAttributeCommand(key, value: value) {
                    self._renderer.executeScript("\(script) \(Renderer.scrapingCommand.terminate())", completionHandler: { result, response, error in
                        completion(decodeResult(nil)(data: result as? NSData))
                    })
                } else {
                    completion(Result.Error(.NetworkRequestFailure))
                }
            }
        }
    }
    
}

//========================================
// MARK: Find Methods
//========================================

extension WKZombie {    
    /**
     The returned WKZombie Action will search a page and return all elements matching the generic HTML element type and
     the passed key/value attributes.
     
     - parameter by: Key/Value Pairs.
     - parameter page: A HTML page.
     
     - returns: The WKZombie Action.
     */
    public func getAll<T: HTMLElement>(by searchType: SearchType<T>) -> (page: HTMLPage) -> Action<[T]> {
        return { (page: HTMLPage) -> Action<[T]> in
            let elements : Result<[T]> = page.findElements(searchType)
            return Action(result: elements)
        }
    }
        
    /**
     The returned WKZombie Action will search a page and return the first element matching the generic HTML element type and
     the passed key/value attributes.
     
     - parameter by: Key/Value Pairs.
     - parameter page: A HTML page.
     
     - returns: The WKZombie Action.
     */
    public func get<T: HTMLElement>(by searchType: SearchType<T>) -> (page: HTMLPage) -> Action<T> {
        return { (page: HTMLPage) -> Action<T> in
            let elements : Result<[T]> = page.findElements(searchType)
            return Action(result: elements.first())
        }
    }
}

//========================================
// MARK: JavaScript Methods
//========================================

public typealias JavaScript = String
public typealias JavaScriptResult = String

extension WKZombie {
    
    /**
     The returned WKZombie Action will execute a JavaScript string.
     
     - parameter script: A JavaScript string.
     
     - returns: The WKZombie Action.
     */
    public func execute(script: JavaScript) -> (page: HTMLPage) -> Action<JavaScriptResult> {
        return { (page: HTMLPage) -> Action<JavaScriptResult> in
            return Action() { [unowned self] completion in
                self._renderer.executeScript(script, completionHandler: { result, response, error in
                    let data = self._handleResponse(result as? NSData, response: response, error: error)
                    let output = data >>> decodeString
                    Logger.log("Script Result".uppercaseString + "\n\(output)\n")
                    completion(output)
                })
            }
        }
    }
}


//========================================
// MARK: Fetch Actions
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will download the linked data of the passed HTMLFetchable object.
     
     - parameter fetchable: A HTMLElement that implements the HTMLFetchable protocol.
     
     - returns: The WKZombie Action.
     */
    public func fetch<T: HTMLFetchable>(fetchable: T) -> Action<T> {
        return Action() { [unowned self] completion in
            if let fetchURL = fetchable.fetchURL {
                self._fetcher.fetch(fetchURL, completion: { (result, response, error) in
                    let data = self._handleResponse(result, response: response, error: error)
                    switch data {
                    case .Success(let value): fetchable.fetchedData = value
                    case .Error(let error):
                        completion(Result.Error(error))
                        return
                    }
                    completion(Result.Success(fetchable))
                })
            } else {
                completion(Result.Error(.NotFound))
            }
        }
    }
}


//========================================
// MARK: Transform Actions
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will transform a HTMLElement into another HTMLElement using the specified function.
     
     - parameter f: The function that takes a certain HTMLElement as parameter and transforms it into another HTMLElement.
     - parameter element: A HTML element.
     
     - returns: The WKZombie Action.
     */
    public func map<T, A>(f: T -> A) -> (object: T) -> Action<A> {
        return { (object: T) -> Action<A> in
            return Action(result: resultFromOptional(f(object), error: .NotFound))
        }
    }
}

//========================================
// MARK: Advanced Actions
//========================================

extension WKZombie {
    /**
     Executes the specified action (with the result of the previous action execution as input parameter) until
     a certain condition is met. Afterwards, it will return the collected action results.
     
     - parameter f:       The Action which will be executed.
     - parameter until:   If 'true', the execution of the specified Action will stop.
     - parameter initial: The initial input parameter for the Action.
     
     - returns: The collected Sction results.
     */
    public func collect<T>(f: T -> Action<T>, until: T -> Bool) -> (initial: T) -> Action<[T]> {
        return { (initial: T) -> Action<[T]> in
            return Action.collect(initial, f: f, until: until)
        }
    }
    
    /**
     Makes a bulk execution of the specified action with the provided input values. Once all actions have
     finished, the collected results will be returned.
     
     - parameter f:        The Action.
     - parameter elements: An array containing the input value for the Action.
     
     - returns: The collected Action results.
     */
    public func batch<T, U>(f: T -> Action<U>) -> (elements: [T]) -> Action<[U]> {
        return { (elements: [T]) -> Action<[U]> in
            return Action.batch(elements, f: f)
        }
    }
}

//========================================
// MARK: JSON Actions
//========================================

extension WKZombie {
    
    /**
     The returned WKZombie Action will parse NSData and create a JSON object.
     
     - parameter data: A NSData object.
     
     - returns: A JSON object.
     */
    public func parse<T: JSON>(data: NSData) -> Action<T> {
        return Action(result: parseJSON(data))
    }
    
    /**
     The returned WKZombie Action will take a JSONParsable (Array, Dictionary and JSONPage) and 
     decode it into a Model object. This particular Model class has to implement the 
     JSONDecodable protocol.
     
     - parameter element: A JSONParsable instance.
     
     - returns: A JSONDecodable object.
     */
    public func decode<T : JSONDecodable>(element: JSONParsable) -> Action<T> {
        return Action(result: decodeJSON(element.content()))
    }
    
    /**
     The returned WKZombie Action will take a JSONParsable (Array, Dictionary and JSONPage) and
     decode it into an array of Model objects of the same class. The class has to implement the
     JSONDecodable protocol.
     
     - parameter element: A JSONParsable instance.
     
     - returns: A JSONDecodable array.
     */
    public func decode<T : JSONDecodable>(array: JSONParsable) -> Action<[T]> {
        return Action(result: decodeJSON(array.content()))
    }
    
}

#if os(iOS)
    
//========================================
// MARK: Snapshot Methods
//========================================
    
/// Default delay before taking snapshots
private let DefaultSnapshotDelay = 0.1
    
extension WKZombie {
    
    /**
     The returned WKZombie Action will make a snapshot of the current page.
     Note: This method only works under iOS. Also, a snapshotHandler must be registered.
     
     - returns: A snapshot class.
     */
    public func snap<T>() -> (element: T) -> Action<T> {
        return { (element: T) -> Action<T> in
            return Action<T>(operation: { [unowned self] completion in
                delay(DefaultSnapshotDelay, completion: {
                    if let snapshotHandler = self.snapshotHandler, snapshot = self._renderer.snapshot() {
                        snapshotHandler(snapshot)
                        completion(Result.Success(element))
                    } else {
                        completion(Result.Error(.SnapshotFailure))
                    }
                })
            })
        }
    }
}
    
#endif

//========================================
// MARK: Debug Methods
//========================================

extension WKZombie {
    /**
     Prints the current state of the WKZombie browser to the console.
     */
    public func dump() {
        _renderer.currentContent { (result, response, error) in
            if let output = (result as? NSData)?.toString() {
                Logger.log(output)
            } else {
                Logger.log("No Output available.")
            }
        }
    }
    
    /**
     Clears the cache/cookie data (such as login data, etc).
     */
    public func clearCache() {
        _renderer.clearCache()
    }
}
