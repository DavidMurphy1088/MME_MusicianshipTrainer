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
            xPos = UIScreen.main.bounds.width * (leftOrRight == 0 ? 0.20 : 0.80)
            yPos = UIScreen.main.bounds.height * (answer.correct ? 0.30 : 0.60)
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
