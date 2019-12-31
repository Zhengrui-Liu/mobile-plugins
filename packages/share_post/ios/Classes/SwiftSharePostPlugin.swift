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
        case "shareStoryOnInstagram" :
            let args = call.arguments as! Dictionary<String, Any>
            let url: String = args["url"] as! String
            sharePostOnInstagram(url: url, result: result)
            break
        case "shareOnWhatsapp" :
            let args = call.arguments as! Dictionary<String, Any>
            let url: String = args["url"] as! String
            shareOnWhatsapp(url: url, result: result)
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
        }
    }
    
    // private var documentsController: UIDocumentInteractionController = UIDocumentInteractionController()
    
    func sharePostOnInstagram(url: String, result: @escaping FlutterResult) {
        let kInstagramURL = "instagram://app"
        let kUTI = "com.instagram.exclusivegram"
        let kfileNameExtension = "instagram.igo"
        
        let urlImage = URL(string: url)!
        let data = try? Data(contentsOf: urlImage)
        let image2 = UIImage(data: data!)!
        
        let instagramURL = URL(string: kInstagramURL)!
        if UIApplication.shared.canOpenURL(instagramURL) {
            
            let imageData = image2.jpegData(compressionQuality: 100)
            let jpgPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(kfileNameExtension)
            
            do {
                try imageData?.write(to: URL(fileURLWithPath: jpgPath), options: .atomic)
            } catch {
                print(error)
            }
            let fileURL = URL.init(fileURLWithPath: jpgPath)
            
            let documentsController = UIDocumentInteractionController()
            documentsController.url = fileURL
            documentsController.delegate = self
            documentsController.uti = kUTI
            
            // adding caption for the image
            // documentsController.annotation = ["InstagramCaption": "instagramCaption"]
            DispatchQueue.main.async {
                documentsController.presentOpenInMenu(from: (UIApplication.shared.keyWindow?.rootViewController!.view.bounds)!,
                                                      in: (UIApplication.shared.keyWindow?.rootViewController!.view)!, animated: true)
            }
            
            
            
            //        let instagramURL = URL(string: "instagram://app")!
            //        if UIApplication.shared.canOpenURL(instagramURL) {
            //            let jpgPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("instagrammFotoToShareName.igo")
            //            if let image = image2.jpegData(compressionQuality: 1.0) {
            //                try? image.write(to: urlImage, options: Data.WritingOptions.atomic) //writeToFile(jpgPath, atomically: true)
            //                let fileURL = NSURL.fileURL(withPath: jpgPath)
            //                documentsController.url = fileURL
            //                documentsController.uti = "com.instagram.exclusivegram"
            //                let rect = CGRect.zero
            //                documentsController.presentOpenInMenu(from: rect, in: (UIApplication.shared.keyWindow?.rootViewController!.view)!, animated: true)
            //            }
            //        }
            //        else {
            //            print("Instagram not found")
            //        }
            
            //        let app = URL(string: "instagram://media?id=12345678")!
            //        if UIApplication.shared.canOpenURL(app){
            //
            //            UIApplication.shared.openURL(app)
            //        }
            //        let urlImage = URL(string: url)!
            //        let data = try? Data(contentsOf: urlImage)
            //        let image = UIImage(data: data!)!
            //
            //        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            //        let checkValidation = FileManager.default
            //        let getImagePath = paths.appending("image.igo")
            //        try? checkValidation.removeItem(atPath: getImagePath)
            //        let imageData =  image.jpegData(compressionQuality: 1.0)
            //        try? imageData?.write(to: URL.init(fileURLWithPath: getImagePath), options: .atomicWrite)
            //        var documentController : UIDocumentInteractionController!
            //        documentController = UIDocumentInteractionController.init(url: URL.init(fileURLWithPath: getImagePath))
            //        documentController.uti = "com.instagram.exclusivegram"
            //
            //        let rect = CGRect.zero
            //
            //        documentController.presentOptionsMenu(from: rect, in: (UIApplication.shared.keyWindow?.rootViewController!.view)!, animated: true)
        }
    }
    
    func shareOnWhatsapp(url: String, result: @escaping FlutterResult) {
        
        let escapedString = url.addingPercentEncoding(withAllowedCharacters:CharacterSet.urlQueryAllowed)
        let url  = URL(string: "whatsapp://send?text=\(String(describing: escapedString))")
        
        if UIApplication.shared.canOpenURL(url! as URL) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url! as URL, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
            }
        }
        
//        let urlImage = URL(string: url)!
//        let data = try? Data(contentsOf: urlImage)
//        let image = UIImage(data: data!)!
//
//        let urlWhats = "instagram://app"
//        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters:CharacterSet.urlQueryAllowed) {
//            if let whatsappURL = URL(string: urlString) {
//
//                if UIApplication.shared.canOpenURL(whatsappURL as URL) {
//
//                    guard let imageData = image.pngData() else { debugPrint("Cannot convert image to data!"); return }
//
//                    let tempFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/fitbestPhoto.igo")
//                    do {
//                        try imageData.write(to: tempFile, options: .atomic)
//                        let documentInteractionController = UIDocumentInteractionController(url: tempFile)
//                        documentInteractionController.uti = "com.instagram.exclusivegram"
//                        documentInteractionController.presentOpenInMenu(from: CGRect.zero, in: (UIApplication.shared.keyWindow?.rootViewController!.view)!, animated: true)
//
//                    } catch {
//
//                    }
//
//                } else {
//
//                }
//            }
//        }
//        https://github.com/nithinbemitk/iOS-Whatsapp-Share
//        let urlWhats: String = "whatsapp://app"
//        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
//            if let whatsappURL = URL(string: urlString) {
//
//                if UIApplication.shared.canOpenURL(whatsappURL) {
//
//                    let urlImage = URL(string: url)!
//                    let data = try? Data(contentsOf: urlImage)
//
//                    if let image = UIImage(data: data!) {
//                        let tempFile = URL(fileURLWithPath: saveImageToDocumentDirectory(image))
//                        do {
//                            let documentInteractionController = UIDocumentInteractionController()
//                            documentInteractionController.url = tempFile
//                            documentInteractionController.uti = "net.whatsapp.image"
//                            let rect = CGRect.zero
//                            documentInteractionController.presentOptionsMenu(from: rect, in: (UIApplication.shared.keyWindow?.rootViewController!.view)!, animated: true)
//                        } catch {
//                            print(error)
//                        }
//                    }
//
//                } else {
//                    // Cannot open whatsapp
//                }
//            }
//        }
    }
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage) -> String {
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"
        
        let filename = dateFormatter.string(from: Date()).appending(".wai")
        let filepath = directoryPath.appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try chosenImage.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
            return "/Documents/\(filename)"
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
    public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
    
    public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        
    }
    
    public func sharerDidCancel(_ sharer: Sharing) {
        
    }
    
    
}
