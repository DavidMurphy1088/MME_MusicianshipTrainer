import SwiftUI
import CommonLibrary

struct MelodyScoreView: View {
    let basePitch:Int
    let interval:Int
    let melody:Melody
    @State var score:Score?
    let metronome = Metronome.getMetronomeWithSettings("Melody example", initialTempo: 90, allowChangeTempo: false)
    
    init(basePitch:Int, interval:Int, melody:Melody) {
        self.basePitch = basePitch
        self.interval = interval
        self.melody = melody
    }

    var body: some View {
        VStack {
            if let score = score {
                ScoreView(score: score, widthPadding: false)
                    .padding(.horizontal, 0)
                    //.border(Color.red)
            }
        }
        
        .onAppear {
            ///Transpose the selected melody to the first note of the interval
            let contentData = ContentSectionData(row:0, type: "", data: melody.data)
            let contentSection = ContentSection(parent: nil, name: "", type: "", data:contentData, isActive:true)
            let parsedScore = contentSection.parseData(staffCount: 1, onlyRhythm: false)
            
            func getNote(_ ts:TimeSlice) -> Note? {
                if ts.entries.count > 0 {
                    if let note = ts.entries[0] as? Note {
                        return note
                    }
                }
                return nil
            }
            func getRest(_ ts:TimeSlice) -> Rest? {
                if ts.entries.count > 0 {
                    if let rest = ts.entries[0] as? Rest {
                        return rest
                    }
                }
                return nil
            }

            //if let parsedScore = parsedScore {
                ///Mark the notes that demonstrate the interval
                ///Calculate the required pitch adjust
            var previousNote:Note?
            var firstIntervalNoteFound = false
            var pitchAdjust:Int = 0
            
            for ts in parsedScore.getAllTimeSlices() {
                if let note = getNote(ts) {
                    if let previousNote = previousNote {
                        let diff = note.midiNumber - previousNote.midiNumber
                        if diff == interval {
                            ts.setStatusTag("MelodyScoreView1", StatusTag.hilightAsCorrect)
                            previousNote.timeSlice.setStatusTag("MelodyScoreView2", StatusTag.hilightAsCorrect)
                            if !firstIntervalNoteFound {
                                firstIntervalNoteFound = true
                                pitchAdjust = basePitch - previousNote.midiNumber
                            }
                            //score.debugScore("melody ex1", withBeam: false)
                        }
                    }
                    previousNote = note
                }
            }
            
            ///Transpose the melody to demonstrate the chosen interval at the same pitch as the question
            score = Score(key: parsedScore.key, timeSignature: parsedScore.timeSignature, linesPerStaff: 5)
            
            if let score = score {
                score.createStaff(num: 0, staff: Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5))
                //score.setLineSpacing(spacing: 5.0)
                for entry in parsedScore.scoreEntries {
                    if let ts = entry as? TimeSlice {
                        let newTS = score.createTimeSlice()
                        if let note = getNote(ts) {
                            let newNote = Note(timeSlice: ts, num: note.midiNumber + pitchAdjust, value: note.getValue(), staffNum: 0)
                            if pitchAdjust == 0 {
                                newNote.writtenAccidental = note.writtenAccidental
                            }
                            newTS.addNote(n: newNote)
                        }
                        if let rest = getRest(ts) {
                            let newRest = Rest(timeSlice: newTS, value: rest.getValue(), staffNum: 0)
                            newTS.addRest(rest: newRest)
                        }
                        newTS.setStatusTag("MelodyScoreView3", ts.statusTag)
                    }
                    if entry is BarLine {
                        score.addBarLine()
                    }
                }
                metronome.playScore(score: score, onDone: {
                    //self.scoreWasPlayed = true
                })
            }
        }
        .onDisappear() {
            metronome.stopPlayingScore()
        }
    }
}

struct ListMelodiesView: View {
    let firstNote:Note
    let intervalName:String
    let interval:Int
    let melodies:[Melody]
    @State var selectedMelodyId:UUID?
    @State var presentMelodies = false
    @State var presentScoreView = false
    @State var selectedMelody:Melody?
    
    var body: some View {
        VStack {
            Button(action: {
                presentMelodies = true
            }) {
                Text("Hear Melody").defaultButtonStyle()
            }
            .padding()
            .fullScreenCover(isPresented: $presentMelodies) {
                ZStack {
                    VStack {
                        Image("app_background_navigation")
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .opacity(UIGlobalsMT.shared.backgroundImageOpacity)
                    }
                    VStack {
                        Spacer()
                        Text("Examples of a \(intervalName)").font(.title).padding()
                        VStack {
                            if presentScoreView {
                                if let selectedMelody = selectedMelody {
                                    MelodyScoreView(basePitch: firstNote.midiNumber, interval:interval, melody: selectedMelody)
                                        .padding(.horizontal, 0)
                                    //.border(Color.green)
                                }
                            }
                        }
                        VStack {
                            ForEach(melodies) { melody in
                                Button(action: {
                                    presentScoreView = false
                                    selectedMelodyId = melody.id
                                    selectedMelody = melody
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        presentScoreView = true
                                    }
                                }) {
                                    //ZStack {
                                    Text(melody.name)
                                    //.padding()
                                        .foregroundColor(selectedMelodyId == melody.id ? .black : .black)
                                        .padding()
                                        .background(selectedMelodyId == melody.id ? Color.blue : Color.white)
                                        .cornerRadius(8)
                                        .padding()
                                        .roundedBorderRectangle()
                                }
                            }
                            Button("Dismiss") {
                                presentMelodies = false
                            }
                            .padding()
                        }
                        .padding()
                        Spacer()
                    }
                }
                
                //.padding()
                .onAppear {
                    self.selectedMelody = nil
                }
            }
        }
    }

}
