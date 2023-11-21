import Foundation
import SwiftUI
import CoreData
import CommonLibrary

struct StemView: View {
    @State var score: Score
    @State var staff: Staff
    @State var notePositionLayout: NoteLayoutPositions
    var notes: [Note]
    //@ObservedObject var lineSpacing:StaffLayoutSize
    
    func getStemLength() -> Double {
        var len = 0.0
        if notes.count > 0 {
            len = notes[0].stemLength * score.lineSpacing
        }
        return len
    }
    
    func getNoteWidth() -> Double {
        return score.lineSpacing * 1.2
    }

    func midPointXOffset(notes:[Note], staff:Staff, stemDirection:Double) -> Double {
        for n in notes {
            if n.rotated {
                if n.midiNumber < staff.middleNoteValue {
                    ///Normally the up stem goes to the right of the note. But if there is a left rotated note we want the stem to go thru the middle of the two notes
                    return -1.0 * getNoteWidth()
                }
            }
        }
        return (stemDirection * -1.0 * getNoteWidth())
    }

//    func log(_ ctx:String) -> Bool {
//        return true
//    }
//
    
    func getStaffNotes(staff:Staff) -> [Note] {
        var notes:[Note] = []
        for n in self.notes {
            if n.staffNum == staff.staffNum {
                notes.append(n)
            }
        }
        return notes
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                let staffNotes = getStaffNotes(staff: staff)
                if staffNotes.count > 0 {
                    if staffNotes.count <= 1 {
                        ///Draw in the stem lines for all notes under the current stem line if this is one.
                        ///For a group of notes under a quaver beam the the stem direction (and later length...) is determined by only one note in the group
                        let startNote = staffNotes[0].getBeamStartNote(score: score, np: notePositionLayout)
                        let inErrorAjdust = 0.0 //notes.notes[0].noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                        if startNote.getValue() != Note.VALUE_WHOLE {
                            //if startNote.debug("VIEW staff:\(staff.staffNum)") {
                                //Note this code eventually has to go adjust the stem length for notes under a quaver beam
                                //3.5 lines is a full length stem
                                let stemDirection = startNote.stemDirection == .up ? -1.0 : 1.0 //stemDirection(note: startNote)
                                //let midX = geo.size.width / 2.0 + (stemDirection * -1.0 * noteWidth / 2.0)
                                let midX = (geo.size.width + (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection))) / 2.0
                                let midY = geo.size.height / 2.0
                                let offsetY = CGFloat(notes[0].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline) * 0.5 * score.lineSpacing + inErrorAjdust
                                Path { path in
                                    path.move(to: CGPoint(x: midX, y: midY - offsetY))
                                    path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
                                }
                                .stroke(notes[0].getColor(staff: staff), lineWidth: 1.5)
                            //}
                        }
                    }
                    else {
                        ///This code assumes the stem for a chord wont (yet) be under a quaver beam
                        //let furthestFromMidline = self.getFurthestFromMidline(noteArray: staffNotes)

                        ZStack {
                            ForEach(staffNotes) { note in
                                let stemDirection = note.stemDirection == .up ? -1.0 : 1.0
                                let midX:Double = (geo.size.width + (midPointXOffset(notes: staffNotes, staff: staff, stemDirection: stemDirection))) / 2.0
                                let midY = geo.size.height / 2.0
                                let inErrorAjdust = 0.0 //note.noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                                
                                if note.getValue() != Note.VALUE_WHOLE {
                                    let offsetY = CGFloat(note.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline) * 0.5 * score.lineSpacing + inErrorAjdust
                                    Path { path in
                                        path.move(to: CGPoint(x: midX, y: midY - offsetY))
                                        path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
                                    }
                                    .stroke(staffNotes[0].getColor(staff: staff), lineWidth: 1.5)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
