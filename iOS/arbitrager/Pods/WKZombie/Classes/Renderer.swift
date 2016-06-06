//
// Renderer.swift
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


typealias RenderCompletion = (result : AnyObject?, response: NSURLResponse?, error: NSError?) -> Void

internal class Renderer : NSObject {
    
    var loadMediaContent : Bool = true
    
    var userAgent : String? {
        get {
            return self.webView.customUserAgent
        }
        set {
            self.webView.customUserAgent = newValue
        }
    }
    
    private var renderQueue : NSOperationQueue = {
        let instance = NSOperationQueue()
        instance.maxConcurrentOperationCount = 1
        instance.qualityOfService = .UserInitiated
       return instance
    }()
    
    private var webView : WKWebView!
    internal static let scrapingCommand = "document.documentElement.outerHTML"
    
    init(processPool: WKProcessPool? = nil) {
        super.init()
        let doneLoadingWithoutMediaContentScript = "window.webkit.messageHandlers.doneLoading.postMessage(\(Renderer.scrapingCommand));"
        let doneLoadingUserScript = WKUserScript(source: doneLoadingWithoutMediaContentScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        
        let getElementByXPathScript = "function getElementByXpath(path) { " +
                                      "   return document.evaluate(path, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; " +
                                      "}"
        let getElementUserScript = WKUserScript(source: getElementByXPathScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
        
        let contentController = WKUserContentController()
        contentController.addUserScript(doneLoadingUserScript)
        contentController.addUserScript(getElementUserScript)

        let config = WKWebViewConfiguration()
        config.processPool = processPool ?? WKProcessPool()
        config.userContentController = contentController
        
        /// Note: The WKWebView behaves very unreliable when rendering offscreen
        /// on a device. This is especially true with JavaScript, which simply 
        /// won't be executed sometimes.
        /// Therefore, I decided to add this very ugly hack where the rendering
        /// webview will be added to the view hierarchy (between the 
        /// rootViewController's view and the key window.
        /// Until there's no better solution, we'll have to roll with this.
        dispatch_sync_on_main_thread {
            let warning = "The keyWindow or contentView is missing."
            #if os(iOS)
                let bounds = UIScreen.mainScreen().bounds
                self.webView = WKWebView(frame: bounds, configuration: config)
                if let window = UIApplication.sharedApplication().keyWindow {
                    self.webView.alpha = 0.01
                    window.insertSubview(self.webView, atIndex: 0)
                } else {
                    Logger.log(warning)
                }
            #elseif os(OSX)
                self.webView = WKWebView(frame: CGRectZero, configuration: config)
                if let window = NSApplication.sharedApplication().keyWindow, view = window.contentView {
                    self.webView.frame = CGRect(origin: CGPointZero, size: view.frame.size)
                    self.webView.alphaValue = 0.01
                    view.addSubview(self.webView)
                } else {
                    Logger.log(warning)
                }
            #endif
        }
    }
    
    deinit {
        dispatch_sync_on_main_thread {
            self.webView.removeFromSuperview()
        }
    }
        
    //========================================
    // MARK: Render Page
    //========================================
    
    internal func renderPageWithRequest(request: NSURLRequest, postAction: PostAction = .None, completionHandler: RenderCompletion) {
        let requestBlock : (operation: RenderOperation) -> Void = { operation in
            if let url = request.URL where url.fileURL {
                operation.webView?.loadFileURL(url, allowingReadAccessToURL: url.URLByDeletingLastPathComponent ?? url)
            } else {
                operation.webView?.loadRequest(request)
            }
        }
        let operation = operationWithRequestBlock(requestBlock, postAction: postAction, completionHandler: completionHandler)
        operation.name = "Request".uppercaseString + "\n\(request.URL?.absoluteString ?? String())"
        renderQueue.addOperation(operation)
    }
    
    
    //========================================
    // MARK: Execute JavaScript
    //========================================
    
    internal func executeScript(script: String, willLoadPage: Bool? = false, postAction: PostAction = .None, completionHandler: RenderCompletion?) {
        var requestBlock : (operation : RenderOperation) -> Void
        if let willLoadPage = willLoadPage where willLoadPage == true {
            requestBlock = { $0.webView?.evaluateJavaScript(script, completionHandler: nil) }
        } else {
            requestBlock = { operation in
                operation.webView?.evaluateJavaScript(script, completionHandler: { result, error in
                    var data : NSData?
                    if let result = result {
                        data = "\(result)".dataUsingEncoding(NSUTF8StringEncoding)
                    }
                    operation.completeRendering(operation.webView, result: data, error: error)
                })
            }
        }
        let operation = operationWithRequestBlock(requestBlock, postAction: postAction, completionHandler: completionHandler)
        operation.name = "Script".uppercaseString + "\n\(script ?? String())"
        renderQueue.addOperation(operation)
    }
    
    //========================================
    // MARK: Helper Methods
    //========================================
    
    private func operationWithRequestBlock(requestBlock: (operation: RenderOperation) -> Void, postAction: PostAction = .None, completionHandler: RenderCompletion?) -> NSOperation {
        let operation = RenderOperation(webView: webView)
        operation.loadMediaContent = loadMediaContent
        operation.postAction = postAction
        operation.completionBlock = { [weak operation] in
            completionHandler?(result: operation?.result, response: operation?.response, error: operation?.error)
        }
        operation.requestBlock = requestBlock
        return operation
    }
    
    internal func currentContent(completionHandler: RenderCompletion) {
        webView.evaluateJavaScript(Renderer.scrapingCommand.terminate()) { result, error in
            var data : NSData?
            if let result = result {
                data = "\(result)".dataUsingEncoding(NSUTF8StringEncoding)
            }
            completionHandler(result: data, response: nil, error: error)
        }
    }
    
}


//========================================
// MARK: Cache
//========================================

extension Renderer {
    internal func clearCache() {
        let distantPast = NSDate.distantPast()
        NSHTTPCookieStorage.sharedHTTPCookieStorage().removeCookiesSinceDate(distantPast)
        let websiteDataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        WKWebsiteDataStore.defaultDataStore().removeDataOfTypes(websiteDataTypes, modifiedSince: distantPast, completionHandler:{ })
    }
}


//========================================
// MARK: Snapshot
//========================================

#if os(iOS)
extension Renderer {
    internal func snapshot() -> Snapshot? {
        precondition(webView.superview != nil, "WKWebView has no superview. Cannot take snapshot.")
        UIGraphicsBeginImageContextWithOptions(webView.bounds.size, true, 0)
        webView.scrollView.drawViewHierarchyInRect(webView.bounds, afterScreenUpdates: true)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let data = UIImagePNGRepresentation(snapshot) {
            return Snapshot(data: data, page: webView.URL)
        }
        return nil
    }
}
#endif
