//
//  MakerViewController.swift
//  ColorSup
//
//  Created by Krishna Panchal on 13/11/23.
//

import UIKit
import StoreKit
import MessageUI
import AVKit
import UniformTypeIdentifiers
import PDFKit


class MakerViewController: UIViewController, UINavigationControllerDelegate,
                           UIColorPickerViewControllerDelegate, UIScrollViewDelegate,
                           UIImagePickerControllerDelegate, UIDropInteractionDelegate {

    // MARK: Outlets
    
    //UI Components
    @IBOutlet weak var aboutBtn: UIButton!
    @IBOutlet weak var deleteImg: UIButton!
    @IBOutlet weak var photoSlab: UIView!
    
    @IBOutlet weak var randomColorBtn: UIButton!
    @IBOutlet weak var editorBtn: UIButton!
    @IBOutlet weak var messageUITextView: UITextView!
    
    @IBOutlet weak var exportAsTextBtn: UIButton!
    @IBOutlet weak var exportAsFileBtn: UIButton!
    @IBOutlet weak var cameraGalleryBtn: UIButton!
    @IBOutlet weak var previousHistoryBtn: UIButton!
    @IBOutlet weak var advancedHistoryBtn: UIButton!
    @IBOutlet weak var userSelectedImg: UIImageView!
    @IBOutlet weak var containerScrollView: UIScrollView!
    
    
    // MARK: properties

    var hexArrayForRandom: [String] = []
    var hexImage: UIImage!
    let colorPicker = UIColorPickerViewController()
    let imagePicker = UIImagePickerController()
    let textViewInset: CGFloat = 16

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if CommandLine.arguments.contains("--colorSupScreenshots") {
            // We are in testing mode, make arrangements if needed
            UIView.setAnimationsEnabled(false)
        }

        containerScrollView.delegate = self
        containerScrollView.minimumZoomScale = 1.0
        containerScrollView.maximumZoomScale = 20.0
        containerScrollView.bouncesZoom = true
        containerScrollView.alwaysBounceHorizontal = true
        containerScrollView.alwaysBounceVertical = true
        userSelectedImg.isUserInteractionEnabled = true
        let doubleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(handleDoubleTap))
        doubleTapGR.numberOfTapsRequired = 2
        containerScrollView.addGestureRecognizer(doubleTapGR)
        for number in 0...Int(Const.Values.rgbMax) {
            hexArrayForRandom.append(String(format: Const.Values.numToHexFormatter, number))
        }
        elementsShould(hide: false)
        let selectedColor: UIColor = uiColorFrom(hex: getSafeHexFromUD())


        photoSlab.backgroundColor = selectedColor

        colorPicker.delegate = self
        colorPicker.supportsAlpha = false
        colorPicker.selectedColor = selectedColor
        colorPicker.title = "Advanced Editor"

        imagePicker.delegate = self

        exportAsTextBtn.menu = getShareMenu(sourceView: exportAsTextBtn)
        cameraGalleryBtn.menu = getImageMenu()
        exportAsFileBtn.menu = getFileMenu(sourceView: exportAsFileBtn)

        for button: UIButton in [aboutBtn, cameraGalleryBtn, exportAsTextBtn,
                                 exportAsFileBtn] {
            button.showsMenuAsPrimaryAction = true
        }

        for button: UIButton in [editorBtn, cameraGalleryBtn,
                                 exportAsTextBtn, randomColorBtn, previousHistoryBtn,
                                 advancedHistoryBtn, exportAsFileBtn] {
            button.clipsToBounds = true
//            button.layer.cornerRadius = 8
//            button.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }


        let dropInteraction = UIDropInteraction(delegate: self)
        userSelectedImg.addInteraction(dropInteraction)

//        messageUITextView.isScrollEnabled = false
        
        //UI Button Components Setup
        randomColorBtn.layer.cornerRadius = 16
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UD.bool(forKey: Const.UserDef.tutorialShown) {
            showTutorial()
            UD.set(true, forKey: Const.UserDef.tutorialShown)
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }


    // MARK: Helpers

    func showTutorial() {
        let storyboard = UIStoryboard(name: Const.StoryboardIDIB.main, bundle: nil)
        let tutorialVC = storyboard.instantiateViewController(
            withIdentifier: Const.StoryboardIDIB.tutorialVC)
        present(tutorialVC, animated: true)
    }


    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if containerScrollView.zoomScale < containerScrollView.maximumZoomScale { // zoom in
            let point = recognizer.location(in: userSelectedImg)

            let scrollSize = containerScrollView.frame.size
            let size = CGSize(width: scrollSize.width / containerScrollView.maximumZoomScale,
                              height: scrollSize.height / containerScrollView.maximumZoomScale)
            let origin = CGPoint(x: point.x - size.width / 2,
                                 y: point.y - size.height / 2)
            containerScrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        } else { // zoom out
            containerScrollView.zoom(
                to: zoomRectForScale(scale: containerScrollView.maximumZoomScale,
                                     center: recognizer.location(in: userSelectedImg)),
                animated: true)
        }
    }


    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = userSelectedImg.frame.size.height / scale
        zoomRect.size.width  = userSelectedImg.frame.size.width  / scale
        let newCenter = containerScrollView.convert(center, from: userSelectedImg)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }


    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return userSelectedImg
    }


    // MARK: Update Color

    func updateColor(hexStringParam: String) {
        let mySafeString: String = hexStringParam
        let selectedColor: UIColor = uiColorFrom(hex: mySafeString)
        self.photoSlab.backgroundColor = selectedColor
        colorPicker.selectedColor = selectedColor

        UD.set(mySafeString, forKey: Const.UserDef.colorKey)

    }


    // MARK: Buttons

    fileprivate func tryShowingCamera() {
        DispatchQueue.main.async {
            // already authorized
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: nil)
            } else {
                let alert = self.createAlert(alertReasonParam: AlertReason.unknown,
                                             okMessage: Const.AppInfo.okMessage)
                self.present(alert, animated: true)
            }
        }

    }


    func getImageMenu() -> UIMenu {
        let newImageFromCamera = UIAction(title: Const.AppInfo.addFromCamera,
                                          image: UIImage(systemName: "camera"),
                                          state: .off) { _ in
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                self.tryShowingCamera()
            } else {
                AVCaptureDevice.requestAccess(for: .video,
                                              completionHandler: { [self] (granted: Bool) in
                    if granted {
                        // access allowed
                        tryShowingCamera()
                    } else {
                        // access denied
                        let alert = createAlert(
                            alertReasonParam: AlertReason.permissiondeniedCamera,
                            okMessage: Const.AppInfo.notNowMessage)
                        let goToSettingsButton = UIAlertAction(title: "Open Settings",
                                                               style: .default, handler: { _ in
                            if let url = NSURL(string: UIApplication.openSettingsURLString)
                                as URL? {
                                UIApplication.shared.open(url)
                            }

                        })
                        alert.addAction(goToSettingsButton)
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = cameraGalleryBtn
                        }
                        DispatchQueue.main.async { [self] in
                            present(alert, animated: true)
                        }
                    }
                })
            }
        }
        let newImageFromGallery = UIAction(
            title: Const.AppInfo.addFromGallery,
            image: UIImage(systemName: "photo.fill.on.rectangle.fill"),
            state: .off) { _ in
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    self.imagePicker.sourceType = .photoLibrary
                    self.imagePicker.allowsEditing = false

                    DispatchQueue.main.async {
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }

                }
            }

        let imageMenu = UIMenu(title: "", image: nil, options: .displayInline,
                               children: [newImageFromCamera, newImageFromGallery])
        return imageMenu
    }


    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo
                               info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        userSelectedImg.image = image
        self.userSelectedImg.accessibilityLabel = "Image"
        containerScrollView.zoomScale = containerScrollView.minimumZoomScale
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func historyButtonTapped() {
        let magicVC = UIStoryboard(name: Const.StoryboardIDIB.main, bundle: nil)
            .instantiateViewController(withIdentifier: Const.StoryboardIDIB.magicTableVC)

        self.navigationController?.pushViewController(magicVC, animated: true)

    }


    @IBAction func advancedHistoryTapped() {
        let advancedVC = UIStoryboard(name: Const.StoryboardIDIB.main, bundle: nil)
            .instantiateViewController(withIdentifier: Const.StoryboardIDIB.advancedTableVC)

        self.navigationController?.pushViewController(advancedVC, animated: true)
    }
    
    @IBAction func showTutorialBtn(_ sender: UIButton) {
        showTutorial()
    }
    
    @IBAction func deleteImg(_ sender: UIButton) {
        self.userSelectedImg.image = nil
        self.userSelectedImg.accessibilityLabel = ""
    }

    func presentImagePreview() {
        let imagePreviewVC = UIStoryboard(
            name: Const.StoryboardIDIB.main, bundle: nil).instantiateViewController(
                withIdentifier: Const.StoryboardIDIB.imagePreviewVC)
        as! ImagePreviewViewController
        imagePreviewVC.actualImage = hexImage!
        present(imagePreviewVC, animated: true)
    }


    @objc func generateImage() {

        elementsShould(hide: true)

        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white]
        let creditsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.white]
        let hexString = getSafeHexFromUD()
        let myUIColor = uiColorFrom(hex: hexString)

        let attrCredits = NSAttributedString(
            string: Const.AppInfo.creditMessage,
            attributes: creditsAttributes)

        let myAttributedText = NSMutableAttributedString()

        let colorFullDictString = getDictForSelectedColor()
        let attrDictString = NSAttributedString(
            string: colorFullDictString,
            attributes: regularAttributes)

        myAttributedText.append(attrDictString)
        myAttributedText.append(attrCredits)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        myAttributedText.addAttribute(
            .paragraphStyle, value: paragraphStyle,
            range: NSRange(location: 0, length: myAttributedText.length))

        messageUITextView.attributedText = myAttributedText
        messageUITextView.textContainerInset = UIEdgeInsets(
            top: textViewInset,
            left: textViewInset,
            bottom: textViewInset,
            right: textViewInset)

        messageUITextView.sizeToFit()

        let viewColorWas = view.backgroundColor
        view.backgroundColor = myUIColor

        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        hexImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        view.backgroundColor = viewColorWas
        elementsShould(hide: false)
    }


    func getDictForSelectedColor() -> String {
        var aString = ""
        for format in ExportFormat.allCases {
            let thing = hexTo(format: format)
            aString.append("\(thing)\n")
        }
        return aString
    }


    func getFileMenu(sourceView: UIView) -> UIMenu {

        // MARK: Copy options
        let getImage = UIAction(
            title: "Generate Screenshot",
            image: UIImage(systemName: "photo")) { _ in
                self.generateImage()
                self.presentImagePreview()
            }
        let sharePDF = UIAction(
            title: "Share as PDF",
            image: UIImage(systemName: "doc.text")) { _ in
                self.shareAsPDF()
            }

        let exportAsFileMenu = UIMenu(options: .displayInline, children: [
            getImage,
            sharePDF])
        return exportAsFileMenu
    }


    func shareAsPDF() {
        generateImage()
        let image: UIImage = hexImage
        let myURL = createPDFDataFromImage(image: image)

        guard let mySafeURL = myURL else {
            let alert = createAlert(alertReasonParam: .unknown, okMessage: "OK")
            present(alert, animated: true)
            return
        }

        let activityController = UIActivityViewController(activityItems: [mySafeURL],
                                                          applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = exportAsFileBtn
        activityController
            .completionWithItemsHandler = { (_, _: Bool, _: [Any]?, error: Error?) in
                guard error == nil else {
                    let alert = self.createAlert(alertReasonParam: AlertReason.unknown,
                                                 okMessage: Const.AppInfo.okMessage)
                    if let presenter = alert.popoverPresentationController {
                        presenter.sourceView = self.exportAsFileBtn
                    }
                    DispatchQueue.main.async {
                        self.present(alert, animated: true)
                    }
                    return
                }
            }
        DispatchQueue.main.async {
            self.present(activityController, animated: true)
        }
    }


    func createPDFDataFromImage(image: UIImage) -> URL? {
        let pdfData = NSMutableData()
        let imgView = UIImageView.init(image: image)
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        UIGraphicsBeginPDFContextToData(pdfData, imageRect, nil)
        UIGraphicsBeginPDFPage()
        let context = UIGraphicsGetCurrentContext()
        imgView.layer.render(in: context!)
        UIGraphicsEndPDFContext()

        // try saving in doc dir to confirm:
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let path = dir?.appendingPathComponent("""
        \(getSafeHexFromUD()) \(Const.AppInfo.appName) by Daniel Springer.pdf
        """)

        guard let safePath = path else {
            return nil
        }

        do {
            try pdfData.write(to: safePath, options: .atomic)
        } catch {
            let alert = createAlert(alertReasonParam: .unknown,
                                    okMessage: Const.AppInfo.okMessage)
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = exportAsFileBtn
            }
            DispatchQueue.main.async {
                self.present(alert, animated: true)
            }
        }

        return safePath
    }


    func elementsShould(hide: Bool) {
        messageUITextView.isHidden = !hide
        for button: UIButton in [aboutBtn, editorBtn, cameraGalleryBtn,
                                 exportAsTextBtn, randomColorBtn, previousHistoryBtn,
                                 advancedHistoryBtn, exportAsFileBtn, deleteImg] {
            button.isHidden = hide
        }
        containerScrollView.isHidden = hide
    }


    @IBAction func pickerMenuButtonTapped() {
        let selectedColor: UIColor = uiColorFrom(hex: getSafeHexFromUD())
        colorPicker.selectedColor = selectedColor
        DispatchQueue.main.async { [self] in
            colorPicker.popoverPresentationController?.sourceView = editorBtn
            present(colorPicker, animated: true)
            if !UD.bool(forKey: Const.UserDef.xSavesShown) {
                let alert = createAlert(alertReasonParam: .xSaves, okMessage: "I understand")
                colorPicker.present(alert, animated: true)
                UD.set(true, forKey: Const.UserDef.xSavesShown)
            }
        }

    }


    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let hexString = hexStringFromColor(color: colorPicker.selectedColor)
        updateColor(hexStringParam: hexString)
        saveToFiles(color: hexString, filename: Const.UserDef.advancedHistoryFilename)
    }


    // MARK: Random

    @IBAction func randomTapped(_ sender: Any) {
        makeRandomColor()
    }


    public func makeRandomColor() {
        var randomHex = ""
        let randomRed = hexArrayForRandom.randomElement()!
        let randomGreen = hexArrayForRandom.randomElement()!
        let randomBlue = hexArrayForRandom.randomElement()!

        randomHex = randomRed + randomGreen + randomBlue

        updateColor(hexStringParam: randomHex)
        saveToFiles(color: randomHex, filename: Const.UserDef.randomHistoryFilename)
    }


}

extension MakerViewController {

    func dropInteraction(_ interaction: UIDropInteraction,
                         canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [UTType.image.identifier]) &&
        session.items.count == 1
    }


    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let dropLocation = session.location(in: view)
        //        updateLayers(forDropLocation: dropLocation)

        let operation: UIDropOperation

        if userSelectedImg.frame.contains(dropLocation) {
            /*
             If you add in-app drag-and-drop support for the .move operation,
             you must write code to coordinate between the drag interaction
             delegate and the drop interaction delegate.
             */
            userSelectedImg.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.7)
            operation = session.localDragSession == nil ? .copy : .move
        } else {
            // Do not allow dropping outside of the image view.
            userSelectedImg.backgroundColor = .clear
            operation = .cancel
        }
        return UIDropProposal(operation: operation)
    }


    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        // Consume drag items (in this example, of type UIImage).
        session.loadObjects(ofClass: UIImage.self) { imageItems in
            let images = imageItems as! [UIImage]

            /*
             If you do not employ the loadObjects(ofClass:completion:) convenience
             method of the UIDropSession class, which automatically employs
             the main thread, explicitly dispatch UI work to the main thread.
             For example, you can use `DispatchQueue.main.async` method.
             */
            self.userSelectedImg.image = images.first
            self.userSelectedImg.backgroundColor = .clear
        }

        // Perform additional UI updates as needed.
        // let dropLocation = session.location(in: view)
    }

}


// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(
    _ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in
            (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }


// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIImagePickerControllerInfoKey(
    _ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }


// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIImagePickerControllerInfoKeyDictionary(
    _ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

