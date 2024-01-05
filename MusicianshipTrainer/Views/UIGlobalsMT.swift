import Foundation
import SwiftUI
import CoreData

public class UIGlobalsMT {
    public static let cornerRadius:CGFloat = 16
    public static let borderColor = Color.gray
    public static let borderLineWidth = 4.0
    public static let backgroundImageOpacity = 0.5
    
    private static var lastRandom = -1
    static public func getRandomBackgroundImageName() -> String {
        var random:Int = -1
        while random < 0 {
            let r = Int.random(in: 0...7)
            if r == lastRandom {
                continue
            }
            random = r
            lastRandom = r
        }
        return "app_background_\(String(describing: random))"
    }
}

