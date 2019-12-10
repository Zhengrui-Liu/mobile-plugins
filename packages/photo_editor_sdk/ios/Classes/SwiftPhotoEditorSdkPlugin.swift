import Flutter
import UIKit
import PhotoEditorSDK

@available(iOS 9.0, *)
public class SwiftPhotoEditorSdkPlugin: NSObject, FlutterPlugin, PhotoEditViewControllerDelegate {
    
    var controller: UIViewController!
    var globalResult: FlutterResult!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        if let licenseURL = Bundle.main.url(forResource: "license", withExtension: "") {
            PESDK.unlockWithLicense(at: licenseURL)
        }
        let channel = FlutterMethodChannel(name: "photo_editor_sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftPhotoEditorSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "editImage") {
            controller = UIApplication.shared.keyWindow?.rootViewController
            globalResult = result
            let args = call.arguments as! String
            do {
                let url = URL(string: args)!
                let data = try Data(contentsOf: url)
                let image2 = UIImage(data: data)!
                let image = Photo(image: image2)
                self.presentPhotoEditViewController(photo: image)
            } catch {
                print(error)
            }
        }
    }
    private func presentPhotoEditViewController(photo: Photo) {
        DispatchQueue.main.async {
            self.controller.present(self.createPhotoEditViewController(with: photo), animated: true, completion: nil)
        }
    }
    
    private func createPhotoEditViewController(with photo: Photo, and photoEditModel: PhotoEditModel = PhotoEditModel()) -> PhotoEditViewController {
        let configuration = buildConfiguration()
        
        // Create a photo edit view controller
        let photoEditViewController = PhotoEditViewController(photoAsset: photo, configuration: configuration, photoEditModel: photoEditModel)
        photoEditViewController.modalPresentationStyle = .fullScreen
        photoEditViewController.delegate = self
        
        return photoEditViewController
    }
    
    public func photoEditViewController(_ photoEditViewController: PhotoEditViewController, didSave image: UIImage, and data: Data) {
        if let navigationController = photoEditViewController.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            globalResult(data)

            controller.dismiss(animated: true, completion: nil)
        }
    }

    public func photoEditViewControllerDidFailToGeneratePhoto(_ photoEditViewController: PhotoEditViewController) {
        if let navigationController = photoEditViewController.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true, completion: nil)
        }
    }

    public func photoEditViewControllerDidCancel(_ photoEditViewController: PhotoEditViewController) {
        if let navigationController = photoEditViewController.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
    private func buildConfiguration() -> Configuration {
        let configuration = Configuration { builder in
            // Configure camera
            builder.configureCameraViewController { options in
                // Just enable photos
                options.allowedRecordingModes = [.photo]
                // Show cancel button
                options.showCancelButton = true
            }
            
            // Configure editor
            builder.configurePhotoEditViewController { options in
                var menuItems = PhotoEditMenuItem.defaultItems
                menuItems.removeLast() // Remove last menu item ('Magic')
                options.menuItems = menuItems
            }
            
            // Configure sticker tool
            builder.configureStickerToolController { options in
                // Enable personal stickers
                options.personalStickersEnabled = true
            }
            
            // Configure theme
            builder.theme = self.theme
        }
        
        return configuration
    }
    
    private static let defaultTheme: Theme = {
        return .dark
    }()
    
    private var theme = defaultTheme
}
