//
//  MainViewController.swift
//  arbitrager
//
//  Created by Matan Lachmish on 02/06/2016.
//  Copyright © 2016 arbitrager. All rights reserved.
//

import Cocoa
import Foundation

class MainViewController: NSViewController {

    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var goButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ProductDetailSegue" {
            let productVC = segue.destinationController as! ProductViewController
            productVC.productUrl = urlTextField.stringValue
            print("Showing product page \(productVC.productUrl)")
        }
    }

}

