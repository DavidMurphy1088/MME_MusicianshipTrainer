import SwiftUI
import CoreData
import CommonLibrary

struct MetronomeView: View {
    let score:Score
    let helpText:String
    var frameHeight:Double
    @State var isPopupPresented:Bool = false
    @ObservedObject var metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "MetronomeView")
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    if metronome.tickingIsActive == false {
                        metronome.startTicking(score: score)
                    }
                    else {
                        metronome.stopTicking()
                    }
                }, label: {
                    Image("metronome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ///Needs more hiehgt on phone to even show
                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? frameHeight * 0.8 : frameHeight * 0.5)
                        .padding(.horizontal, frameHeight * 0.1)
                        .overlay(
                            RoundedRectangle(cornerRadius: frameHeight * 0.1)
                                .stroke(metronome.tickingIsActive ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .padding(.horizontal, frameHeight * 0.1)
                })
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Image("note_transparent")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: frameHeight / 6.0)
                }
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Text("=\(Int(metronome.tempo)) BPM").foregroundColor(.black)
                }
                else {
                    Text("\(Int(metronome.tempo))").foregroundColor(.black)
                }
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Text(metronome.tempoName).padding().foregroundColor(.black)
                }
                
                if metronome.allowChangeTempo {
                    Slider(value: Binding<Double>(
                        get: { Double(metronome.tempo) },
                        set: {
                            metronome.setTempo(tempo: Int($0), context: "Metronome View, Slider change")
                        }
                    ), in: Double(metronome.tempoMinimumSetting)...Double(metronome.tempoMaximumSetting), step: 1)
                    .padding()
                }
                
                Button(action: {
                    isPopupPresented.toggle()
                }) {
                    VStack {
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            Text("Practice Tool")
                        }
                        Image(systemName: "questionmark.circle")
                            .font(UIDevice.current.userInterfaceIdiom == .pad ? .largeTitle : .title3)
                    }
                }
                .padding()
                .popover(isPresented: $isPopupPresented) { //, arrowEdge: .bottom) {
                    VStack {
                        Text(helpText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 1)
                            .padding()
                        )
                    .padding()
                }
            }
        }
        .frame(height: frameHeight)
//        .overlay(
//            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
//        )
        .background(Settings.shared.colorInstructions)
    }
}




