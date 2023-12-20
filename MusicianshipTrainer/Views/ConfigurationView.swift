import SwiftUI
import CoreData
import SwiftUI
import CommonLibrary

struct LogView: View {
    let items: [LogMessage] = Logger.logger.recordedMsgs
    
    var body: some View {
        Text("Log messages")
        ScrollView {
            VStack(spacing: 20) {
                ForEach(items) { item in
                    HStack {
                        Text(item.message).padding(0)
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct ConfigurationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var settings:Settings
    let colorCircleSize = 60.0
    
    var body: some View {
        VStack(alignment: .center) {
            
            Text("Configuration").font(.title).padding()
                //.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                .padding()

            // ------------------- Colors ----------------
            
            HStack {
                VStack {
                    Circle()
                        .fill(settings.colorBackground)
                        .frame(width: colorCircleSize, height: colorCircleSize)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ColorPicker("Background\nSelect a Colour", selection: $settings.colorBackground, supportsOpacity: false)
                    }
                    else {
                        Text("Background").font(.caption)
                        ColorPicker("", selection: $settings.colorBackground, supportsOpacity: false)
                    }
                    
                    Button("Reset") {
                        DispatchQueue.main.async {
                            settings.colorBackground = UIGlobals.colorBackgroundDefault
                        }
                    }
                }
                .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)).padding()

                VStack {
                    Circle()
                        .fill(settings.colorScore)
                        .frame(width: colorCircleSize, height: colorCircleSize)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ColorPicker("Score\nSelect a Colour", selection: $settings.colorScore, supportsOpacity: false)
                    }
                    else {
                        Text("Score").font(.caption)
                        ColorPicker("", selection: $settings.colorScore, supportsOpacity: false)
                    }
                    Button("Reset") {
                        DispatchQueue.main.async {
                            settings.colorScore = UIGlobals.colorScoreDefault
                        }
                    }
                }
                .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)).padding()

                VStack {
                    Circle()
                        .fill(settings.colorInstructions)
                        .frame(width: colorCircleSize, height: colorCircleSize)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ColorPicker("Instructions\nSelect a Colour", selection: $settings.colorInstructions, supportsOpacity: false)
                    }
                    else {
                        Text("Instructions").font(.caption)
                        ColorPicker("", selection: $settings.colorInstructions, supportsOpacity: false)
                    }
                    Button("Reset") {
                        DispatchQueue.main.async {
                            settings.colorInstructions = UIGlobals.colorInstructionsDefault
                        }
                    }

                }
                .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)).padding()
            }
            
            VStack {
                HStack {
                    HStack {
                        Text("Age Group")
                        ConfigSelectAgeMode(selectedIndex: $settings.ageGroup)
                    }
                    .onAppear {
//                            if settings.ageGroup == .Group_5To10 {
//                                settings.selectedAge = .G
//                            }
//                            else {
//                                settings.selectedAge = 1
//                            }
                    }
                    //.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1))
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useAnimations.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.useAnimations ? "checkmark.square" : "square")
                            Text("Animated Answers")
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.soundOnTaps.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.soundOnTaps ? "checkmark.square" : "square")
                            Text("Sound For Tapping")
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useVirtualKeyboard.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.useVirtualKeyboard ? "checkmark.square" : "square")
                            Text("Use Virtual Keyboard")
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.showReloadHTMLButton.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.showReloadHTMLButton ? "checkmark.square" : "square")
                            Text("Reload HTML Button")
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useTestData.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.useTestData ? "checkmark.square" : "square")
                            Text("Use Test Data")
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.companionOn.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.companionOn ? "checkmark.square" : "square")
                            Text("Companion On")
                        }
                    }
                    .padding()
                }
            }
            
            //LogView().border(.black).padding()
            HStack {
                Button("Ok") {
                    Settings.shared = Settings(copy: settings)
                    Settings.shared.saveConfig()
                    isPresented = false
                }
                .padding()
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
            }
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

            VStack {
                Text("Musicianship Trainer - Version.Build \(appVersion).\(buildNumber)").font(.headline)
                Text("© 2024 Musicmaster Education LLC.").font(.headline)
            }
        }
    }
}

//struct ConfigSelectAgeMode: View {
//    @Binding var selectedIndex: AgeGroup
//    let items: [String]
//
//    var body: some View {
//        Picker("Select your Age", selection: $selectedIndex) {
//            ForEach(0..<items.count) { index in
//                Text(items[index]).tag(index).font(.title)
//            }
//        }
//        .pickerStyle(DefaultPickerStyle())
//        //.pickerStyle(InlinePickerStyle())
//    }
//}

struct ConfigSelectAgeMode: View {
    @Binding public var selectedIndex: AgeGroup

    var body: some View {
        Picker("Select your Age", selection: $selectedIndex) {
            ForEach(AgeGroup.allCases) { ageGroup in
                Text(ageGroup.displayName).tag(ageGroup).font(.title)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        // .pickerStyle(InlinePickerStyle())
    }
}
