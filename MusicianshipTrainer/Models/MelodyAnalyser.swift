import Foundation
import Foundation
import CommonLibrary

class MelodyAnalyser {
        
    ///Make a playable score of notes from the tapped notes
    public func makeScoreFromTaps(questionScore:Score, questionTempo:Int, tapPitches: [Int], tapTimes:[Date]) -> Score {
        let outputScore = Score(key: questionScore.key, timeSignature: questionScore.timeSignature, linesPerStaff: 5)
        let staff = Staff(score: outputScore, type: .treble, staffNum: 0, linesInStaff: 5)
        outputScore.createStaff(num: 0, staff: staff)
        var totalValue = 0.0
        outputScore.label = "Your Melody"
        
        ///Get first and last notes
        var firstNoteValue:Double?
        var lastNoteValue:Double = 1.0
        
        if questionScore.scoreEntries.count > 0 {
            let entry = questionScore.scoreEntries[0]
            for slice in questionScore.getAllTimeSlices() {
                if slice.getTimeSliceNotes().count > 0 {
                    if firstNoteValue == nil {
                        firstNoteValue = slice.getTimeSliceNotes()[0].getValue()
                    }
                    lastNoteValue = slice.getTimeSliceNotes()[0].getValue()
                }
            }
        }
        //var valueMultiplier:Double = 1.0 ///Convert tap durations (ms) to note values
        var lastNoteTime:Date?
        var lastNotePitch:Int?
        let tapRecorder = TapRecorder()
        var tempo:Int = 60
        
        for n in 0..<tapTimes.count+1 {
            if n == 0 {
                lastNotePitch = tapPitches[n]
                lastNoteTime = tapTimes[n]
                continue
            }
            ///Calculate the multiplier for the first note to have the same value as the question score note
            ///Then use that multiplier for all teh following notes to get their value from their time durations
            if n == 1 && tapTimes.count > 1 {
                let timeDuractionInSeconds = tapTimes[n].timeIntervalSince(lastNoteTime!)
                if let firstNoteValue = firstNoteValue {
                    tempo = Int(60.0 * firstNoteValue / timeDuractionInSeconds)
                }
            }
            var noteValue:Double?
            
            let timeDurationInSeconds:Double
            if n < tapTimes.count {
                timeDurationInSeconds = tapTimes[n].timeIntervalSince(lastNoteTime!)
                noteValue = tapRecorder.roundNoteValueToStandardValue(inValue: timeDurationInSeconds, tempo: tempo)
            }
            else {
                let restsDuration = questionScore.getEndRestsDuration()
                noteValue = lastNoteValue + restsDuration
                timeDurationInSeconds = (noteValue ?? 1.0) * 60.0 / Double(tempo)
            }
            if let noteValue = noteValue {
                let ts = outputScore.createTimeSlice()
                ts.addNote(n: Note(timeSlice: ts, num: Int(lastNotePitch!), value:noteValue, staffNum: 0))
                ts.tapSecondsNormalizedToTempo = timeDurationInSeconds * Double(tempo) / 60.0
                totalValue += noteValue
            }
            if n < tapTimes.count {
                lastNotePitch = tapPitches[n]
                lastNoteTime = tapTimes[n]
                if totalValue >= Double(questionScore.timeSignature.top) {
                    totalValue = 0
                    outputScore.addBarLine()
                }
            }
        }
        outputScore.tempo = tempo
        return outputScore
    }
}
