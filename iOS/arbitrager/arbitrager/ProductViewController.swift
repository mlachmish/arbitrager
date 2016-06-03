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
import Kingfisher


class ProductViewController: NSViewController {

    var productUrl : String!
    
    let service : ServiceClient = ServiceClient()
    
    @IBOutlet weak var productNameLabel: NSTextField!
    @IBOutlet weak var productDescription: NSScrollView!
    @IBOutlet weak var originalPriceLabel: NSTextField!
    @IBOutlet weak var newPriceTextField: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let textView = productDescription.documentView as! NSTextView
        textView.editable = false
        newPriceTextField.editable = false
        
        scrapeUrl(productUrl)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func scrapeUrl(sender: String) {
        service.getProduct(productUrl, success: { (product) in
            //Update UI
            self.productNameLabel.stringValue = product.name!
            self.productDescription.documentView!.textStorage!!.mutableString.setString(product.dsc!)
            self.originalPriceLabel.stringValue = product.price!
            self.newPriceTextField.stringValue = product.newPrice!
            self.imageView.kf_setImageWithURL(NSURL(string: product.imageURL!)!)


            }) { (error) in
             print("Fail!!! \(error)")
        }
    }
    
    func shell(args: String...) -> String {
        let task = NSTask()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String? = String(data: data, encoding: NSUTF8StringEncoding)
        return output!
        
//        return task.terminationStatus
    }

    @IBAction func publishNewProduct(sender: AnyObject) {
        print("Publishing new product")
    }
}

