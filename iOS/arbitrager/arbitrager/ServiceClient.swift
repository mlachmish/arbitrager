//
// Created by Matan Lachmish on 24/05/2016.
// Copyright (c) 2016 GiftApp. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

struct ServiceClientConstants{
    static let BASE_URL_PATH = "http://localhost:8080"
}

public class ServiceClient: NSObject {

    var manager : Manager!

    //-------------------------------------------------------------------------------------------
    // MARK: - Initialization & Destruction
    //-------------------------------------------------------------------------------------------
    internal dynamic override init() {
        super.init()
//        self.allowUnsecureConnection()
    }

    func allowUnsecureConnection() {
        self.manager.delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
            var credential: NSURLCredential?

            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = NSURLSessionAuthChallengeDisposition.UseCredential
                credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .CancelAuthenticationChallenge
                } else {
                    credential = self.manager.session.configuration.URLCredentialStorage?.defaultCredentialForProtectionSpace(challenge.protectionSpace)

                    if credential != nil {
                        disposition = .UseCredential
                    }
                }
            }

            return (disposition, credential)
        }
    }
    
    func getProduct(url : String,
                    success: (product : Product) -> Void,
               failure: (error: ErrorType) -> Void) {

        Alamofire.request(.GET, ServiceClientConstants.BASE_URL_PATH+"/product", headers: ["amazonURL":url]).validate().responseObject { (response: Response<Product, NSError>) in
            switch response.result {
            case .Success:
                let product = response.result.value
                success(product: product!)
            case .Failure(let error):
                failure(error: error)
            }
        }
    }
    
    func publish(product : Product,
                    success: () -> Void,
                    failure: (error: ErrorType) -> Void) {
        
        Alamofire.request(.POST, ServiceClientConstants.BASE_URL_PATH+"/publish", parameters: ["name":product.name!, "price":product.newPrice!, "description":product.dsc!, "imageURL":product.imageURL!], encoding: .JSON).validate().responseObject { (response: Response<Product, NSError>) in
            switch response.result {
            case .Success:
                success()
            case .Failure(let error):
                failure(error: error)
            }
        }
    }

}