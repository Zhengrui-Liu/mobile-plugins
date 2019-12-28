import Flutter
import UIKit
import FacebookCore
import FacebookShare
import FacebookLogin

public class SwiftSharePostPlugin: NSObject, FlutterPlugin, SharingDelegate {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "share_post", binaryMessenger: registrar.messenger())
        let instance = SwiftSharePostPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getFacebookUser":
            getFacebookUser(result: result)
            break
        case "getFacebookUserPages":
            getFacebookUserPages(result: result)
            break
        case "shareOnFacebook":
            let args = call.arguments as! Dictionary<String, Any>
            let url: String = args["url"] as! String
            let message: String = args["message"] as! String
            let accessToken: String? = args["accessToken"] as? String ?? nil
            let time: NSNumber? = args["time"] as? NSNumber ?? nil
            let facebookId: String = args["facebookId"] as! String
            if( accessToken == nil ) {
                shareOnFacebookProfile(url: url, result: result)
            } else {
                shareOnFacebookPage(url: url, message: message, accessToken: accessToken, time: time, facebookId: facebookId, result: result)
            }
            break
        default:
            result(FlutterError(code: "METHOD_NOT_FOUND", message: "Method not found", details: nil))
        }
    }
    
    private func getFacebookUser(result: @escaping FlutterResult) {
        if AccessToken.current != nil {
            let request = GraphRequest(graphPath: "/me", parameters: ["fields": "id, name"], httpMethod: HTTPMethod.get)
            request.start(completionHandler: {(_ connection, _ values, _ error) in
                if let values = values as? [String : Any] {
                    if let pages = values as? Dictionary<String, String> {
                        result(pages)
                    }
                }
            })
        }
    }
    
    private func getFacebookUserPages(result: @escaping FlutterResult) {
        if AccessToken.current != nil {
            if ((AccessToken.current?.hasGranted("publish_pages"))!) && ((AccessToken.current?.hasGranted("manage_pages"))!) {
                let request = GraphRequest(graphPath: "me/accounts", parameters: ["fields": "id, name, access_token"], httpMethod: HTTPMethod.get)
                request.start(completionHandler: {(_ connection, _ values, _ error) in
                    
                    if let values = values as? [String : Any] {
                        if let pages = values["data"] as? Array<Dictionary<String, String>> {
                            result(pages)
                        }
                    }
                })
            }
        }
    }
    
    private func shareOnFacebookPage(url: String, message: String, accessToken: String?,
                                     time: NSNumber?, facebookId: String, result: @escaping FlutterResult) {
        var dict: [String:Any] = [:]
        dict["url"] = url
        dict["message"] = message
        dict["access_token"] = accessToken

        // scheduled post
        if( time != nil ) {
            dict["scheduled_publish_time"] = time
            dict["published"] = "false"
        }
        let graphPath = "\(facebookId)/photos"
        let request = GraphRequest(graphPath: graphPath, parameters: dict, tokenString: dict["access_token"] as? String, version: "v5.0", httpMethod: HTTPMethod.post)
        request.start(completionHandler: {(_ connection, _ values, _ error) in
            if( error == nil ) {
                result("POST_SENT")
            } else {
                result(FlutterError(code: "ERROR_TO_POSTING", message: "Error to posting", details: nil))
            }
        })
    }
    
    private func shareOnFacebookProfile(url: String, result: @escaping FlutterResult) {
        let url = URL(string: url)!
        let data = try? Data(contentsOf: url)
        let img = UIImage(data: data!)!
        let photo = SharePhoto(image: img, userGenerated: true)
        let content = SharePhotoContent()
        content.photos = [photo]
        let showDialog = ShareDialog(fromViewController: UIApplication.shared.keyWindow?.rootViewController, content: content, delegate: self)
        if (showDialog.canShow) {
            showDialog.show()
        } else {
            result(FlutterError(code: "FACEBOOK_APP_NOT_FOUND", message: "Facebook app not found", details: nil))
        }
    }
    
    public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
    
    public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        
    }
    
    public func sharerDidCancel(_ sharer: Sharing) {
        
    }
    
}
