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
    
    
    @IBOutlet weak var productNameLabel: NSTextField!
    @IBOutlet weak var productDescription: NSScrollView!
    @IBOutlet weak var originalPriceLabel: NSTextField!
    @IBOutlet weak var newPriceTextField: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let textView = productDescription.documentView as! NSTextView
        textView.editable = false
        newPriceTextField.editable = false
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func publishNewProduct(sender: AnyObject) {
        print("Publishing new product")
    }
}

