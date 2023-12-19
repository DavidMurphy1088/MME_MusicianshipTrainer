import SwiftUI
import CommonLibrary
import AVFoundation
import Foundation

struct SightReadingView: PianoUserProtocol, View {
    var answer:Answer? = nil
    var score:Score? = nil
    init() {
    }

    func getActionHandler(piano:Piano) -> some View {
        VStack {
        }
    }
    
    func receiveNotificationOfKeyPress(key: PianoKey) {
        if let answer = answer {
            answer.sightReadingNotePitches.append(key.midi)
            answer.sightReadingNoteTimes.append(Date())
            //print("======receiveNotification", answer.sightReadingNotes.count, key.midi)
        }
    }
    
    func getKeyDisplayView(key:PianoKey) -> some View {
        VStack {
            //Text("K:\(key.midi)")
        }
    }

    var body: some View {
        VStack {
        }
    }    
}

struct SightReadingPianoView: View {
    let answer:Answer
    @State var piano:Piano?
    let score:Score
    
    func getPianoView(piano:Piano) -> some View {
        var user = SightReadingView()
        user.score = score
        user.answer = answer
        let pianoView = PianoView<SightReadingView>(piano: piano, user: user)
        return pianoView
    }
    
    var body: some View {
        VStack {
            if let piano = piano {
                getPianoView(piano: piano)
            }
        }
        .onAppear() {
            ///Determine what range the piano keys need to span
            var minMidi = 100
            var maxMidi = 0
            for timeSlice in score.getAllTimeSlices() {
                if timeSlice.entries.count > 0 {
                    if let note = timeSlice.entries[0] as? Note {
                        if note.midiNumber < minMidi {
                            minMidi = note.midiNumber
                        }
                        if note.midiNumber > maxMidi {
                            maxMidi = note.midiNumber
                        }
                    }
                }
            }
            ///Start on a C or an E
            var pianoStart = 0
            var minDiff = 1000
            //for startMidi in [48, 53, 60, 65, 72, 77] {
            ///Always start on C?
            for startMidi in [48, 60, 72] {
                if startMidi <= minMidi {
                    let diff = minMidi - startMidi
                    if diff < minDiff {
                        minDiff = diff
                        pianoStart = startMidi
                    }
                }
            }
            var pianoEnd = maxMidi + 4
            if Piano.midiIsBlack(midi: pianoEnd) {
                pianoEnd += 1
            }
            let keyCount = pianoEnd - pianoStart
            piano = Piano(startMidi: pianoStart, number: keyCount, soundNotes: true)
        }
    }
}
