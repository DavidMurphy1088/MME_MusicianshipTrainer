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
            ///RATIONALE: Thread.sleep here blocked the MAIN thread for 50ms on every tap. While it
            ///sleeps, iOS can't deliver the next touch to the app, so a tap made during that time is
            ///processed late. asyncAfter gives the same 50ms flash without blocking anything.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.invert.toggle()
            }
        }
    }
}

///A transparent UIKit view laid over the drum that reports each finger-down with its hardware time.
///RATIONALE for using UIKit instead of SwiftUI DragGesture:
///  - DragGesture is designed for dragging. It reports continuously while a finger is down or moving,
///    so one tap arrives as several events (4-6 on iPhone). The old code had to discard events within
///    0.20s of the previous tap, which also discarded genuine fast taps (a semiquaver at 120 bpm is
///    0.125s), and a long or wobbly press could still be counted twice.
///  - touchesBegan is called exactly ONCE each time a finger goes down, so no time filter is needed:
///    fast rhythms are recorded completely and long presses never double count.
///  - UITouch.timestamp is the time iOS detected the touch, not the time our code got to run.
final class TapPadView: UIView {
    var onTap: ((TimeInterval) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        ///One call per finger that went down. Usually one touch; if two fingers land in the same
        ///instant each is a separate tap, as it would be on a real drum.
        for touch in touches {
            onTap?(touch.timestamp)
        }
    }
}

struct TapPad: UIViewRepresentable {
    let onTap: (TimeInterval) -> Void

    func makeUIView(context: Context) -> TapPadView {
        let view = TapPadView()
        view.backgroundColor = .clear      ///Invisible, the drum image shows through; clear views still receive touches
        ///RATIONALE: students often alternate fingers, putting the next finger down before lifting the
        ///previous one. With multiple touch disabled, that second finger-down would not be delivered
        ///and the tap would be lost.
        view.isMultipleTouchEnabled = true
        view.onTap = onTap
        return view
    }

    func updateUIView(_ view: TapPadView, context: Context) {
        ///Refresh the closure so it always sees the current isRecording value
        view.onTap = onTap
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
    ///lastGestureTime removed: it only existed for the 0.20s duplicate filter, which is no longer needed

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
        var size = UIGlobalsCommon.screenBounds.width / (UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2)
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
//                        .frame(width: UIGlobalsCommon.screenBounds.width / (UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2))
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
                ///Still fires on the downstroke, as before, but once per finger-down and with the touch's own time.
                .overlay(
                    TapPad { touchTime in
                        if isRecording {
                            ///Record FIRST using the touch's own timestamp, then do the visual/sound feedback.
                            ///Always the system tap sound. The drum sound option was removed from Configuration; any old saved
                            ///soundOnTaps value is ignored, so all users get the same (lighter, lower-latency) click.
                            tapRecorder.makeTap(useSoundPlayer: false, timestamp: touchTime)
                            invert.switchBorder()
                            tapCtr += 1
                        }
                    }
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





