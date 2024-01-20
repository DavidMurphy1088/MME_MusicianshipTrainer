import Foundation
import SwiftUI
import CommonLibrary

enum UserDefaultKeys {
    static let selectedColorScore = "SelectedColorScore"
    static let selectedColorInstructions = "SelectedColorInstructions"
    static let selectedColorBackground = "SelectedColorBackground"
    static let selectedAgeGroup = "SelectedAgeGroup"
    static let selectedBackgroundsSet = "SelectedBackgroundsSet"
    static let showReloadHTMLButton = "showReloadHTMLButton"
    static let useTestData = "useTestData"
    static let useAnimations = "useAnimations"
    static let soundOnTaps = "soundOnTaps"
    static let useUpstrokeTaps = "useUpstrokeTaps"
    static let companionOn = "companionOn"
    static let useAcousticKeyboard = "useAcousticKeyboard"
    static let licenseEmail = "licenseEmail"
}    

public enum AgeGroup: Int, CaseIterable, Identifiable {
    case Group_5To10 = 0
    case Group_11Plus = 1

    public var id: Self { self }
    
    public var displayName: String {
        switch self {
        case .Group_5To10:
            return "5 to 10"
        case .Group_11Plus:
            return "11 Plus"
        }
    }
}

public enum BackgroundsSet: Int, CaseIterable, Identifiable {
    case scene = 0
    case people = 1
    
    public var id: Self { self }
    
    public var displayName: String {
        switch self {
        case .scene:
            return "Scene"
        case .people:
            return "People"
        }
    }
}

public enum QuestionType {
    //intervals
    case intervalVisual
    case intervalAural
    //rhythms
    case rhythmVisualClap
    case melodyPlay
    case rhythmEchoClap
    case none
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
    
    func setSelectedBackgroundSet(key:String, _ backgroundsSet: BackgroundsSet) {
        var bkg = 0
        if backgroundsSet == .scene {
            bkg = 0
        }
        else {
            bkg = 1
        }
        
        let data = withUnsafeBytes(of: bkg) { Data($0) }
        set(data, forKey: key)
    }

    func getSelectedAgeGroup(key:String) -> AgeGroup? {
        guard let data = data(forKey: key) else { return nil }
        let age  = data.withUnsafeBytes { $0.load(as: Int.self) }
        return age == 0 ? .Group_5To10 : .Group_11Plus
    }
    
    func getSelectedBackgroundSet(key:String) -> BackgroundsSet? {
        guard let data = data(forKey: key) else { return nil }
        let bkg  = data.withUnsafeBytes { $0.load(as: Int.self) }
        return bkg == 0 ? .scene : .people
    }

    func setBoolean(key:String, _ way: Bool) {
        set(way, forKey: key)
    }
    
    func setString(key:String, _ way: String) {
        set(way, forKey: key)
    }

    func getBoolean(key:String) -> Bool {
        return bool(forKey: key)
    }
    
    func getString(key:String) -> String? {
        return string(forKey: key)
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

public class SettingsMT : ObservableObject {
    var id = UUID()
    public let AGE_GROUP_11_PLUS = "11Plus"
    @Published public var useTestData = false
    @Published public var showReloadHTMLButton = false
    @Published public var useAnimations = false
    
    @Published public var ageGroup:AgeGroup = .Group_11Plus
    @Published public var backgroundsSet:BackgroundsSet = .scene
    
    @Published public var colorScore = UIGlobalsCommon.colorScoreDefault
    @Published public var colorInstructions = UIGlobalsCommon.colorInstructionsDefault
    ///Color of each test's screen background
    @Published public var colorBackground = UIGlobalsCommon.colorBackgroundDefault
    @Published public var soundOnTaps = true
    @Published public var useUpstrokeTaps = false //Turned off for the moment. Possibly will never use and always use downstrokes
    @Published public var companionOn = true
    @Published public var useAcousticKeyboard = false
    @Published public var licenseEmail:String = ""
    
    public static var shared = SettingsMT()
    
    public init() {
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
        if let retrievedBackgroundsSet = UserDefaults.standard.getSelectedBackgroundSet(key: UserDefaultKeys.selectedBackgroundsSet) {
            backgroundsSet = retrievedBackgroundsSet
        }
        showReloadHTMLButton = UserDefaults.standard.getBoolean(key: UserDefaultKeys.showReloadHTMLButton)
        useTestData = UserDefaults.standard.getBoolean(key: UserDefaultKeys.useTestData)
        useAnimations = UserDefaults.standard.getBoolean(key: UserDefaultKeys.useAnimations)
        soundOnTaps = UserDefaults.standard.getBoolean(key: UserDefaultKeys.soundOnTaps)
        useUpstrokeTaps = UserDefaults.standard.getBoolean(key: UserDefaultKeys.useUpstrokeTaps)
        companionOn = UserDefaults.standard.getBoolean(key: UserDefaultKeys.companionOn)
        useAcousticKeyboard = UserDefaults.standard.getBoolean(key: UserDefaultKeys.useAcousticKeyboard)
        if let email = UserDefaults.standard.getString(key: UserDefaultKeys.licenseEmail) {
            licenseEmail = email
        }
        else {
            licenseEmail = ""
        }
    }
    
    public init(copy settings: SettingsMT) {
        self.useTestData = settings.useTestData
        self.showReloadHTMLButton = settings.showReloadHTMLButton
        self.useAnimations = settings.useAnimations
        self.ageGroup = settings.ageGroup
        self.backgroundsSet = settings.backgroundsSet
        self.colorScore = settings.colorScore
        self.colorInstructions = settings.colorInstructions
        self.colorBackground = settings.colorBackground
        self.soundOnTaps = settings.soundOnTaps
        self.useUpstrokeTaps = settings.useUpstrokeTaps
        self.companionOn = settings.companionOn
        self.useAcousticKeyboard = settings.useAcousticKeyboard
        self.licenseEmail = settings.licenseEmail
    }
    
    public func getNameOfLicense(grade:String, email:String) -> String? {        
        let iap = IAPManager.shared
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let gradeToCheck = grade.replacingOccurrences(of: " ", with: "_")
        for productId in iap.purchasedProductIds {
            if productId.contains(gradeToCheck) {
                if productId.contains(String(currentYear)) {
                    if let product = iap.availableProducts[productId] {
                        return product.localizedTitle
                    }
                }
            }
        }
        if iap.emailIsLicensed(email: email) {
            return email
        }
        return nil
    }
    
    public func isContentSectionLicensed(contentSection:ContentSection) -> Bool {
        guard let gradeSection = contentSection.parentSearch(testCondition: {section in
                return section.name.contains("Grade")
            }) else {
                return true
            }
        return getNameOfLicense(grade: gradeSection.name, email: self.licenseEmail) != nil
    }

    public func getAgeGroup() -> String {
        return ageGroup == .Group_11Plus ? AGE_GROUP_11_PLUS : "5-10"
    }

    public func saveConfig() {
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorScore, colorScore)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorInstructions, colorInstructions)
        UserDefaults.standard.setSelectedColor(key: UserDefaultKeys.selectedColorBackground, colorBackground)
        UserDefaults.standard.setSelectedAgeGroup(key: UserDefaultKeys.selectedAgeGroup, ageGroup)
        UserDefaults.standard.setSelectedBackgroundSet(key: UserDefaultKeys.selectedBackgroundsSet, backgroundsSet)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.showReloadHTMLButton, showReloadHTMLButton)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useTestData, useTestData)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useAnimations, useAnimations)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.soundOnTaps, soundOnTaps)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useUpstrokeTaps, useUpstrokeTaps)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.companionOn, companionOn)
        UserDefaults.standard.setBoolean(key: UserDefaultKeys.useAcousticKeyboard, useAcousticKeyboard)
        UserDefaults.standard.setString(key: UserDefaultKeys.licenseEmail, licenseEmail)
    }
    
}
