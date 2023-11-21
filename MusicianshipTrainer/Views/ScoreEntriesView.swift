import SwiftUI
import CoreData
import CommonLibrary

struct TimeSliceLabelView: View {
    var score:Score
    var staff:Staff
    @ObservedObject var timeSlice:TimeSlice
    @State var showPopover = false
    @State var font = Font.system(size:0) //)//Font.custom("TimesNewRomanPS-BoldMT", size: score.lineSpacing * 1.5)

    var body: some View {
        ZStack {
            if staff.staffNum == 0 {
                if let tag = timeSlice.tagHigh {
                    VStack {
                        if tag.enablePopup {
                            if tag.popup != nil {
                                Button(action: {
                                    showPopover.toggle()
                                }) {
                                    Text(tag.content).font(font)
                                }
                            }
                            else {
                                Text(tag.content).font(font)
                            }
                        }
                        else {
                            Text(tag.content).font(font).defaultTextStyle()
                        }
                        Spacer()
                    }
                    .popover(isPresented: $showPopover) {
                        Text(tag.popup ?? "").font(font).padding()
                    }
                }
                if let tag = timeSlice.tagLow {
                    VStack {
                        Spacer()
                        Text(tag).font(font).defaultTextStyle()
                    }
                }
            }
        }
        .onAppear() {
            font = Font.custom("TimesNewRomanPS-BoldMT", size: score.lineSpacing * 2.0)
        }
        //.border(Color.red)
    }
}


struct ScoreEntriesView: View {
    @ObservedObject var noteLayoutPositions:NoteLayoutPositions
    @ObservedObject var barLayoutPositions:BarLayoutPositions

    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    
    static var viewNum:Int = 0
    let noteOffsetsInStaffByKey = NoteOffsetsInStaffByKey()
    let viewNum:Int
    
    init(score:Score, staff:Staff) {
        self.score = score
        self.staff = staff
        self.noteLayoutPositions = staff.noteLayoutPositions
        self.barLayoutPositions = score.barLayoutPositions
        ScoreEntriesView.viewNum += 1
        self.viewNum = ScoreEntriesView.viewNum
    }
        
    func getNote(entry:ScoreEntry) -> Note? {
        if entry is TimeSlice {
            //if let
                let notes = entry.getTimeSliceNotes()
                if notes.count > 0 {
                    return notes[0]
                }
            //}
        }
        return nil
    }
    
    ///Return the start and end points for te quaver beam based on the note postions that were reported
    func getBeamLine(endNote:Note, noteWidth:Double, startNote:Note, stemLength:Double) -> (CGPoint, CGPoint)? {
        let stemDirection:Double = startNote.stemDirection == .up ? -1.0 : 1.0
        if startNote.timeSlice.statusTag == .inError {
            return nil
        }
        let endNotePos = noteLayoutPositions.positions[endNote]
        if let endNotePos = endNotePos {
            let xEndMid = endNotePos.origin.x + endNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
            let yEndMid = endNotePos.origin.y + endNotePos.size.height / 2.0
            
            let endPitchOffset = endNote.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
            let yEndNoteMiddle:Double = yEndMid + (Double(endPitchOffset) * score.lineSpacing * -0.5)
            let yEndNoteStemTip = yEndNoteMiddle + stemLength * stemDirection
            
            //start note
            let startNotePos = noteLayoutPositions.positions[startNote]
            if let startNotePos = startNotePos {
                let xStartMid = startNotePos.origin.x + startNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
                let yStartMid = startNotePos.origin.y + startNotePos.size.height / 2.0
                let startPitchOffset = startNote.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
                let yStartNoteMiddle:Double = yStartMid + (Double(startPitchOffset) * score.lineSpacing * -0.5)
                let yStartNoteStemTip = yStartNoteMiddle + stemLength * stemDirection
                let p1 = CGPoint(x:xEndMid, y: yEndNoteStemTip)
                let p2 = CGPoint(x:xStartMid, y:yStartNoteStemTip)
                return (p1, p2)
            }
        }
        return nil
    }
        
//    func getLineSpacing() -> Double {
//        return self.lineSpacing
//    }

    func getQuaverImage(note:Note) -> Image {
        return Image(note.midiNumber > 71 ? "quaver_arm_flipped_grayscale" : "quaver_arm_grayscale")
    }

    func quaverBeamView(line: (CGPoint, CGPoint), startNote:Note, endNote:Note, lineSpacing: Double) -> some View {
        ZStack {
            if startNote.sequence == endNote.sequence {
                //An unpaired quaver
                let height = lineSpacing * 4.5
                let width = height / 3.0
                let flippedHeightOffset = startNote.midiNumber > 71 ? height / 2.0 : 0.0
                getQuaverImage(note:startNote)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(startNote.getColor(staff: staff))
                    .scaledToFit()
                    .frame(height: height)
                    .position(x: line.0.x + width / 3.0 , y: line.1.y + height / 3.5 - flippedHeightOffset)
                
                if endNote.getValue() == Note.VALUE_SEMIQUAVER {
                    getQuaverImage(note:startNote)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(startNote.getColor(staff: staff))
                        .scaledToFit()
                        .frame(height: height)
                        .position(x: line.0.x + width / 3.0 , y: line.1.y + height / 3.5 - flippedHeightOffset + lineSpacing)
                }
            }
            else {
                //A paired quaver
                Path { path in
                    path.move(to: CGPoint(x: line.0.x, y: line.0.y))
                    path.addLine(to: CGPoint(x: line.1.x, y: line.1.y))
                }
                .stroke(endNote.getColor(staff: staff), lineWidth: 3)
                //.stroke(lineWidth: 3)
            }
        }
    }
    
    var body: some View {
        ZStack {
            let noteWidth = score.lineSpacing * 1.2
            HStack(spacing: 0) { //HStack - score entries display along the staff
                ForEach(score.scoreEntries) { entry in
                    ZStack { //VStack - required in forEach closure
                        if let timeSlice = entry as? TimeSlice {
                            let entries = entry as! TimeSlice
                            ZStack { // Each note frame in the timeslice shares the same same vertical space
                                TimeSliceView(staff: staff,
                                              timeSlice: entries,
                                              noteWidth: noteWidth,
                                              lineSpacing: score.lineSpacing)
                                //.border(Color.green)
                                .background(GeometryReader { geometry in
                                    ///Record and store the note's postion so we can later draw its stems which maybe dependent on the note being in a quaver group with a quaver beam
                                    Color.clear
                                        .onAppear {
                                            if timeSlice.statusTag != .inError {
                                                if staff.staffNum == 0 {
                                                    noteLayoutPositions.storePosition(notes: entries.getTimeSliceNotes(),rect: geometry.frame(in: .named("HStack")))
                                                }
                                            }
                                        }
                                        .onChange(of: score.lineSpacing) { newValue in
                                            if staff.staffNum == 0 {
                                                noteLayoutPositions.storePosition(notes: entries.getTimeSliceNotes(),rect: geometry.frame(in: .named("HStack")))
                                            }
                                        }
                                })
                                if timeSlice.statusTag != .inError {
                                    StemView(score:score,
                                             staff:staff,
                                             notePositionLayout: noteLayoutPositions,
                                             notes: entries.getTimeSliceNotes())
                                }

                                TimeSliceLabelView(score:score, staff:staff, timeSlice: entry as! TimeSlice)
                                    .frame(height: score.getStaffHeight())
                            }
                        }
                        if entry is BarLine {
                            GeometryReader { geometry in
                                BarLineView(score: score, entry: entry, staff: staff) //, staffLayoutSize: staffLayoutSize)
                                    .frame(height: score.getStaffHeight())
                                    //.border(Color .red)
                                    .onAppear {
                                        if staff.staffNum == 0 {
                                            let barLine = entry as! BarLine
                                            barLayoutPositions.storePosition(barLine: barLine, rect: geometry.frame(in: .named("ScoreView")), ctx: "onAppear")
                                        }
                                    }
                                    .onChange(of: score.lineSpacing) { newValue in
                                        if staff.staffNum == 0 {
                                            let barLine = entry as! BarLine
                                            barLayoutPositions.storePosition(barLine: barLine, rect: geometry.frame(in: .named("ScoreView")), ctx: "onChange")
                                        }
                                    }
                            }
                        }
                    }
                    .coordinateSpace(name: "VStack")
                    //IMPORTANT - keep this since the quaver beam code needs to know exactly the note view width
                }
                //.coordinateSpace(name: "ForEach")
                ///Spacing before end of staff
                Text(" ")
                    .frame(width:1.5 * noteWidth)
            }
            .coordinateSpace(name: "HStack")

            // ---------- Quaver beams ------------
            
            if staff.staffNum == 0 {
                GeometryReader { geo in
                    ZStack {
                        ZStack {
                            //let log = log(noteLayoutPositions: noteLayoutPositions)
                            ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.sequence < $1.key.sequence }), id: \.key.id) {
                                endNote, endNotePos in
                                if endNote.beamType == .end {
                                    let startNote = endNote.getBeamStartNote(score: score, np:noteLayoutPositions)
                                    if let line = getBeamLine(endNote: endNote,
                                                              noteWidth: noteWidth,
                                                              startNote: startNote,
                                                              stemLength:score.lineSpacing * 3.5) {
                                        quaverBeamView(line: line, startNote: startNote, endNote: endNote, lineSpacing: score.lineSpacing)
                                    }
                                }
                            }
                        }
                        //.border(Color .red)
                        .padding(.horizontal, 0)
                    }
                    //.border(Color .orange)
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, 0)
                //.border(Color .green)
            }
        }
        .coordinateSpace(name: "ZStack0")
        .onAppear() {
        }
        .onDisappear() {
           // NoteLayoutPositions.reset()
        }
    }
    
}

