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
        case "shareOnFacebookProfile":
            let args = call.arguments as! Dictionary<String, String>
            let url: String = args["url"]!
            shareOnFacebookProfile(url: url, result: result)
            break
        case "shareOnFacebookPage":
            let args = call.arguments as! Dictionary<String, String>
            let url: String = args["url"]!
            shareOnFacebookPage(url: url, result: result)
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
    
    private func shareOnFacebookPage(url: String, result: @escaping FlutterResult) {
        let url = URL(string: url)!
        let data = try? Data(contentsOf: url)
        let photo = UIImage(data: data!)!
        var dict: [String:Any] = [:]
        dict["access_token"] = "EAAFrmTrE3MABALwe404TYxIZADTSc4qoSKj6Txmo9R4ZBVIYdrW0eIwm3KuDXLFTZBZBhoGiKBUcK5xpsZBZC7MFNqu1CDBhPl0XpUut8IWFC6gRJow6RxZCYxJx8BwseyuXLaNreCV5ZA35o5olWXwm8TAvEdxZCjncT2yi2EwtTOgZDZD"
        dict["image"] = photo
        dict["message"] = "huehue"
        
        // scheduled post
        dict["scheduled_publish_time"] = 1577145600
        dict["published"] = "false"
        
        let fbId = "233753760362842"
        let graphPath = "\(fbId)/photos"
        
        let request = GraphRequest(graphPath: graphPath, parameters: dict,  httpMethod: HTTPMethod.post)
        request.start(completionHandler: {(_ connection, _ values, _ error) in
            
            let a = ""
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
