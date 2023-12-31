import Foundation
import SwiftUI
import CoreData

public class UIGlobalsMT {
    public static let shared = UIGlobalsMT()
    public let cornerRadius:CGFloat = 16
    public let borderColor = Color.gray
    public let borderLineWidth = 4.0
    public let backgroundImageOpacity = 0.5
    public var rhythmTolerancePercent:Double = 45.0 //Hard

    private var lastRandom = -1
    public func getRandomBackgroundImageName(backgroundSet:BackgroundsSet) -> String {
        var random:Int = -1
        var number = backgroundSet == .landscape ? 12 : 3
        while random < 0 {
            let r = Int.random(in: 0...number)
            if number > 1 {
                if r == lastRandom {
                    continue
                }
            }
            random = r
            lastRandom = r
        }
        return "app_background_\(backgroundSet.rawValue)_\(String(describing: random))"
    }
    
}

