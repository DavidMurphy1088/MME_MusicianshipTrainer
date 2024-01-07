import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit
import CommonLibrary

class RhytmTolerance {
    static func getToleranceName(_ setting:Double) -> String {
        //var name = UIDevice.current.userInterfaceIdiom == .pad ? "Tolerance" : "Tolerance"
        var grade:String = ""
        if setting < 39.0 {
            grade = "Hardest"
        }
        else {
            if setting < 48.0 {
                grade = "Hard"
            }
            else {
                if setting < 57.0 {
                    grade = "Moderate"
                }
                else {
                    grade = "Easy"
                }
            }
        }
//        if let grade = grade {
//            name += " " + grade
//        }
        return grade
    }
}

struct RhythmToleranceView: View {
    let contextText:String?
    @State var isToleranceHelpPresented:Bool = false
    @State private var rhythmTolerancePercent: Double = UIGlobalsMT.shared.rhythmTolerancePercent

    func setRhythmTolerance(newValue:Double) {
        let allowedValues = [30, 35, 40, 45, 50, 55, 60, 65]
        //let allowedValues = [35, 40, 45, 50, 55, 60, 65, 70, 75]
        let sortedValues = allowedValues.sorted()
        let closest = sortedValues.min(by: { abs($0 - Int(newValue)) < abs($1 - Int(newValue)) })
        UIGlobalsMT.shared.rhythmTolerancePercent = Double(closest ?? Int(newValue))
        rhythmTolerancePercent = UIGlobalsMT.shared.rhythmTolerancePercent
    }
    
    var body: some View {
        HStack {
            VStack {
                if let context = contextText {
                    Text(context).padding()
                }
                HStack {
                    var label = UIDevice.current.userInterfaceIdiom == .pad ? "Rhythm Tolerance:" : "Tolerance"
                    Text("\(label) \(RhytmTolerance.getToleranceName(UIGlobalsMT.shared.rhythmTolerancePercent))").defaultTextStyle()
                    Button(action: {
                        self.isToleranceHelpPresented = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(UIDevice.current.userInterfaceIdiom == .pad ? .largeTitle : .title3)
                    }
                }
                .sheet(isPresented: $isToleranceHelpPresented) {
                    VStack {
                        Spacer()
                        Text("Rhythm Matching Tolerance").font(.title).foregroundColor(.blue).padding()
                        Text("The rhythm tolerance setting affects how precisely your tapped rhythm is measured for correctness.").padding()
                        Text("Higher grades of tolerance require more precise tapping to achieve a correct rhythm. Lower grades require less precise tapping.").padding()
                        Spacer()
                    }
                    .background(SettingsMT.shared.colorBackground)
                }
                //Slider(value: $rhythmTolerancePercent, in: 30...66).padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 50 : 4)
                Slider(value: $rhythmTolerancePercent, in: 30...66).padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 50 : 4)
            }
            .onChange(of: rhythmTolerancePercent) { newValue in
                setRhythmTolerance(newValue: newValue)
                //rhythmTolerancePercent = UIGlobalsMT.rhythmTolerancePercent
            }
            .padding()
            .roundedBorderRectangle()
            .padding()
        }
    }
}
