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
    @ObservedObject var settings:SettingsMT
    let colorCircleSize = 60.0
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("Configuration").font(.largeTitle).padding()
                .padding()
//            Image(systemName: "music.note.list")
//                .foregroundColor(.blue)
//                .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .largeTitle)

            VStack {
                HStack {
                    HStack {
                        Text("Age Group")
                        ConfigSelectAgeMode(selectedIndex: $settings.ageGroup)
                    }
                    .padding()
                    .roundedBorderRectangle()
                    
                    HStack {
                        Text("Backgrounds")
                        ConfigBackgroundsSet(selectedIndex: $settings.backgroundsSet)
                    }
                    .padding()
                    .roundedBorderRectangle()
                }
                .padding()
                
                VStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useAnimations.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: settings.useAnimations ? "checkmark.square" : "square")
                            let text = UIDevice.current.userInterfaceIdiom == .phone ? "Show animations" : "Show animations for correct and incorrect answers"
                            Text(text)
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.soundOnTaps.toggle()
                        }
                    }) {
                        HStack {
                            let text = UIDevice.current.userInterfaceIdiom == .phone ? "Drum sound tap" : "Use a drum sound for rhythm tapping"
                            Image(systemName: settings.soundOnTaps ? "checkmark.square" : "square")
                            Text(text)
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        DispatchQueue.main.async {
                            settings.useAcousticKeyboard.toggle()
                        }
                    }) {
                        HStack {
                            let text = UIDevice.current.userInterfaceIdiom == .phone ? "Acoustic piano" : "Use an acoustic piano for sight reading"
                            Image(systemName: settings.useAcousticKeyboard ? "checkmark.square" : "square")
                            Text(text)
                        }
                    }
                    .padding()
                }
                .roundedBorderRectangle()
                .padding()
                
                VStack {
                    Text("Teacher Section")
                    HStack {
                        Text("Email")
                        TextField("Enter your email", text: $settings.licenseEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                }
                .roundedBorderRectangle()
                .padding()
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                Text("------------------ Testing Only ------------------").padding()
                
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
            }
            
            //LogView().border(.black).padding()
            HStack {
                Button(action: {
                    SettingsMT.shared = SettingsMT(copy: settings)
                    SettingsMT.shared.saveConfig()
                    isPresented = false
                }) {
                    Text("Ok").font(.title)
                }
                .padding()
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel").font(.title)
                }
                .padding()

            }
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

            VStack {
                Text("Musicianship Trainer - Version.Build \(appVersion).\(buildNumber)").font(.headline)
                Text("© 2024 Musicmaster Education LLC.").font(.headline)
            }
            Spacer()
        }
        //.background(Settings.shared.colorBackground)
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

struct ConfigBackgroundsSet: View {
    @Binding public var selectedIndex: BackgroundsSet

    var body: some View {
        Picker("Select Backgrounds Set", selection: $selectedIndex) {
            ForEach(BackgroundsSet.allCases) { bkg in
                Text(bkg.displayName).tag(bkg).font(.title)
            }
        }
        .pickerStyle(DefaultPickerStyle())
    }
}

//            HStack {
//                VStack {
//                    Circle()
//                        .fill(settings.colorBackground)
//                        .frame(width: colorCircleSize, height: colorCircleSize)
//                    if UIDevice.current.userInterfaceIdiom == .pad {
//                        ColorPicker("Background\nSelect a Colour", selection: $settings.colorBackground, supportsOpacity: false)
//                    }
//                    else {
//                        Text("Background").font(.caption)
//                        ColorPicker("", selection: $settings.colorBackground, supportsOpacity: false)
//                    }
//
//                    Button("Reset") {
//                        DispatchQueue.main.async {
//                            settings.colorBackground = UIGlobals.colorBackgroundDefault
//                        }
//                    }
//                }
//                .padding()
//                .roundedBorderRectangle()
//                .padding()
//
//                VStack {
//                    Circle()
//                        .fill(settings.colorScore)
//                        .frame(width: colorCircleSize, height: colorCircleSize)
//                    if UIDevice.current.userInterfaceIdiom == .pad {
//                        ColorPicker("Score\nSelect a Colour", selection: $settings.colorScore, supportsOpacity: false)
//                    }
//                    else {
//                        Text("Score").font(.caption)
//                        ColorPicker("", selection: $settings.colorScore, supportsOpacity: false)
//                    }
//                    Button("Reset") {
//                        DispatchQueue.main.async {
//                            settings.colorScore = UIGlobals.colorScoreDefault
//                        }
//                    }
//                }
//                .padding()
//                .roundedBorderRectangle()
//                .padding()
//
//                VStack {
//                    Circle()
//                        .fill(settings.colorInstructions)
//                        .frame(width: colorCircleSize, height: colorCircleSize)
//                    if UIDevice.current.userInterfaceIdiom == .pad {
//                        ColorPicker("Instructions\nSelect a Colour", selection: $settings.colorInstructions, supportsOpacity: false)
//                    }
//                    else {
//                        Text("Instructions").font(.caption)
//                        ColorPicker("", selection: $settings.colorInstructions, supportsOpacity: false)
//                    }
//                    Button("Reset") {
//                        DispatchQueue.main.async {
//                            settings.colorInstructions = UIGlobals.colorInstructionsDefault
//                        }
//                    }
//
//                }
//                .padding()
//                .roundedBorderRectangle()
//                .padding()
//            }
