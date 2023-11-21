import SwiftUI
import CoreData
import CommonLibrary

struct ToolsView: View {
    let score:Score
    let helpMetronome:String
    
    var body: some View {
        VStack {
            HStack {
                MetronomeView(score:score, helpText: helpMetronome, frameHeight: score.lineSpacing * 6)
                    //.padding(.horizontal)
                    .padding()
//                VoiceCounterView(frameHeight: frameHeight)
//                    //.padding(.horizontal)
//                    .padding()
            }
        }
    }
}




