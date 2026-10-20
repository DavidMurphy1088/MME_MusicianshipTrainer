import SwiftUI
import Foundation
import CommonLibrary

struct FlyingImageView: View {
    @State var answer:Answer
    @State var xPos = 0.0
    @State var yPos = 0.0
    @State var loop = 0
    let imageSize:CGFloat = 120.0
    let totalDuration = 15.0
    let heightDelta = 60.0
    @State var rotation = 0.0
    @State var opacity = 1.0
    @State var imageNumber = 0
    @State var leftOrRight = 0
    @State private var viewWidth = 0.0

    func imageName() -> String {
        return "answer_animate_" + String(self.imageNumber)
    }
    
    var body: some View {
        ZStack {
            Image(imageName())
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .foregroundColor(.blue)
                .opacity(opacity * 1.5)
                .rotationEffect(Angle(degrees: rotation))
                .position(CGPoint(x: xPos, y: yPos))
        }
        .onAppear {
            leftOrRight = Int.random(in: 0...1)
            xPos = UIGlobalsCommon.screenBounds.width * (leftOrRight == 0 ? 0.20 : 0.80)
            yPos = UIGlobalsCommon.screenBounds.height * (answer.correct ? 0.30 : 0.60)
            self.imageNumber = Int.random(in: 0...21)
            if !answer.correct {
                //withAnimation(Animation.linear(duration: 1.0)) { //}.repeatForever(autoreverses: false)) {
                    rotation = -90.0
                //}
            }

            DispatchQueue.global(qos: .background).async {
                //sleep(1)
                animateRandomly()
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    self.viewWidth = geometry.size.width
                }
            }
        )

    }
    
    func animateRandomly() {
        let loops = 4
        for _ in 0..<loops {
            withAnimation(Animation.linear(duration: totalDuration / Double(loops))) { //}.repeatForever(autoreverses: false)) {
                opacity = 0.0
                if answer.correct {
                    xPos = xPos + CGFloat.random(in: imageSize * -1.0 ... imageSize * 1.0)
                    yPos = yPos - heightDelta
                    rotation = rotation + Double(Int.random(in: 0...10))
                }
                else {
                    let distance = CGFloat.random(in: 0...imageSize * 6)
                    let direction = Int.random(in: 0...1)
                    if direction == 0 {
                        xPos = xPos + distance
                    }
                    else {
                        xPos = xPos - distance
                    }
                    if xPos < 0 {
                        xPos = 0
                    }
                    if xPos > self.viewWidth - imageSize {
                        xPos = self.viewWidth - imageSize
                    }
                    yPos = yPos + heightDelta * 1.0
                    rotation = rotation + 90.0
                }
            }
        }
    }
}

// MARK: - Dice shuffle animation

///A short, purely decorative dice roll shown when a student taps Shuffle / Random Pick.
///SAFETY: this does not choose or change the question. The shuffle code picks and selects the question exactly
///as before; it just calls DiceShuffle.shared.roll() to play the animation on top. The overlay ignores all touches,
///so it can never block a button, and if anything went wrong the worst case is a visual glitch.
final class DiceShuffle: ObservableObject {
    static let shared = DiceShuffle()
    @Published var rollCount = 0

    ///Play the dice animation (if the overlay is on screen)
    func roll() {
        DispatchQueue.main.async {
            self.rollCount += 1
        }
    }

    ///Pick a random position in 0..<count, avoiding the current one when there is a choice.
    ///Fixes the old Int.random(in: 0...count), which could pick one past the last question so Shuffle did nothing.
    static func pickIndex(count: Int, avoiding current: Int?) -> Int? {
        if count <= 0 {
            return nil
        }
        if count == 1 {
            return 0
        }
        var index = Int.random(in: 0..<count)
        if let current = current, index == current {
            index = (index + Int.random(in: 1..<count)) % count
        }
        return index
    }
}

///One face of the die: a rounded white square with a music symbol
struct DiceFaceView: View {
    let symbol: String
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.35), radius: size * 0.08, x: size * 0.04, y: size * 0.06)
            RoundedRectangle(cornerRadius: size * 0.22)
                .stroke(color, lineWidth: size * 0.06)
            Text(symbol)
                .font(.system(size: size * 0.55))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

///Full screen overlay that plays the dice roll whenever DiceShuffle.shared.roll() is called.
///Placed once, over the whole app's navigation view (MusicianshipTrainerApp).
struct DiceShuffleOverlay: View {
    @ObservedObject var dice = DiceShuffle.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isShowing = false
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0
    @State private var faceIndex = 0
    ///Each roll gets a token so a second tap mid-roll cleanly takes over from the first
    @State private var rollToken = 0

    private let faces = ["♩", "♪", "♫", "♬", "𝄞", "𝄽"]
    private let colors: [Color] = [.red, .orange, .green, .blue, .purple, .pink]

    private var isYounger: Bool {
        SettingsMT.shared.ageGroup != .Group_11Plus
    }

    var body: some View {
        GeometryReader { geo in
            if isShowing {
                let size = min(geo.size.width, geo.size.height) * (isYounger ? 0.28 : 0.18)
                DiceFaceView(symbol: faces[faceIndex], color: colors[faceIndex], size: size)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .position(x: geo.size.width / 2 + offsetX, y: geo.size.height / 2)
            }
        }
        .allowsHitTesting(false)   ///Never intercept a tap
        .onChange(of: dice.rollCount) { _ in
            startRoll()
        }
    }

    private func after(_ seconds: Double, token: Int, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            if token == rollToken {
                work()
            }
        }
    }

    private func startRoll() {
        if reduceMotion {
            return
        }
        rollToken += 1
        let token = rollToken
        ///Younger students get a bigger, longer, bouncier roll; 11+ a quicker, subtler one
        let rollTime = isYounger ? 0.9 : 0.55
        let screenWidth = UIGlobalsCommon.screenBounds.width

        ///Start off to the left, small and spinning
        offsetX = -screenWidth * 0.45
        rotation = 0
        scale = 0.6
        opacity = 1
        faceIndex = Int.random(in: 0..<faces.count)
        isShowing = true

        ///Tumble in to the centre
        withAnimation(.easeOut(duration: rollTime)) {
            offsetX = 0
            rotation = isYounger ? 720 : 360
            scale = 1.0
        }

        ///Flick through faces while tumbling
        let flips = Int(rollTime / 0.09)
        for i in 0..<flips {
            after(Double(i) * 0.09, token: token) {
                faceIndex = Int.random(in: 0..<faces.count)
            }
        }

        ///Land with a bounce and a light tap
        after(rollTime, token: token) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) {
                scale = isYounger ? 1.2 : 1.08
            }
        }
        after(rollTime + 0.2, token: token) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                scale = 1.0
            }
        }

        ///Fade away
        let holdTime = isYounger ? 0.5 : 0.3
        after(rollTime + holdTime, token: token) {
            withAnimation(.easeIn(duration: 0.25)) {
                opacity = 0
                scale = 0.8
            }
        }
        after(rollTime + holdTime + 0.3, token: token) {
            isShowing = false
        }
    }
}
