//
//  Const.swift
//  ColorSup
//
//  Created by Krishna Panchal on 13/11/23.
//

import UIKit

// swiftlint:disable:next identifier_name
let UD = UserDefaults.standard


struct Const {


    struct StoryboardIDIB {
        static let main = "Main"
        static let magicCell = "MagicCell"
        static let magicTableVC = "MagicTableVC"
        static let advancedCell = "advancedCell"
        static let advancedTableVC = "advancedTableVC"
        static let tutorialVC = "TutorialViewController"
        static let imagePreviewVC = "ImagePreviewViewController"
    }


    struct UserDef {
        static let colorKey = "color"
        static let defaultColor = "E5E5EA"
        static let randomHistoryFilename = "colors.txt"
        static let advancedHistoryFilename = "colorsadvanced.txt"
        static let tutorialShown = "tutorialShown"
        static let xSavesShown = "xSavesShown"
    }

    struct Values {
        static let numToHexFormatter = "%02X"
        static let rgbMax = 255.0
    }

    struct AppInfo {
        static let version = "v."
        static let tutorial = "Watch Tutorial"
        static let shareApp = "Tell a Friend"
        static let addFromCamera = "Take Photo"
        static let okMessage = "OK"
        static let notNowMessage = "Not now"
        static let addFromGallery = "Choose Photo"
        static let clearImage = "Delete Photo"
        static let appVersion = "CFBundleShortVersionString"
        static let appName = "ColorSup - Color Extractor"
        static let galleryLink = "photos-redirect://"
        static let historyHeader = """
        Tap a color to restore it to the home page of the app and share it
        """
        static let creditMessage = """
        \n\(appName)
        App Developed by Krishna Panchal
        """
    }

}
