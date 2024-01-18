import SwiftUI
import CommonLibrary

struct ScoreSpacerView: View {
    var body: some View {
        VStack {
            Text(" ")
            Text(" ")
            Text(" ")
        }
    }
}

struct SelectIntervalView: View {
    @Binding var answer:Answer
    @Binding var answerState:AnswerState
    @ObservedObject var intervals:Intervals
    @State var selectedIntervalName:String?
    var questionType:QuestionType
    var scoreWasPlayed:Bool
    
    ///When using hints random incorrect answer are disabled to make the question easier
    @Binding var hintCorrectAnswer:String
        
    var body: some View {
        HStack(alignment: .top)  {
            let columns:Int = intervals.getVisualColumnCount()
            let enabledToSelect = (questionType == .intervalVisual) || (scoreWasPlayed && questionType == .intervalAural)
            
            ForEach(0..<columns) { column in
                
                //Spacer()
                VStack {
                    let intervalsForColumn = intervals.getVisualColumns(col: column)
                    ForEach(intervalsForColumn, id: \.name) { intervalType in
                        Button(action: {
                            selectedIntervalName = intervalType.name
                            answerState = .answered
                            answer.selectedIntervalName = intervalType.name
                        }) {
                            if enabledToSelect {
                                if intervalType.enabled {
                                    Text(intervalType.name)
                                        .selectedButtonStyle(selected: selectedIntervalName == intervalType.name)
                                }
                                else {
                                    Text(intervalType.name)
                                    .disabledButtonStyle()
                                }
                            }
                            else {
                                Text(intervalType.name).disabledButtonStyle()
                            }
                        }
                        .disabled(!enabledToSelect)
                        .padding()
                    }
                }
                //.padding(.top, 0)
                //.padding()
                //Spacer()
            }
        }
        .onChange(of: hintCorrectAnswer) { hintCorrectAnswer in
            intervals.setRandomSelected(correctIntervalName: hintCorrectAnswer)
        }
    }
}

struct IntervalPresentView: View { //}, QuestionPartProtocol {
    let contentSection:ContentSection
    var grade:Int
    
    @ObservedObject var score:Score
    @ObservedObject private var logger = Logger.logger
    @ObservedObject var audioRecorder = AudioRecorder.shared
    
    @State var examInstructionsWereNarrated = false
    
    @State var intervalNotes:[Note] = []
    @State private var selectedIntervalName:String?
    @State private var selectedOption: String? = nil
    @State private var scoreWasPlayed = false
    @State var intervals:Intervals
    @State var hintCorrectAnswer:String = ""
    @State var presentInstructions = false
    
    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    
    let questionType:QuestionType
    let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"IntervalPresentView")
    let googleAPI = GoogleAPI.shared
    
    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        _answerState = answerState
        _answer = answer
        self.grade = contentSection.getGrade()
        self.intervals = Intervals(grade: grade, questionType: questionType)
    }
    
    func initView() {
        let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
        self.score.createStaff(num: 0, staff: staff)
        
        var chord:Chord?
        if questionType == .intervalAural {
            chord = Chord()
        }
        for timeSlice in score.getAllTimeSlices() {
            if timeSlice.getTimeSliceNotes().count > 0 {
                let note = timeSlice.getTimeSliceNotes()[0]
                intervalNotes.append(note)
                if let chord = chord {
                    let chordNote = Note(timeSlice: timeSlice, num: note.midiNumber, value:2, staffNum: note.staffNum)
                    chordNote.writtenAccidental = note.writtenAccidental
                    chord.addNote(note: chordNote)
                }
            }
        }
        if let chord = chord {
            ///We are adding the two notes as a chord for aural intervals
            ///Add the chord after a bar line to make sure the chord note accidentals stay in place
            ///Then remove the bar line
            score.addBarLine()
            let timeslice = score.createTimeSlice()
            timeslice.addChord(c: chord)
            score.scoreEntries.remove(at: 2)
        }
    }
    
    func buildAnswer() {
        if intervalNotes.count == 0 {
            return
        }
        let halfStepDifference = intervalNotes[1].midiNumber - intervalNotes[0].midiNumber
        
        let staff = score.getStaff()[0]
        let offset1 = intervalNotes[0].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        let offset2 = intervalNotes[1].getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
        let offetDifference = abs(offset2 - offset1)
        
        let explanation = intervals.getExplanation(grade: contentSection.getGrade(), offset1: offset1, offset2: offset2)
        answer.explanation = explanation
        
        func intervalOccursOnlyOnce(_ interval:Int) -> Bool {
            var ctr = 0
            for intervalName in intervals.intervalNames {
                if intervalName.intervals.contains(abs(interval)) {
                    ctr += 1
                }
            }
            return ctr == 1
        }
        
        answer.correct = false
        for intervalName in intervals.intervalNames {
            if intervalName.intervals.contains(abs(halfStepDifference)) {
                if intervalName.noteSpan == offetDifference || intervalOccursOnlyOnce(halfStepDifference) {
                    answer.correctIntervalName = intervalName.name
                    answer.correctIntervalHalfSteps = halfStepDifference
                    if intervalName.name == answer.selectedIntervalName  {
                        answer.correct = true
                        break
                    }
                }
            }
        }
    }
    
    func allowHearInterval() -> Bool {
        return !(contentSection.isTakingExam() && !examInstructionsWereNarrated)
    }
    
    func getInstruction(mode: QuestionType) -> String? {
        if mode == .intervalVisual {
            return "Look at the given interval and choose the correct answer."
        }
        if mode == .intervalAural {
            return "Tap to hear the given interval then choose the correct answer."
        }
        return nil
    }
    
    func instructionView(instruction:String) -> some View {
        ScrollView {
            VStack {
                Text("Instructions").font(.title).foregroundStyle(Color.blue)
                Text(instruction)
                    .defaultTextStyle()
                    .padding()
            }
        }
        .padding()
    }
    
    var body: some View {
        AnyView(
            VStack {
                ScoreSpacerView() //keep for top ledger line notes
                if UIDevice.current.userInterfaceIdiom == .pad {
                    ScoreSpacerView()
                }
                //keep the score in the UI for consistent UIlayout between various usages of this view
                if questionType == .intervalVisual {
                    ScoreView(score: score, widthPadding: true).padding()
                        .roundedBorderRectangle()
                        .opacity(questionType == .intervalAural ? 0.0 : 1.0)
                        .frame(width: UIScreen.main.bounds.width * 0.75)
                }
                
                HStack {
                    if contentSection.isTakingExam() {
                        if examInstructionsWereNarrated {
                            if answerState == .notEverAnswered {
                                Button(action: {
                                    audioRecorder.stopPlaying()
                                    self.contentSection.playExamInstructions(withDelay:false,
                                                                             onLoaded: {status in},
                                                                             onNarrated: {})
                                }) {
                                    Text("Repeat The Instructions").defaultButtonStyle()
                                }
                                .padding()
                            }
                        }
                        else {
                            Text("Please wait for narrated instructions ...").hintAnswerButtonStyle(selected: false)
                        }
                    }
                    
                    if questionType == .intervalAural {
                        VStack {
                            Text("").padding()
                            if allowHearInterval() {
                                Button(action: {
                                    metronome.playScore(score: score, onDone: {
                                        self.scoreWasPlayed = true
                                    })
                                    self.scoreWasPlayed = true
                                }) {
                                    Text("Hear The Interval").defaultButtonStyle(enabled: true)
                                }
                                .padding()
                            }
                            Text("").padding()
                        }
                    }
                    
                    if !contentSection.isTakingExam() {
                        if let instruction = self.getInstruction(mode: self.questionType) {
                            Button(action: {
                                presentInstructions.toggle()
                            }) {
                                VStack {
                                    if UIDevice.current.userInterfaceIdiom == .pad {
                                        Text("Instructions")
                                    }
                                    Image(systemName: "questionmark.circle")
                                }
                                .padding()
                                .roundedBorderRectangle()
                            }
                        }
                    }
                    
                    if !contentSection.isTakingExam() {
                        ///Enable one hint click to reduce number of intervals to choose from
                        if intervals.intervalNames.count > 2 {
                            if (questionType == .intervalVisual) || (scoreWasPlayed && questionType == .intervalAural) {
                                if self.hintCorrectAnswer.count == 0 {
                                    Button(action: {
                                        self.buildAnswer()
                                        self.hintCorrectAnswer = answer.correctIntervalName
                                    }) {
                                        hintButtonView("Get a Hint")
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }

                VStack {
                    if !contentSection.isTakingExam() {
                        if scoreWasPlayed {
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Text("Please select the correct interval").defaultTextStyle().padding()
                                    //.background(Color.white)
                                    .roundedBorderRectangle()
                            }
                        }
                    }
                    HStack {
                        if !(contentSection.isTakingExam() && !examInstructionsWereNarrated) {
                            SelectIntervalView(answer: $answer,
                                               answerState: $answerState,
                                               intervals: intervals,
                                               questionType: questionType,
                                               scoreWasPlayed: scoreWasPlayed,
                                               hintCorrectAnswer: $hintCorrectAnswer)
                            .padding()
                        }
                    }
                    //.padding() ///Dont use - truncates iPhone
                }
                .disabled(questionType == .intervalAural && scoreWasPlayed == false)
                .padding()
                
                if answerState == .answered {
                    VStack {
                        Button(action: {
                            self.buildAnswer()
                            answerState = .submittedAnswer
                        }) {
                            Text("\(contentSection.isTakingExam() ? "Submit" : "Check") Your Answer").submitAnswerButtonStyle()
                        }
                        //.padding()
                    }
                }
                //Spacer()
            }
            .sheet(isPresented: $presentInstructions) {
                if let instructions = self.getInstruction(mode: questionType) {
                    self.instructionView(instruction: instructions)
                }
            }
            .onAppear {
                self.initView()
                if contentSection.isTakingExam() {
                    examInstructionsWereNarrated = false
                    self.contentSection.playExamInstructions(withDelay: true,
                           onLoaded: {
                            status in},
                        onNarrated: {
                            examInstructionsWereNarrated = true
                    })
                }
            }
            .onDisappear() {
                self.audioRecorder.stopPlaying()
            }
        )
    }
}

struct IntervalAnswerView: View {
    let contentSection:ContentSection
    private var questionType:QuestionType
    private var score:Score
    private let imageSize = Double(48)
    private let metronome = Metronome.getMetronomeWithSettings(initialTempo: 40, allowChangeTempo: false, ctx:"Interval answer View")
    private var noteIsSpace:Bool
    private var answer:Answer
    private let intervals:Intervals
    private let grade:Int
    private let melodies = Melodies.shared

    init(contentSection:ContentSection, score:Score, answer:Answer, questionType:QuestionType, refresh:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.score = score
        self.noteIsSpace = true
        metronome.speechEnabled = false
        self.questionType = questionType
        self.answer = answer
        self.grade = contentSection.getGrade()
        self.intervals = Intervals(grade: grade, questionType: questionType)
    }
    
    func getMelodies() -> [Melody] {
        let result:[Melody] = []
        let timeSlices = score.getAllTimeSlices()
        if timeSlices.count < 2 {
            return result
        }
        let firstNote = timeSlices[0].getTimeSliceNotes()[0]
        let halfSteps = timeSlices[1].getTimeSliceNotes()[0].midiNumber - firstNote.midiNumber
        return melodies.getMelodies(halfSteps: halfSteps)
    }
    
    func nextButtons(answerWasCorrect:Bool) -> some View {
        VStack {
            Text(" ")
            HStack {
                Spacer()
                Button(action: {
                    let parent = self.contentSection.parent
                    if let parent = parent {
                        parent.setSelected((parent.selectedIndex ?? 0) - 1)
                    }
                }) {
                    HStack {
                        Text("\u{2190} Previous").defaultButtonStyle()
                    }
                }
                if SettingsMT.shared.isContentSectionLicensed(contentSection: contentSection) {
                    Spacer()
                    Button(action: {
                        let parent = self.contentSection.parent
                        if let parent = parent {
                            parent.setSelected((parent.selectedIndex ?? 0) + 1)
                        }
                    }) {
                        HStack {
                            Text("Next \u{2192}").defaultButtonStyle()
                        }
                    }
                    
                    Spacer()
                    Button(action: {
                        if let parent = self.contentSection.parent {
                            let c = parent.subSections.count
                            let r = Int.random(in: 0...c)
                            parent.setSelected(r)
                        }
                    }) {
                        HStack {
                            Text("\u{2191} Shuffle").defaultButtonStyle()
                        }
                    }
                }
                Spacer()
            }
        }
    }
        
    var body: AnyView {
        AnyView(
            VStack {
                ScoreSpacerView()
                ScoreView(score: score, widthPadding: true).padding()
                    .roundedBorderRectangle()
                    .frame(width: UIScreen.main.bounds.width * 0.75)
                //ScoreSpacerView()
                //ScoreSpacerView()
                
                VStack {
                    HStack {
                        if answer.correct {
                            Image(systemName: "checkmark.circle").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green)
                            Text("Correct - Good Job")
                                .font(UIGlobalsCommon.correctAnswerFont)
                                .defaultTextStyle()
                        }
                        else {
                            Image(systemName: "staroflife.circle").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red)
                            Text("Incorrect")
                                .font(UIGlobalsCommon.correctAnswerFont)
                                .defaultTextStyle()
                        }
                    }
                    //.padding()
                    
                    if !answer.correct {
                        Text("You said that the interval was a \(answer.selectedIntervalName )").defaultTextStyle()
                        //.padding()
                    }
                    Text("The interval is a \(answer.correctIntervalName)").defaultTextStyle().padding()
                    if questionType == .intervalVisual {
                        if answer.correct == false {
                            Text(answer.explanation).defaultTextStyle()
                            //.padding()
                        }
                    }
                }
                .padding()
                .roundedBorderRectangle()
                
                HStack {
                    Button(action: {
                        metronome.playScore(score: score)
                    }) {
                        Text("Hear Interval").defaultButtonStyle()
                    }
                    .padding()
                    
                    if getMelodies().count > 0 {
                        ListMelodiesView(firstNote: score.getAllTimeSlices()[0].getTimeSliceNotes()[0],
                                         intervalName: answer.correctIntervalName,
                                         interval: answer.correctIntervalHalfSteps, melodies: getMelodies())
                        //.background(Color.yellow.opacity(0.1))
                    }
                }
                
                if contentSection.getExamTakingStatus() == .notInExam {
                    //Spacer()
                    nextButtons(answerWasCorrect: answer.correct)
                    //Spacer()
                }
                else {
                    Spacer()
                }
            }
        )
    }
}

struct IntervalView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    let contentSection:ContentSection
    
    var score:Score
    
    @ObservedObject var logger = Logger.logger
    @Binding var answerState:AnswerState
    @Binding var answer:Answer

    let id = UUID()
    let questionType:QuestionType
    
    init(questionType:QuestionType, contentSection:ContentSection, answerState:Binding<AnswerState>, answer:Binding<Answer>) {
        self.questionType = questionType
        self.contentSection = contentSection
        _answerState = answerState
        _answer = answer
        score = contentSection.getScore(staffCount: 1, onlyRhythm: false)
        contentSection.backgroundImageName = UIGlobalsMT.shared.getRandomBackgroundImageName(backgroundSet: SettingsMT.shared.backgroundsSet)
    }
    
    func shouldShowAnswer() -> Bool {
        if let parent = contentSection.parent {
            if parent.isExamTypeContentSection() {
                if answerState  == .submittedAnswer {
                    //Only show answer for exam questions in exam review mode
                    if contentSection.storedAnswer == nil {
                        return false
                    }
                    else {
                        return true
                    }
                } else {
                    return false
                }
            }
            return true
        }
        else {
            return true
        }
    }
            
    var body: some View {
        ZStack {
            VStack {
                let imageName = contentSection.getExamTakingStatus() == .notInExam ? contentSection.backgroundImageName : "app_background_navigation"
                Image(imageName)
                    .resizable()
                    .scaledToFill() // Scales the image to fill the view
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .opacity(UIGlobalsMT.shared.backgroundImageOpacity)
            }

            VStack {
                if answerState  == .notEverAnswered || answerState  == .answered {
                    IntervalPresentView(contentSection: contentSection,
                                        score: self.score,
                                        answerState: $answerState,
                                        answer: $answer,
                                        questionType:questionType)
                    
                }
                else {
                    if shouldShowAnswer() {
                        ZStack {
                            IntervalAnswerView(contentSection: contentSection,
                                               score: self.score,
                                               answer: answer,
                                               questionType:questionType)
                            if SettingsMT.shared.useAnimations {
                                if !contentSection.isExamTypeContentSection() {
                                    FlyingImageView(answer: answer)
                                }
                            }
                        }
                    }
                }
            }

        }

        //.background(Settings.shared.colorBackground)
        //.border(Color.red)
    }
}

