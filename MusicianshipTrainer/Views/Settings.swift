
import Foundation

import SwiftUI

enum UserDefaultKeys {
    static let selectedColorScore = "SelectedColorScore"
    static let selectedColorInstructions = "SelectedColorInstructions"
    static let selectedColorBackground = "SelectedColorBackground"
    static let selectedAgeGroup = "SelectedAgeGroup"
    static let showReloadHTMLButton = "showReloadHTMLButton"
    static let useTestData = "useTestData"
    static let useAnimations = "useAnimations"
    static let soundOnTaps = "soundOnTaps"
    static let useUpstrokeTaps = "useUpstrokeTaps"
}

extension UserDefaults {
    func setSelectedColor(key:String, _ color: Color) {
        set(color.rgbData, forKey: key)
    }

    func getSelectedColor(key:String) -> Color? {
        guard let data = data(forKey: key) else { return nil }
        return Color.rgbDataToColor(data)
    }
    
    func setSelectedAgeGroup(key:String, _ ageGroup: AgeGroup) {
        var age = 0
        if ageGroup == .Group_5To10 {
            age = 0
        }
        else {
            age = 1
        }
        
        let data = withUnsafeBytes(of: age) { Data($0) }
        set(data, forKey: key)
    }

    func getSelectedAgeGroup(key:String) -> AgeGroup? {
        guard let data = data(forKey: key) else { return nil }
        let age  = data.withUnsafeBytes { $0.load(as: Int.self) }
        return age == 0 ? .Group_5To10 : .Group_11Plus
    }
    
//    func setShowReloadHTMLButton(key:String, _ way: Bool) {
//        set(way, forKey: key)
//        log()
//    }
    
    func setBoolean(key:String, _ way: Bool) {
        set(way, forKey: key)
    }
    
    func getBoolean(key:String) -> Bool {
        return bool(forKey: key)
    }
    
    func getUseTestData(key:String) -> Bool {
        return bool(forKey: key)
    }
    
    func log() {
        let userDefaults = UserDefaults.standard
        let allValues = userDefaults.dictionaryRepresentation()

        for (key, value) in allValues {
            print("Key: \(key), Value: \(value)")
        }
    }
}

extension Color {
    var rgbData: Data {
        let uiColor = UIColor(self)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        return data ?? Data()
    }
    
    static func rgbDataToColor(_ data: Data) -> Color? {
        guard let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return nil
        }
        return Color(uiColor)
    }
}

class Settings : ObservableObject {
    var id = UUID()
    let AGE_GROUP_11_PLUS = "11Plus"
    @Published var useTestData = false
    @Published var showReloadHTMLButton = false
    @Published var useAnimations = false
    @Published var ageGroup:AgeGroup = .Group_11Plus
    @Published var colorScore = UIGlobals.colorScoreDefault
    @Published var colorInstructions = UIGlobals.colorInstructionsDefault
    ///Color of each test's screen background
    @Published var colorBackground = UIGlobals.colorBackgroundDefault
    @Published var soundOnTaps = true
    @Published var useUpstrokeTaps = false //Turned off for the moment. Possibly will never use and always use downstrokes

    static var shared = Settings()
    
    init() {
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorScore) {
            colorScore = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorInstructions) {
            colorInstructions = retrievedColor
        }
        if let retrievedColor = UserDefaults.standard.getSelectedColor(key: UserDefaultKeys.selectedColorBackground) {
            colorBackground = retrievedColor
        }
        if let retrievedAgeGroup = UserDefaults.standard.getSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup) {
            ageGroup = retrievedAgeGroup
        }
        showReloadHTMLButton = UserDefaults.standard.getBoolean(key: UserDefaultKeys.showReloadHTMLButton)
        useTestData = UserDefaults.standard.getUseTestData(key: UserDefaultKeys.useTestData)
        useAnimations = UserDefaults.standard.getUseTestData(key: UserDefaultKeys.useAnimations)
        soundOnTaps = UserDefaults.standard.getUseTestData(key: UserDefaultKeys.useAnimations)
        useUpstrokeTaps = UserDefaults.standard.getUseTestData(key: UserDefaultKeys.useUpstrokeTaps)
    }
    
    init(copy settings: Settings) {
        self.useTestData = settings.useTestData
        self.showReloadHTMLButton = settings.showReloadHTMLButton
        self.useAnimations = settings.useAnimations
        self.ageGroup = settings.ageGroup
        self.colorScore = settings.colorScore
        self.colorInstructions = settings.colorInstructions
        self.colorBackground = settings.colorBackground
        self.soundOnTaps = settings.soundOnTaps
        self.useUpstrokeTaps = settings.useUpstrokeTaps
    }
    
    func getAgeGroup() -> String {
        return ageGroup == .Group_11Plus ? AGE_GROUP_11_PLUS : "5-10"
    }

    func saveConfig() {
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorScore, colorScore)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorInstructions, colorInstructions)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorBackground, colorBackground)
        UserDefaults.standard.setSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup, ageGroup)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.showReloadHTMLButton, showReloadHTMLButton)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useTestData, useTestData)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useAnimations, useAnimations)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.soundOnTaps, soundOnTaps)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useUpstrokeTaps, useUpstrokeTaps)
    }
    
}
