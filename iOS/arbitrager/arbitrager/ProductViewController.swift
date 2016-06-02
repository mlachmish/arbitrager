//
//  ProductViewController.swift
//  arbitrager
//
//  Created by Matan Lachmish on 03/06/2016.
//  Copyright © 2016 arbitrager. All rights reserved.
//

import Cocoa
import Foundation
import WebKit

class ProductViewController: NSViewController {

    var productUrl : String!

    @IBOutlet var webView: WebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let url = NSURL(string:productUrl)
        let req = NSURLRequest(URL:url!)
        webView!.mainFrame.loadRequest(req)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

