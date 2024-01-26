import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit
import CommonLibrary

struct RhythmToleranceView: View {
    let contextText:String?
    @State var isToleranceHelpPresented:Bool = false
    //@State private var rhythmTolerancePercent: Double = UIGlobalsMT.shared.rhythmTolerancePercent
    @State private var rhythmToleranceSetting: Int = UIGlobalsMT.shared.rhythmToleranceSetting
    
    var body: some View {
        HStack {
            if let context = contextText {
                Text(context).padding()
            }
            HStack {
                var label = UIDevice.current.userInterfaceIdiom == .pad ? "Rhythm Tolerance:" : "Tolerance"
                //Text("\(label) \(RhytmTolerance.getToleranceName(UIGlobalsMT.shared.rhythmTolerancePercent))").defaultTextStyle()
                Text("\(label)").defaultTextStyle()
                Picker("Options", selection: $rhythmToleranceSetting) {
                    Text("Hardest").defaultTextStyle().tag(0)
                    Text("Hard").defaultTextStyle().tag(1)
                    Text("Moderate").defaultTextStyle().tag(2)
                    Text("Easy").defaultTextStyle().tag(3)
                }
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
            //Slider(value: $rhythmTolerancePercent, in: 30...66).padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 50 : 4)
        }
        .onChange(of: rhythmToleranceSetting) { newValue in
            //setRhythmTolerance(newValue: newValue)
            UIGlobalsMT.shared.rhythmToleranceSetting = newValue
            //rhythmToleranceSetting = UIGlobalsMT.rhythmToleranceSetting
        }
        .padding()
        .roundedBorderRectangle()
        .padding()
    }
}
