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
        self.translate()
        let channel = FlutterMethodChannel(name: "photo_editor_sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftPhotoEditorSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if( call.method == "addAllContents" ) {
            if let args = call.arguments as? Dictionary<String, Array<String>> {
                UserDefaults.standard.set(args["logos"], forKey: "logos")
                UserDefaults.standard.set(args["stickers"], forKey: "stickers")
            }
        } else if (call.method == "editImage") {
            setUpStickers()

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

        photoEditViewController.toolbar.backgroundColor = UIColor.white
        photoEditViewController.toolbar.tintColor = UIColor.black
        photoEditViewController.view.tintColor = UIColor.black
        //        photoEditViewController.toolbarItems?.forEach { i in
        //            i.color = UIColor.black
        //        }

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

    func createDefaultItems() -> [PhotoEditMenuItem] {
        let logo = PhotoEditMenuItem.tool(
            ToolMenuItem(
                title: "sua logo",
                icon: UIImage(named: "imgly_icon_tool_sticker_48pt", in: Bundle.imglyBundle, compatibleWith: nil)!,
                toolControllerClass: StickerToolController.self)!
        )
        let sticker = PhotoEditMenuItem.tool(ToolMenuItem(title: "adesivo", icon: UIImage(named: "imgly_icon_tool_sticker_48pt", in: Bundle.imglyBundle, compatibleWith: nil)!, toolControllerClass: StickerToolController.self)!)
        let text = PhotoEditMenuItem.tool(ToolMenuItem(title: "texto", icon: UIImage(named: "imgly_icon_tool_text_48pt", in: Bundle.imglyBundle, compatibleWith: nil)!, toolControllerClass: TextToolController.self)!)

        return [logo, sticker, text]
    }

    private func buildConfiguration() -> Configuration {
        let configuration = Configuration { builder in
            // Configure editor
            builder.configurePhotoEditViewController { options in
                options.menuItems = createDefaultItems()

                //options.backgroundColor = UIColor.white
                options.actionButtonConfigurationClosure = { cell, action in
                    cell.contentTintColor = UIColor(red: 121/255, green: 0, blue: 173/255, alpha: 1)
                }

//                options.applyButtonConfigurationClosure = { shareButton in
//                    shareButton.setImage(UIImage(named: "Share"), for: .normal)
//                }
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

    fileprivate static func translate() {
        PESDK.localizationDictionary = [
            "pt": [
                "No permission" : "Sem permissão",
                "Top left cropping area" : "Área de corte superior esquerda",
                "Settings" : "Configurações",
                "No Focus" : "Sem Foco",
                "Loading image" : "Carregando imagem...",
                "Transform" : "Cortar",
                "Free" : "Livre",
                "Filter" : "Filtros",
                "None" : "Nenhum",
                "Adjust" : "Ajustes",
                "Brightness" : "Brilho",
                "Contrast" : "Contraste",
                "Saturation" : "Saturação",
                "Clarity" : "Claridade",
                "Shadows" : "Sombras",
                "Highlights" : "Destaques",
                "Exposure" : "Exposição",
                "Shapes" : "Formas",
                "Sticker" : "Logo",
                "Sticker Options" : "Opções do Sticker",
                "Color" : "Cor",
                "Sticker Color" : "Cor do Sticker",
                "Flip" : "Inverter",
                "To Front" : "Sobrepor",
                "Text" : "Texto",
                "Text Design" : "Texto",
                "Add Text" : "Adicionar Texto",
                "Change Text" : "Alterar Texto",
                "Change Text Desing" : "Alterar Texto",
                "Text Options" : "Opções do Texto",
                "Font" : "Fonte",
                "Text Color" : "Cor do Texto",
                "BGColor" : "Fundo",
                "Alignment" : "Alinhamento",
                "Overlay" : "Sobreposição",
                "Golden" : "Dourado",
                "Lightleak" : "Feixe de luz",
                "Rain" : "Chuva",
                "Mosaic" : "Mosaico",
                "Vintage" : "Vintage",
                "Paper" : "Papel",
                "Frame" : "Moldura",
                "No Frame" : "Sem Moldura",
                "Loading" : "Carregando",
                "Brush" : "Pincel",
                "Brush Color" : "Cor do Pincel",
                "Size" : "Tamanho",
                "Hardness" : "Rigidez",
                "Focus" : "Foco",
                "Magic" : "Auto",
                "Discard changes?" : "Descartar alterações?",
                "All changes will be lost." : "Todas as alterações serão perdidas.",
                "Discard changes" : "Descartar alterações",
                "Cancel" : "Cancelar",
                "Saving image" : "Carregando..."
            ]
        ]
    }

    fileprivate func setUpStickers() {
        if let last = StickerCategory.all.last {
            let shapes = StickerCategory(title: "Formas", imageURL: last.imageURL, stickers: last.stickers)
            StickerCategory.all.removeAll()
            StickerCategory.all.append(shapes)
        }
        createStickerSection(key: "logos", name: "Logo", index: 0)
        createStickerSection(key: "stickers", name: "Adesivos", index: 1)
        
        // MARK: User logo & Facebook photos

        //        if let userOldLogo = userInfo!["logo_image_url"] as? String {
        //            if let logoStickerURL = URL(string: userOldLogo) {
        //                let logoSticker = Sticker(imageURL: logoStickerURL, thumbnailURL: nil, identifier: "UserLogo")
        //                images.append(logoSticker)
        //            }
        //        }
        //

    }
    
    private func createStickerSection(key: String, name: String, index: Int) {
        
        var images: [Sticker] = []
        let defaults = UserDefaults.standard
        let logos = defaults.array(forKey: key)
        var cont = 0
        logos?.forEach { logo in
            if let logoURL = URL(string: logo as! String) {
                let logoSticker = Sticker(imageURL: logoURL, thumbnailURL: nil, identifier: "\(cont) \(index)")
                cont = cont+1
                images.append(logoSticker)
            }
        }

        if !images.isEmpty {

            let logoStickerCategory = URL(string: "http://is3.mzstatic.com/image/thumb/Purple118/v4/f3/31/b8/f331b8c5-d637-d9d7-7466-d1eb79c70c3f/source/175x175bb.jpg")!
            let stickerCategory = StickerCategory(title: name, imageURL: logoStickerCategory, stickers: images)

//            if !StickerCategory.all.contains(where: { (stickerCategory) -> Bool in
//                if stickerCategory.title == key {
//                    return true
//                }
//                return false
//            }) {
                StickerCategory.all.insert(stickerCategory, at: index)
//            }
        }
    }

    private static let defaultTheme: Theme = {
        return .light
    }()

    private var theme = defaultTheme
}
