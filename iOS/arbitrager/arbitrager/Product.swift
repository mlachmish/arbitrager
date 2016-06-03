//
// Created by Matan Lachmish on 25/05/2016.
// Copyright (c) 2016 GiftApp. All rights reserved.
//

import Foundation
import ObjectMapper

class Product: NSObject, Mappable, NSCoding {
    var name: String?
    var price: String?
    var newPrice : String? {
        let newPriceDouble = (price! as NSString).doubleValue * 1.3
        return String(format:"%.1f", newPriceDouble)
    }
    var inStock: Bool?
    var dsc: String?
    var imageURL: String?

    override init() {}
    
    required init?(_ map: Map) {

    }

    func mapping(map: Map) {
        name <- map["name"]
        price <- map["price"]
        inStock <- map["inStock"]
        dsc <- map["description"]
        imageURL <- map["imageURL"]
    }

    @objc required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        self.name = aDecoder.decodeObjectForKey("name") as! String?
        self.price = aDecoder.decodeObjectForKey("price") as! String?
        self.inStock = aDecoder.decodeObjectForKey("inStock") as! Bool?
        self.dsc = aDecoder.decodeObjectForKey("description") as! String?
        self.imageURL = aDecoder.decodeObjectForKey("imageURL") as! String?
    }

    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: "name")
        aCoder.encodeObject(self.price, forKey: "price")
        aCoder.encodeObject(self.inStock, forKey: "inStock")
        aCoder.encodeObject(self.description, forKey: "description")
        aCoder.encodeObject(self.imageURL, forKey: "imageURL")
    }
}
