import SwiftUI
import CoreData
import MessageUI
import CoreImage
import CommonLibrary

struct BarLineView: View {
    var score:Score
    var entry:ScoreEntry
    var staff:Staff
    //var staffLayoutSize:StaffLayoutSize

    var body: some View {
        ///For some unfathomable reason the bar line does not show if its not in a gemetry reader (-:
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.black)
                .frame(width: 1.0, height: 4.0 * Double(score.lineSpacing))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        //.frame(maxWidth: Double(staffLayoutSize.lineSpacing)  * 1.0)
        .frame(minWidth: Double(score.lineSpacing)  * 1.1)
        //.border(Color.red)
    }
}

struct NoteHiliteView: View {
    @ObservedObject var entry:TimeSliceEntry
    var x:CGFloat
    var y:CGFloat
    var width:CGFloat
    
    var body: some View {
        VStack {
            if entry.hilite {
                //Text("hHH")
                Ellipse()
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: width, height: width)
                    .position(x: x, y:y)
            }
        }
    }
}

struct TimeSliceView: View {
    @ObservedObject var timeSlice:TimeSlice
    var staff:Staff
    var color: Color
    var lineSpacing:Double
    var noteWidth:Double
    var accidental:Int?
    
    init(staff:Staff, timeSlice:TimeSlice, noteWidth:Double, lineSpacing: Double) {
        self.staff = staff
        self.timeSlice = timeSlice
        self.noteWidth = noteWidth
        self.color = Color.black
        self.lineSpacing = lineSpacing
    }
    
    func getAccidental(accidental:Int) -> String {
        if accidental < 0 {
            return "\u{266D}"
        }
        else {
            if accidental > 0 {
                return "\u{266F}"
            }
            else {
                return "\u{266E}"
            }
        }
    }
    
    struct LedgerLine:Hashable, Identifiable {
        var id = UUID()
        var offsetVertical:Double
    }
    
    func getLedgerLines(staff:Staff, note:Note, noteWidth:Double, lineSpacing:Double) -> [LedgerLine] {
        var result:[LedgerLine] = []
        let p = note.getNoteDisplayCharacteristics(staff: staff)
        
        if p.offsetFromStaffMidline <= -6 {
            result.append(LedgerLine(offsetVertical: 3 * lineSpacing * 1.0))
        }
        if p.offsetFromStaffMidline <= -8 {
            result.append(LedgerLine(offsetVertical: 4 * lineSpacing * 1.0))
        }
        if p.offsetFromStaffMidline <= -10 {
            result.append(LedgerLine(offsetVertical: 5 * lineSpacing * 1.0))
        }
        
        if p.offsetFromStaffMidline >= 6 {
            result.append(LedgerLine(offsetVertical: 3 * lineSpacing * -1.0))
        }
        if p.offsetFromStaffMidline >= 8 {
            result.append(LedgerLine(offsetVertical: 4 * lineSpacing * -1.0))
        }
        if p.offsetFromStaffMidline >= 10 {
            result.append(LedgerLine(offsetVertical: 5 * lineSpacing * -1.0))
        }
        return result
    }
    
    func getTimeSliceEntries() -> [TimeSliceEntry] {
        var result:[TimeSliceEntry] = []
        for n in self.timeSlice.entries {
            //if n is Note {
            result.append(n)
            //}
        }
        return result
    }
    
    func RestView(staff:Staff, entry:TimeSliceEntry, lineSpacing:Double, geometry:GeometryProxy) -> some View {
        ZStack {
            
            if entry.getValue() == 0 {
                Text("?")
                    .font(.largeTitle)
                    .foregroundColor(entry.getColor(staff: staff, log: true))
                Spacer()
            }
            else {
                if entry.getValue() == 1 {
                    Image("rest_quarter_grayscale")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(entry.getColor(staff: staff, log: true))
                        .scaledToFit()
                        .frame(height: lineSpacing * 3)
                }
                else {
                    if entry.getValue() == 2 {
                        let height = lineSpacing / 2.0
                        Rectangle()
                            .fill(entry.getColor(staff: staff, log: true))
                            .frame(width: lineSpacing * 1.5, height: height)
                            .offset(y: 0 - height / 2.0)
                    }
                    else {
                        if (entry.getValue() == 1.5) {
                            HStack {
                                Image("rest_quarter_grayscale")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(entry.getColor(staff: staff, log: true))
                                    .scaledToFit()
                                    .frame(height: lineSpacing * 3)
                                Text(".")
                                    .font(.largeTitle)
                                    .foregroundColor(entry.getColor(staff: staff, log: true))
                            }
                        }
                        else {
                            if (entry.getValue() == 4.0) {
                                let height = lineSpacing / 2.0
                                Rectangle()
                                    .fill(entry.getColor(staff: staff, log: true))
                                    .frame(width: lineSpacing * 1.5, height: height)
                                    .offset(y: 0 - height * 1.5)
                            }
                            else {
                                if (entry.getValue() == 0.5 ){
                                    Image("rest_quaver")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(entry.getColor(staff: staff, log: true))
                                        .scaledToFit()
                                        .frame(height: lineSpacing * 2)
                                    
                                }
                                else {
                                    VStack {
                                        Text("?")
                                            .font(.largeTitle)
                                            .foregroundColor(entry.getColor(staff: staff, log: true))
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        //.border(Color.red)
    }
    

    func NoteView(note:Note, noteFrameWidth:Double, geometry: GeometryProxy, inError:Bool) -> some View {
        ZStack {
            let placement = note.getNoteDisplayCharacteristics(staff: staff)
            let offsetFromStaffMiddle = placement.offsetFromStaffMidline
            let accidental = placement.accidental
            let noteEllipseMidpoint:Double = geometry.size.height/2.0 - Double(offsetFromStaffMiddle) * lineSpacing / 2.0
            let noteValueUnDotted = note.isDotted() ? note.getValue() * 2.0/3.0 : note.getValue()
            
            if inError {
                Text("X").bold().font(.system(size: lineSpacing * 3.0)).foregroundColor(.red)
                    .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
            }
            else {
                if note.staffNum == staff.staffNum  {
                    NoteHiliteView(entry: note, x: noteFrameWidth/2, y: noteEllipseMidpoint, width: noteWidth * 1.5)
                }
                
                if let accidental = accidental {
                    let yOffset = accidental == 1 ? lineSpacing / 5 : 0.0
                    Text(getAccidental(accidental: accidental))
                        .font(.system(size: lineSpacing * 3.0))
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 1.0))
                        .position(x: noteFrameWidth/2 - lineSpacing * (timeSlice.anyNotesRotated() ? 3.0 : 1.5),
                                  y: noteEllipseMidpoint + yOffset)
                        .foregroundColor(note.getColor(staff: staff))
                    
                }
                if [Note.VALUE_QUARTER, Note.VALUE_QUAVER, Note.VALUE_SEMIQUAVER].contains(noteValueUnDotted )  {
                    Ellipse()
                    //Closed ellipse
                        .foregroundColor(note.getColor(staff: staff))
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 1.0))
                        .position(x: noteFrameWidth/2  - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
                }
                if noteValueUnDotted == Note.VALUE_HALF || noteValueUnDotted == Note.VALUE_WHOLE {
                    Ellipse()
                    //Open ellipse
                        .stroke(note.getColor(staff: staff), lineWidth: 2)
                        .foregroundColor(note.getColor(staff: staff))
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 0.9))
                        .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
                }
                
                //dotted
                if note.isDotted() {
                    //the dot needs to be moved off the note center to move the dot off a staff line
                    let yOffset = offsetFromStaffMiddle % 2 == 0 ? lineSpacing / 3.0 : 0
                    Ellipse()
                    //Open ellipse
                        .frame(width: noteWidth/3.0, height: noteWidth/3.0)
                    //.position(x: noteFrameWidth/2 + noteWidth/0.90, y: noteEllipseMidpoint - yOffset)
                        .position(x: noteFrameWidth/2 + noteWidth/1.1, y: noteEllipseMidpoint - yOffset)
                        .foregroundColor(note.getColor(staff: staff))
                }
                
                if !note.isOnlyRhythmNote {
                    //if staff.type == .treble {
                    ForEach(getLedgerLines(staff: staff, note: note, noteWidth: noteWidth, lineSpacing: lineSpacing)) { line in
                        let y = geometry.size.height/2.0 + line.offsetVertical
                        let x = noteFrameWidth/2 - noteWidth - (note.rotated ? noteWidth : 0)
                        Path { path in
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + 2 * noteWidth, y: y))
                        }
                        .stroke(note.getColor(staff: staff), lineWidth: 1)
                    }
                    //}
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let noteFrameWidth = geometry.size.width * 1.0 //center the note in the space allocated by the parent for this note's view
                ForEach(getTimeSliceEntries(), id: \.id) { entry in
                    VStack {
                        if entry is Note {
                            NoteView(note: entry as! Note, noteFrameWidth: noteFrameWidth, geometry: geometry, inError: timeSlice.statusTag == .inError)
                            //.border(Color.green)
                        }
                        if entry is Rest {
                            //Spacer()
                            RestView(staff: staff, entry: entry, lineSpacing: lineSpacing, geometry: geometry)
                            //Spacer()
                                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
                            //.border(Color.blue)
                        }
                    }
                }
            }
        }
    }
}
