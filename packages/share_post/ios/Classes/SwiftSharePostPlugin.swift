import Flutter
import UIKit
import FacebookCore
import FacebookShare
import FacebookLogin

public class SwiftSharePostPlugin: NSObject, FlutterPlugin, SharingDelegate, UIDocumentInteractionControllerDelegate {
    
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
            let url: String? = args["url"] as? String ?? nil
            let message: String = args["message"] as! String
            let accessToken: String? = args["accessToken"] as? String ?? nil
            let time: NSNumber? = args["time"] as? NSNumber ?? nil
            let facebookId: String = args["facebookId"] as! String
            if( accessToken == nil ) {
                shareOnFacebookProfile(url: url, message: message, result: result)
            } else {
                shareOnFacebookPage(url: url, message: message, accessToken: accessToken, time: time, facebookId: facebookId, result: result)
            }
            break
        case "shareStoryOnInstagram" :
            let args = call.arguments as! Dictionary<String, Any>
            let url: String = args["url"] as! String
            shareStoryOnInstagram(url: url, result: result)
            break
        case "sharePostOnInstagram" :
            let args = call.arguments as! Dictionary<String, Any>
            let url: String = args["url"] as! String
            sharePostOnInstagram(url: url, result: result)
            break
        case "shareOnWhatsapp" :
            let args = call.arguments as! Dictionary<String, Any>
            let url: String? = args["url"] as? String ?? nil
            let message: String! = args["message"] as? String ?? ""
            if( url != nil ) {
                shareOnWhatsapp(url: url, app: "whatsapp://app", result: result)
            } else {
                let messageEncoded = message.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
                shareOnWhatsapp(url: url, app: "whatsapp://send?text=" + messageEncoded, result: result)
            }
            break
        case "openAppOnStore" :
            let args = call.arguments as! Dictionary<String, Any>
            let appUrl: String = args["appUrl"] as! String
            openAppOnStore(appUrl: appUrl)
            break
        case "shareOnNative" :
            let args = call.arguments as! Dictionary<String, Any>
            let url: String? = args["url"] as? String ?? nil
            let message: String? = args["message"] as? String ?? nil
            shareOnNative(url: url, message: message, result: result)
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
    
    private func shareOnFacebookPage(url: String?, message: String, accessToken: String?,
                                     time: NSNumber?, facebookId: String, result: @escaping FlutterResult) {
        var dict: [String:Any] = [:]
        if( url != nil ) {
            dict["url"] = url
        }
        dict["message"] = message
        dict["access_token"] = accessToken
        
        // scheduled post
        if( time != nil ) {
            dict["scheduled_publish_time"] = time
            dict["published"] = "false"
        }
        
        let partPath = ( url != nil ) ? "photos" : "feed"
        let graphPath = "\(facebookId)/\(partPath)"
        let request = GraphRequest(graphPath: graphPath, parameters: dict, tokenString: dict["access_token"] as? String, version: "v5.0", httpMethod: HTTPMethod.post)
        request.start(completionHandler: {(_ connection, _ values, _ error) in
            if( error == nil ) {
                result("POST_SENT")
            } else {
                result(FlutterError(code: "ERROR_TO_POSTING", message: "Error to posting", details: nil))
            }
        })
    }
    
    private func shareOnFacebookProfile(url: String?, message: String?, result: @escaping FlutterResult) {
        var content:SharingContent? = nil
        if( url != nil ) {
            let url = URL(string: url!)!
            let data = try? Data(contentsOf: url)
            let img = UIImage(data: data!)!
            let photo = SharePhoto(image: img, userGenerated: true)
            content = SharePhotoContent()
            (content as! SharePhotoContent).photos = [photo]
        } else {
            content = ShareLinkContent()
            (content as! ShareLinkContent).quote = message
        }
                
        let showDialog = ShareDialog(fromViewController: UIApplication.shared.keyWindow?.rootViewController, content: content!, delegate: self)
        if (showDialog.canShow) {
            showDialog.show()
            result("POST_SENT")
        } else {
            result(FlutterError(code: "APP_NOT_FOUND", message: "Facebook app not found", details: nil))
        }
    }
    
    func shareStoryOnInstagram(url: String, result: @escaping FlutterResult){
        let app = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(app){
            let urlImage = URL(string: url)!
            let data = try? Data(contentsOf: urlImage)
            let img = UIImage(data: data!)!
            
            let backgroundData = img.jpegData(compressionQuality: 1.0)!
            let pasteBoardItems = [
                ["com.instagram.sharedSticker.backgroundImage" : backgroundData],
            ]
            if #available(iOS 10.0, *) {
                UIPasteboard.general.setItems(pasteBoardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
            } else {
                UIPasteboard.general.items = pasteBoardItems
            }
            UIApplication.shared.openURL(app)
            result("POST_SENT")
        } else {
            result(FlutterError(code: "APP_NOT_FOUND", message: "Instagram app not found", details: nil))
        }
    }
    
    func sharePostOnInstagram(url: String, result: @escaping FlutterResult) {
        let app = URL(string: "instagram://app")!
        if UIApplication.shared.canOpenURL(app){
            let urlImage = URL(string: url)!
            let data = try? Data(contentsOf: urlImage)
            let photo = UIImage(data: data!)!
            
            let documentsController = UIActivityViewController.init(activityItems: [photo], applicationActivities: nil)
            
            documentsController.excludedActivityTypes = [ .postToFacebook, .postToTwitter, .postToWeibo,
                                                          .message, .mail, .print, .copyToPasteboard,
                                                          .assignToContact, .saveToCameraRoll, .addToReadingList,
                                                          .postToFlickr, .postToVimeo, .postToTencentWeibo, .airDrop]
            UIApplication.shared.keyWindow?.rootViewController?.present(documentsController, animated: true, completion: nil)
            result("POST_SENT")
        } else {
            result(FlutterError(code: "APP_NOT_FOUND", message: "Instagram app not found", details: nil))
        }
        
        
        //let urlImage = URL(string: url)!
        //let data = try? Data(contentsOf: urlImage)
        //let photo = UIImage(data: data!)!
        //
        //let instagramURL = URL(string: "instagram://app")!
        //
        //if UIApplication.shared.canOpenURL(instagramURL) {
        //    let imageData = photo.jpegData(compressionQuality: 1.0)!
        //
        //    let writePath = URL(fileURLWithPath: NSTemporaryDirectory() as String).appendingPathComponent("instagram.ig")
        //
        //    do {
        //        try imageData.write(to: writePath, options: .atomic)
        //        let documentsInteractionsController = UIDocumentInteractionController(url: writePath)
        //        documentsInteractionsController.delegate = self
        //        documentsInteractionsController.uti = writePath.uti
        //        documentsInteractionsController.presentOpenInMenu(from: CGRect.zero,
        //                                                          in: (UIApplication.shared.keyWindow?.rootViewController!.view)!,
        //                                                          animated: true)
        //
        //
        //    } catch {
        //        return
        //    }
        //
        //
        //}
    }
    
    func shareOnWhatsapp(url: String?, app: String, result: @escaping FlutterResult) {
        let app = URL(string: app)!
        if UIApplication.shared.canOpenURL(app){
            if( url != nil ) {
                let urlImage = URL(string: url!)!
                let data = try? Data(contentsOf: urlImage)
                let photo = UIImage(data: data!)!
                let documentsController = UIActivityViewController.init(activityItems: [photo], applicationActivities: nil)
                documentsController.excludedActivityTypes = [ .postToFacebook, .postToTwitter, .postToWeibo,
                                                              .message, .mail, .print, .copyToPasteboard,
                                                              .assignToContact, .saveToCameraRoll, .addToReadingList,
                                                              .postToFlickr, .postToVimeo, .postToTencentWeibo, .airDrop]
                UIApplication.shared.keyWindow?.rootViewController?.present(documentsController, animated: true, completion: nil)
            } else {
                UIApplication.shared.openURL(app)
            }
            result("POST_SENT")
        } else {
            result(FlutterError(code: "APP_NOT_FOUND", message: "WhatsApp app not found", details: nil))
        }
        
        //let urlWhats = app
        //if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters:CharacterSet.urlQueryAllowed) {
        //    if let whatsappURL = URL(string: urlString) {
        //
        //        if UIApplication.shared.canOpenURL(whatsappURL as URL) {
        //
        //            if let image = UIImage(named: "fastfood.jpg") {
        //                if let imageData = image.jpegData(compressionQuality: 1.0) {
        //                    let tempFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/whatsAppTmp.wai")
        //                    do {
        //                        try imageData.write(to: tempFile, options: .atomic)
        //                        let documentInteractionController = UIDocumentInteractionController(url: tempFile)
        //                        documentInteractionController.uti = "public.url"
        //                        documentInteractionController.presentOpenInMenu(from: CGRect.zero, in: (UIApplication.shared.keyWindow?.rootViewController!.view)!, animated: true)
        //
        //                    } catch {
        //                        print(error)
        //                    }
        //                }
        //            }
        //
        //        } else {
        //            // Cannot open whatsapp
        //        }
        //    }
        //}
    }
    
    func shareOnNative(url: String?, message: String?, result: @escaping FlutterResult) {
        if( url != nil ) {
            let urlImage = URL(string: url!)!
            let data = try? Data(contentsOf: urlImage)
            let photo = UIImage(data: data!)!
            let documentsController = UIActivityViewController.init(activityItems: [photo], applicationActivities: nil)
            documentsController.excludedActivityTypes = [ .postToFacebook ]
            UIApplication.shared.keyWindow?.rootViewController?.present(documentsController, animated: true, completion: nil)
        } else {
            let documentsController = UIActivityViewController.init(activityItems: [message!], applicationActivities: nil)
            documentsController.excludedActivityTypes = [ .postToFacebook ]
            UIApplication.shared.keyWindow?.rootViewController?.present(documentsController, animated: true, completion: nil)
        }
    }
    
    func openAppOnStore(appUrl: String) {
        let app = URL(string: appUrl)!
        UIApplication.shared.openURL(app)
    }
    
    public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
    
    public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        
    }
    
    public func sharerDidCancel(_ sharer: Sharing) {
        
    }
    
}
