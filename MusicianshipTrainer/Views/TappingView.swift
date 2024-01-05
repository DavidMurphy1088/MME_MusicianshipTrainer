import SwiftUI
import CoreData
import CommonLibrary

enum TapState {
    case inactive
    case active(location: CGPoint)
}

class Invert : ObservableObject {
    @Published var invert = true
    func switchBorder() {
        DispatchQueue.main.async {
            self.invert.toggle()
        }
    }
}

struct TappingView: View {
    @Binding var isRecording:Bool
    @ObservedObject var tapRecorder:TapRecorder
    var onDone: ()->Void

    @State var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "TappingView")
    @State private var tapRecords: [CGPoint] = []
    @State var ctr = 0
    @ObservedObject var invert:Invert = Invert()
    @State var tapSoundOn = false
    @State var tapCtr = 0
    @State var lastGestureTime:Date? = nil

    func drumView() -> some View {
        ZStack {
            Image("drum_transparent")
                .resizable()
                .scaledToFit()
                .padding().padding().padding()
                .overlay(Circle().stroke(invert.invert ? Color.white : Color.black, lineWidth: 4))
                .shadow(radius: 10)
            
            if isRecording {
                if tapRecorder.enableRecordingLight {
                    Image(systemName: "stop.circle")
                        .foregroundColor(Color.red)
                        .font(.system(size: 60))
                }
            }
            Text(" ").padding()
        }
        .padding()
        .roundedBorderRectangle()
    }
    
    func getDrumWidth() -> Double {
        var size = UIScreen.main.bounds.width / (UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2)
        if UIGlobalsCommon.isLandscape() {
            size *= 0.75
        }
        return size
    }
    
    var body: some View {
        VStack {
            ///18Nov23 - useUpstrokeTaps - removed option - is now always false. Use down strokes everywhere
            ///comment deprecated - Using the gesture on iPhone is problematic. It generates 4-6 notifications per tap. Use use upstroke for phone
            ///But leave commented code for the moment
//            if Settings.shared.useUpstrokeTaps { //}|| UIDevice.current.userInterfaceIdiom == .phone {
//                ZStack {
//                    drumView()
//                        .frame(width: UIScreen.main.bounds.width / (UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2))
//                }
//                .padding()
//                .onTapGesture {
//                    ///Fires on up stroke
//                    if isRecording {
//                        invert.switchBorder()
//                        ///Too much sound lag on phone so dont use sound
//                        tapRecorder.makeTap(useSoundPlayer:Settings.shared.soundOnTaps) // && UIDevice.current.userInterfaceIdiom == .pad)
//                    }
//                }
//            }
//            else {
                drumView()
                .frame(width: getDrumWidth())
                .gesture(
                    ///Fires on downstroke
                    ///Min distance has to be 0 to notify on tap
                    DragGesture(minimumDistance: 0)
                    .onChanged({ gesture in
                        if isRecording {
                            ///iPhone seems to generate 4-6 notifictions on each tap. Maybe since this is a gesture?
                            ///So drop the notifictions that are too close together. < 0.10 seconds
                            var doTap = false
                            if let lastTime = lastGestureTime {
                                let diff = gesture.time.timeIntervalSince(lastTime)
                                if diff > 0.20 {
                                    doTap = true
                                }
                            }
                            else {
                                doTap = true
                            }
                            if doTap {
                                self.lastGestureTime = gesture.time
                                invert.switchBorder()
                                tapRecorder.makeTap(useSoundPlayer:SettingsMT.shared.soundOnTaps)
                            }
                            tapCtr += 1
                        }
                    })
                )
                .padding()
//            }

            Button(action: {
                onDone()
            }) {
                Text("Stop Recording").defaultButtonStyle()
            }
        }
        .onAppear() {
            self.tapSoundOn = UIGlobalsCommon.rhythmTapSoundOn
        }
    }
    
}





