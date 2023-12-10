import SwiftUI
import CommonLibrary
import AVFoundation

struct PracticeToolView: View {
    var text:String
    var body: some View {
        HStack {
            Text("Practice Tool:").defaultTextStyle()
            Text(text).defaultTextStyle()
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        //.background(UIGlobals.backgroundColorLighter)
        .background(Settings.shared.colorInstructions)
        .padding()
    }
}

struct PlayRecordingView: View {
    var buttonLabel:String
    @State var metronome:Metronome
    let fileName:String
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @State private var playingScore:Bool = false
    var onStart: ()->Score?
    var onDone: (()->Void)?
    
    var body: some View {
        VStack {
            Button(action: {
                let score = onStart()
                if let score = score {
                    metronome.playScore(score: score, onDone: {
                        playingScore = false
                        if let onDone = onDone {
                            onDone()
                        }
                    })
                    playingScore = true
                }
                else {
                    audioRecorder.playRecording(fileName: fileName)
                }
            }) {
                if playingScore {
                    Button(action: {
                        playingScore = false
                        metronome.stopPlayingScore()
                    }) {
                        Text("Stop Playing")
                            .defaultButtonStyle()
                        Image(systemName: "stop.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                }
                else {
                    Text(self.buttonLabel)
                        .defaultButtonStyle()
                }
            }
            .padding()
        }
    }
}

struct ClapOrPlayPresentView: View {
    let contentSection:ContentSection

    @ObservedObject var score:Score
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @ObservedObject public var tapRecorder = TapRecorder.shared
    @ObservedObject private var logger = Logger.logger
    @ObservedObject private var metronome:Metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "ClapOrPlayPresentView init @ObservedObject")

    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    @Binding var tryNumber: Int

    @State private var helpPopup = false
    @State var isTapping = false
    @State var rhythmHeard:Bool = false
    @State var examInstructionsNarrated = false
    @State private var rhythmTolerancePercent: Double = 50
    @State private var originalScore:Score?
    @State var isToleranceHelpPresented:Bool = false

    @State private var startWasShortended = false
    @State private var endWasShortended = false
    @State private var rhythmWasSimplified = false
    @State var examInstructionsWereNarrated = false
    @State var countDownTimeLimit:Double = 30.0

    var questionType:QuestionType
    let questionTempo = 90
    let googleAPI = GoogleAPI.shared

    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, answer:Binding<Answer>,
         tryNumber: Binding<Int>, questionType:QuestionType, refresh_unused:(() -> Void)? = nil) {
        self.contentSection = contentSection
        self.questionType = questionType
        _answerState = answerState
        _answer = answer
        _tryNumber = tryNumber
        self.score = score
        if score.staffs.count > 1 {
            self.score.staffs[1].isHidden = true
        }
        self.rhythmHeard = self.questionType == .rhythmVisualClap ? true : false
    }
    
    func examInstructionsDone(status:RequestStatus) {
    }
    
    func getInstruction(mode:QuestionType, grade:Int, examMode:Bool) -> String? {
        var result = ""
        let bullet = "\u{2022}" + " "
        var linefeed = "\n"
        if !UIDevice.current.orientation.isLandscape {
            linefeed = linefeed + "\n"
        }
        switch mode {
        case .rhythmVisualClap:
            result += "\(bullet)Look through the given rhythm."
            result += "\(linefeed)\(bullet)When you are ready to, press Start Recording."
            
            if !examMode {
                result += "\(linefeed)\(bullet)Tap your rhythm on the drum with the pad of your finger and then press Stop Recording once you have finished."
                
                result += "\(linefeed)\(bullet)Advice: For a clear result, you should tap and then immediately release"
                result += " your finger from the screen, rather than holding it down."
                if grade >= 2 {
                result += "\n\n\(bullet)For rests, accurately count them but do not touch the screen."
            }
        }
            
        case .rhythmEchoClap:
            result += "\(bullet)Listen to the given rhythm."
            //result += "\(linefeed)\(bullet)When it has finished you will be able to press Start Recording."
            result += "\(linefeed)\(bullet)Tap your rhythm on the drum that appears and then press Stop Recording once you have finished."
            
            if !examMode {
                result += "\(linefeed)\(bullet)Advice: For a clear result, you should tap with the pad of your finger and then immediately release"
                result += " your finger from the screen, rather than holding it down."
                result += "\n\n\(bullet)If you tap the rhythm incorrectly, you will be able to hear your rhythm attempt and the correct given rhythm at crotchet = 90 on the Answer Page."
            }

        case .melodyPlay:
            result += "\(bullet)Press Start Recording then "
            result += "play the melody and the final chords."
            result += "\(linefeed)\(bullet)When you have finished, stop the recording."
            
        default:
            result = ""
        }
        return result.count > 0 ? result : nil
    }
    
    func getStudentTappingAsAScore() -> Score? {
        if let values = self.answer.values {
            let rhythmAnalysisScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: values)
            return rhythmAnalysisScore
        }
        else {
            return nil
        }
    }
    
    func helpMetronome() -> String {
        let lname = questionType == .melodyPlay ? "melody" : "rhythm"
        var practiceText = "You can adjust the metronome to hear the given \(lname) at varying tempi."
        if questionType == .melodyPlay {
            practiceText += " You can also tap the picture of the metronome to practise along with the tick."
        }
        return practiceText
    }
    
    func rhythmIsCorrect() -> Bool {
        guard let tapValues = answer.values else {
            return false
        }
        let tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        let fittedScore = score.fitScoreToQuestionScore(tappedScore:tappedScore, tolerancePercent: UIGlobals.rhythmTolerancePercent).0
        if fittedScore.errorCount() == 0 && fittedScore.getAllTimeSlices().count > 0 {
            return true
        }
        return false
    }
         
    func instructionView() -> some View {
        VStack {
            if let instruction = self.getInstruction(mode: self.questionType, grade: contentSection.getGrade(),
                                                     examMode: contentSection.getExamTakingStatus() == .inExam) {
                ScrollView {
                    Text(instruction)
                        .defaultTextStyle()
                        .padding()
                }
            }
        }
//        .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .leading)
        ///Limit the size of the scroller since otherwise it takes as much height as it can
        .frame(height: UIScreen.main.bounds.height * 0.10)
        .overlay(
            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
        )
        .padding()
    }
    
    func recordingWasStarted() -> Bool {
        if questionType == .melodyPlay {
            return false
        }
        if answerState == .notEverAnswered {
            DispatchQueue.main.async {
                //sleep(1)
                answerState = .recording
                metronome.stopTicking()
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                    self.isTapping = true
                    tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.tempo)
                } else {
                    audioRecorder.startRecording(fileName: contentSection.name)
                }
            }
            return true
        }
        return false
    }
    
    func nextStepText() -> String {
        var next = ""
        if questionType == .melodyPlay {
            if contentSection.getExamTakingStatus() == .inExam {
                next = "Submit Your Answer"
            }
            else {
                next = "See The Answer"
            }
        }
        else {
            next = contentSection.getExamTakingStatus() == .inExam ? "Submit" : "Check"
            next += " Your Answer"
        }
        return next
    }
    
    func log()->Bool {
        return true
    }
    
    func shouldOfferToPlayRecording() ->Bool {
        var play = false
        if contentSection.getExamTakingStatus() == .inExam {
            if examInstructionsNarrated {
                if questionType == .rhythmEchoClap && answerState != .recorded{
                    play = true
                }
            }
        }
        else {
            play = true
        }
        return play
    }
    
    func buttonsView() -> some View {
        VStack {
            HStack {
                if contentSection.getExamTakingStatus() == .inExam && answerState != .recorded {
                    if examInstructionsWereNarrated {
                        Button(action: {
                                self.contentSection.playExamInstructions(withDelay: true,
                                                                         onLoaded: {status in },
                                                                         onNarrated: {
                                    examInstructionsWereNarrated = true
                                })
                            }) {
                                Text("Repeat Instructions").defaultButtonStyle()
                            }
                            .padding()
                        }
                }
            }
            
            ///Allow editing (simplifying of the rhythm and a button to restor ethe question rhythm if it was edited
            if contentSection.getExamTakingStatus() != .inExam {
                if questionType == .rhythmEchoClap {
                    if tryNumber > 0 {
                        ///Student can edit only if they've heard the full rhythm previously. i.e. try == 0
                        showEditButtons()
                    }
                }
            }

            HStack {
                let uname = questionType == .melodyPlay ? "Melody" : "Rhythm"
                if answerState != .recording {
                    if shouldOfferToPlayRecording() {
                        PlayRecordingView(buttonLabel: "Hear The \(uname)",
                                          metronome: metronome,
                                          fileName: contentSection.name,
                                          onStart: {
                                            return score
                                            },
                                          onDone: {rhythmHeard = true}
                        )
                    }
                }
                
                if answerState == .recorded {
                    if !(contentSection.getExamTakingStatus() == .inExam) {
                        PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                          metronome: self.metronome,
                                          fileName: contentSection.name,
                                          onStart: ({
                            if questionType == .melodyPlay {
                                ///Play from the audio ecording
                                return nil
                            }
                            else {
                                if let recordedScore = getStudentTappingAsAScore() {
                                    if let recordedtempo = recordedScore.tempo {
                                        metronome.setTempo(tempo: recordedtempo, context:"start hear student")
                                    }
                                }
                                return getStudentTappingAsAScore()
                            }
                        }),
                        onDone: ({
                            //recording was played at the student's tempo and now reset metronome
                            metronome.setTempo(tempo: self.questionTempo, context: "end hear student")
                        })
                        )
                    }
                }
            }
        }
    }
    
    func recordingStartView() -> some View {
        VStack {
            ///For echo clap present the tapping view right after the rhythm is heard (without requiring a button press)
            if questionType == .melodyPlay || questionType == .rhythmVisualClap || !recordingWasStarted() {
                Button(action: {
                    if contentSection.getExamTakingStatus() == .inExam {
                        self.audioRecorder.stopPlaying()
                    }
                    answerState = .recording
                    metronome.stopTicking()
                    score.barEditor = nil
                    if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                        self.isTapping = true
                        tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.tempo)
                    } else {
                        if !audioRecorder.checkAudioPermissions() {
                            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                                audioRecorder.startRecording(fileName: contentSection.name)
                            }
                        }
                        else {
                            audioRecorder.startRecording(fileName: contentSection.name)
                        }
                    }
                }) {
                    if answerState == .recorded {
                        if !(contentSection.getExamTakingStatus() == .inExam) {
                            Text("Redo Recording")
                                .defaultButtonStyle(enabled: rhythmHeard || questionType != .intervalAural)
                        }
                    }
                    else {
                        Text("Start Recording")
                            .defaultButtonStyle(enabled: rhythmHeard || questionType != .intervalAural)
                    }
                }
                .disabled(!(rhythmHeard || questionType != .intervalAural))
            }
        }
    }
    
    func getToleranceLabel(_ setting:Double) -> String {
        var name = UIDevice.current.userInterfaceIdiom == .pad ? "Rhythm Tolerance:" : "Tolerance"
        //if UIDevice.current.userInterfaceIdiom == .pad {
        var grade:String? = nil
        while grade == nil {
            if setting < 35.0 {
                grade = "A+"
                break
            }
            if setting < 40.0 {
                grade = "A"
                break
            }
            if setting < 45.0 {
                grade = "A-"
                break
            }
            if setting < 50.0 {
                grade = "B+"
                break
            }
            if setting < 55.0 {
                grade = "B"
                break
            }
            if setting < 60.0 {
                grade = "B-"
                break
            }
            if setting < 65.0 {
                grade = "C+"
                break
            }
            if setting <= 70.0 {
                grade = "C"
                break
            }
            break
        }
        if let grade = grade {
            name += " " + grade
        }
        //let percent = " " + String(format: "%.0f", setting) + "%"
        //name += percent
        return name
    }
    
    func setRhythmToleranceView() -> some View {
        HStack {
            VStack {
                HStack {
                    Text(getToleranceLabel(rhythmTolerancePercent)).defaultTextStyle()
                    Button(action: {
                        self.isToleranceHelpPresented = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(UIDevice.current.userInterfaceIdiom == .pad ? .largeTitle : .title3)
                    }
                }
                .sheet(isPresented: $isToleranceHelpPresented) {
                    VStack {
                        Text("Rhythm Matching Tolerance").font(.title).foregroundColor(.blue).padding()
                        Text("The rhythm tolerance setting affects how precisely your tapped rhythm is measured for correctness.").padding()
                        Text("Higher grades of tolerance require more precise tapping to achieve a correct rhythm. Lower grades require less precise tapping.").padding()
                    }
                }
                Slider(value: $rhythmTolerancePercent, in: 30...70).padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 50 : 4)
            }
            .onChange(of: rhythmTolerancePercent) { newValue in
                let allowedValues = [30, 35, 40, 45, 50, 55, 60, 65, 70]
                let sortedValues = allowedValues.sorted()
                let closest = sortedValues.min(by: { abs($0 - Int(newValue)) < abs($1 - Int(newValue)) })
                UIGlobals.rhythmTolerancePercent = Double(closest ?? Int(newValue))//newValue
                rhythmTolerancePercent = UIGlobals.rhythmTolerancePercent
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
            )
            .background(Settings.shared.colorScore)
            .padding()
        }
    }
    
    func showEditButtons() -> some View {
        VStack {
            if score.getBarCount() > 1 {
                ///Enable bar manager to edit out bars in the given rhythm
                Button(action: {
                    score.createBarEditor(onEdit: scoreEditedNotification)
                    score.barEditor?.reWriteBar(targetBar: 0, way: .delete)
                    self.startWasShortended = true
                    //}
                }) {
                    hintButtonView("Remove The Rhythm Start", selected: startWasShortended)
                }
                .padding()
                Button(action: {
                    score.createBarEditor(onEdit: scoreEditedNotification)
                    //score.barEditor?.notifyFunction = self.notifyScoreEditedFunction
                    score.barEditor?.reWriteBar(targetBar: score.getBarCount()-1, way: .delete)
                    self.endWasShortended = true
                }) {
                    hintButtonView("Remove The Rhythm End", selected: endWasShortended)
                }
                .padding()
            }
            if let originalScore = originalScore {
                if score.getBarCount() != originalScore.getBarCount() {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        //This button just cant fit on iPhone display
                        Button(action: {
                            score.copyEntries(from: originalScore)
                            self.endWasShortended = false
                            self.startWasShortended = false
                        }) {
                            hintButtonView("Put Back The Question Rhythm", selected: false)
                        }
                        .padding()
                    }
                }
            }
        }
    }

    func scoreEditedNotification(_ wasChanged:Bool) -> Void {
        if !self.rhythmWasSimplified {
            self.rhythmWasSimplified = wasChanged
        }
    }
    
    var body: AnyView {
        AnyView(
            VStack {
                if contentSection.getExamTakingStatus() == .inExam {
                    Text(" ")
                }
                else {
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        //if questionType == .melodyPlay || questionType == .rhythmEchoClap {
                            ToolsView(score: score, helpMetronome: helpMetronome())
//                        }
//                        else {
//                            Text(" ")
//                        }
                    }
                }

                if questionType == .rhythmVisualClap || questionType == .melodyPlay {
                    //ScoreSpacerView()
                    ScoreView(score: score).padding()
                    //ScoreSpacerView()
                }
                
                ///Option for editing the rhythm and restoring the rhythm to the original if the rhythm was edited
                if answerState != .recording {
                    if contentSection.getExamTakingStatus() != .inExam {
                        HStack {
                            if questionType == .rhythmVisualClap {
                                if score.getBarCount() > 1 {
                                    //HStack {
                                    ///Enable bar manager to edit out bars in the given rhythm
                                    if score.barEditor == nil {
                                        Button(action: {
                                            score.createBarEditor(onEdit: scoreEditedNotification)
                                        }) {
                                            hintButtonView("Simplify the Rhythm", selected: self.rhythmWasSimplified)
                                        }
                                        .padding()
                                    }
                                    if let originalScore = originalScore {
                                        if score.getBarCount() != originalScore.getBarCount() {
                                            if UIDevice.current.userInterfaceIdiom == .pad {
                                                //This button just cant fit on iPhone display                                                
                                                Button(action: {
                                                    score.barLayoutPositions = BarLayoutPositions()
                                                    score.copyEntries(from: originalScore)
                                                    self.rhythmWasSimplified = false
                                                }) {
                                                    hintButtonView("Put Back The Question Rhythm", selected: false)
                                                }
                                                .padding()
                                            }
                                        }
                                    }
                                    //}
                                }
                            }

                        }
                    }
                    if questionType != .melodyPlay {
                        setRhythmToleranceView()
                    }
                }
                                
                if questionType == .melodyPlay {
                    if answerState != .recording {
                        CountdownTimerView(size: 50.0, timerColor: .blue, timeLimit: $countDownTimeLimit, startNotification: {}, endNotification: {})
                    }
                }
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if UIDevice.current.orientation.isPortrait {
                        //if UIGlobals.showDeviceOrientation() {
                            instructionView()
                        //}
                    }
                }
                
                HStack {
                    if answerState != .recording {
                        buttonsView()
                        Text(" ")
                        if contentSection.getExamTakingStatus() == .inExam {
                            if examInstructionsNarrated {
                                recordingStartView()
                            }
                            else {
                                Text("Please wait for narrated instructions ...").hintAnswerButtonStyle(selected: false)
                            }
                        }
                        else {
                            if rhythmHeard || questionType == .melodyPlay || questionType == .rhythmVisualClap {
                                recordingStartView()
                            }
                        }
                    }
                    
                    if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                        if answerState == .recording {
                            if questionType == .rhythmEchoClap {
                                PlayRecordingView(buttonLabel: "Hear The Given Rhythm", // Again",
                                                  metronome: metronome,
                                                  fileName: contentSection.name,
                                                  onStart: {
                                                        return score
                                                    },
                                                  onDone: {})
                                
                                ///Allow editing (simplifying of the rhythm and a button to restor ethe question rhythm if it was edited
                                if contentSection.getExamTakingStatus() != .inExam {
                                    if questionType == .rhythmEchoClap {
                                        showEditButtons()
                                    }
                                }
                            }
                    
                        }
                    }

                    if questionType == .melodyPlay {
                        if answerState == .recording {
                            Button(action: {
                                answerState = .recorded
                                audioRecorder.stopRecording()
                                answer.recordedData = self.audioRecorder.getRecordedAudio(fileName: contentSection.name)
                            }) {
                                Text("Stop Recording")
                                    .defaultButtonStyle()
                            }
                            .padding()
                        }
                    }
                }
                
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                    if answerState == .recording {
                        TappingView(isRecording: $isTapping, tapRecorder: tapRecorder, onDone: {
                            answerState = .recorded
                            self.isTapping = false
                            answer.values = self.tapRecorder.stopRecording(score:score)
                            isTapping = false
                        })
                    }
                }
                
                //Check answer
                if answerState == .recorded {
                    HStack {
                        Button(action: {
                            answerState = .submittedAnswer
                            if questionType == .melodyPlay {
                                answer.correct = true
                            }
                            else {
                                answer.correct = rhythmIsCorrect()
                            }
                            score.setHiddenStaff(num: 1, isHidden: false)
                        }) {
                            Text(nextStepText()).submitAnswerButtonStyle()
                        }
                        .padding()
                    }
                }
            }
            .font(.system(size: UIDevice.current.userInterfaceIdiom == .phone ? UIFont.systemFontSize : UIFont.systemFontSize * 1.6))
            .onAppear() {
                examInstructionsNarrated = false
                if contentSection.getExamTakingStatus() == .inExam {
                    self.contentSection.playExamInstructions(withDelay: true,
                           onLoaded: {
                            status in},
                        onNarrated: {
                            examInstructionsNarrated = true
                    })
                }

                metronome.setTempo(tempo: 90, context: "View init")
                //if questionType == .rhythmEchoClap || questionType == .melodyPlay {
                    metronome.setAllowTempoChange(allow: true)
//                }
//                else {
//                    metronome.setAllowTempoChange(allow: false)
//                }
                if questionType == .melodyPlay {
                    score.addTriadNotes()
                }
                self.rhythmTolerancePercent = UIGlobals.rhythmTolerancePercent
                self.originalScore = contentSection.parseData(staffCount: 1, onlyRhythm: true)
            }
            .onDisappear() {
                self.audioRecorder.stopPlaying()
                //self.metronome.stopPlayingScore()
            }
        )
    }
}

struct ClapOrPlayAnswerView: View {
    let contentSection:ContentSection
    @ObservedObject var tapRecorder = TapRecorder.shared
    @ObservedObject private var logger = Logger.logger
    @ObservedObject var audioRecorder = AudioRecorder.shared
    var answerMetronome:Metronome
    @Binding var answerState:AnswerState
    @Binding var tryNumber: Int

    @State var playingCorrect = false
    @State var playingStudent = false
    @State var speechEnabled = false
    @State var fittedScore:Score?
    //@State var tryingAgain = false

    @State private var score:Score
    @State var hoveringForHelp = false
    @State var originalScore:Score?
    @State var scoreCurrentBarCount:Int = 0

    private var questionType:QuestionType
    private var answer:Answer
    let questionTempo = 90
    
    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, tryNumber:Binding<Int>, answer:Answer, questionType:QuestionType) {
        self.contentSection = contentSection
        self.score = score //contentSection.getScore(staffCount: questionType == .melodyPlay ? 2 : 1, onlyRhythm: questionType == .melodyPlay ? false : true)
        self.questionType = questionType
        self.answerMetronome = Metronome.getMetronomeWithCurrentSettings(ctx:"ClapOrPlayAnswerView")
        self.answer = answer
        _answerState = answerState
        _tryNumber = tryNumber
        answerMetronome.setSpeechEnabled(enabled: self.speechEnabled)
    }
    
    func analyseStudentRhythm() {
        guard let tapValues = answer.values else {
            return
        }
        
        let tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        tappedScore.label = "Your Rhythm"
        
        ///Checks -
        ///1) all notes in the question have taps at the same time location
        ///2) no taps are in a location where there is no question note
        ///
        ///If the student got the test correct then ensure that what they saw that they tapped exaclty matches the question.
        ///Otherwise, try to make the studnets tapped score look the same as the question score up until the point of error
        ///(e.g. a long tap might correctly represent either a long note or a short note followed by a rest. So mark the tapped score accordingingly

        let fitted = score.fitScoreToQuestionScore(tappedScore:tappedScore, tolerancePercent: UIGlobals.rhythmTolerancePercent)
        self.fittedScore = fitted.0
        let feedback = fitted.1
        
        if self.fittedScore == nil {
            return
        }

        self.answerMetronome.setAllowTempoChange(allow: false)
        self.answerMetronome.setTempo(tempo: self.questionTempo, context: "ClapOrPlayAnswerView")

        if let fittedScore = self.fittedScore {
            if fittedScore.errorCount() == 0 && fittedScore.getAllTimeSlices().count > 0 {
                feedback.correct = true
                feedback.feedbackExplanation = "Good job!"
                if let recordedTempo = tappedScore.tempo {
                    self.answerMetronome.setAllowTempoChange(allow: true)
                    self.answerMetronome.setTempo(tempo: recordedTempo, context: "ClapOrPlayAnswerView")
                    let questionTempo = Metronome.getMetronomeWithCurrentSettings(ctx: "for clap answer").tempo
                    let tolerance = Int(CGFloat(questionTempo) * 0.2)
                    if questionType == .rhythmVisualClap {
                        feedback.feedbackExplanation! +=
                        " Your tempo was \(recordedTempo)."
                    }
                    if questionType == .rhythmEchoClap {
                        feedback.feedbackExplanation! +=
                        " Your tempo was \(recordedTempo) "
                        if recordedTempo < questionTempo - tolerance || recordedTempo > questionTempo + tolerance {
                            feedback.feedbackExplanation! +=
                            "which was \(recordedTempo < questionTempo ? "slower" : "faster") than the question tempo \(questionTempo) you heard."
                        }
                        else {
                            feedback.feedbackExplanation! += "."
                        }
                    }
                }
            }
            else {
                feedback.correct = false
            }
            self.fittedScore!.setStudentFeedback(studentFeedack: feedback)
        }
    }
    
    func helpMetronome() -> String {
        let lname = questionType == .melodyPlay ? "melody" : "rhythm"
        var practiceText = "You can adjust the metronome to hear the given \(lname) at varying tempi."
        //if mode == .melodyPlay {
            practiceText += " You can also tap the picture of the metronome to practise along with the tick."
        //}
        return practiceText
    }
    
    func nextButtons() -> some View {
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
                Spacer()
            }
        }
    }
    
    func helpMessage() -> String {
        var msg = "\u{2022} You can modify the question's rhythm to make it easier to clap the rhythm that was difficult"
        msg = msg + "\n\n\u{2022} Select the bar you would like to be made simpler"
        msg = msg + "\n\n\u{2022} You can then -"
        msg = msg + "\n Delete the bar "
        msg = msg + "\n Set the bar to crotchets "
        msg = msg + "\n Set the bar to rests"
        msg = msg + "\n Undo all changes to the bar"
        msg = msg + "\n\n\u{2022} Then you can try again with the easier rhythm"
        return msg
    }
        
//    func log(_ score:Score) -> Bool {
//    print ("========", score == nil, score.studentFeedback == nil)
//       return true
//    }
    
    func restoreQuestionView() -> some View {
        VStack {
            if let originalScore = originalScore {
                if self.scoreCurrentBarCount != originalScore.getBarCount() {
                    Button(action: {
                        score.copyEntries(from: originalScore)
                        self.scoreCurrentBarCount = self.score.getBarCount()
                        if let fittedScore = fittedScore {
                            if let studentFeedback = fittedScore.studentFeedback {
                                ///Force the retry button to appear so the student now tries the original question
                                studentFeedback.correct = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Put Back The Question Rhythm").submitAnswerButtonStyle()
                        }
                    }
                }
            }
        }
    }
    
    func nextStepsView() -> some View {
        HStack {
            if contentSection.getExamTakingStatus() == .notInExam {
                if let fittedScore = self.fittedScore {
                    if let studentFeedback = fittedScore.studentFeedback {
                        if studentFeedback.correct {
                            if self.originalScore != nil {
                                if studentFeedback.correct {
                                    nextButtons()
                                }
                            }
                        }
                        else {
                            HStack {
                                Button(action: {
                                    answerState = .notEverAnswered
                                    self.tryNumber += 1
                                }) {
                                    Text("Try Again").submitAnswerButtonStyle() //defaultButtonStyle()
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
        }
    }

    var body: AnyView {
        AnyView(
            VStack {
                //if UIDevice.current.userInterfaceIdiom != .phone {
                    if questionType != .melodyPlay {
                        ToolsView(score: score, helpMetronome: helpMetronome())
                    }
                    else {
                        Text(" ")
                    }
                //}
                //ScoreSpacerView()
                if questionType == .melodyPlay {
                    ScoreSpacerView()
                }
                ScoreView(score: score).padding()
                //ScoreSpacerView()
                if questionType == .melodyPlay {
                    ScoreSpacerView()
                }
                if let fittedScore = self.fittedScore {
                    Text(" ")
                    //ScoreSpacerView()
                    ScoreView(score: fittedScore).padding()
                    //ScoreSpacerView()
                }

                HStack {
                    PlayRecordingView(buttonLabel: "Hear The Given \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                      //score: getCurrentScore(),
                                      metronome: answerMetronome,
                                      fileName: contentSection.name,
                                      onStart: {return score})

                    if questionType == .melodyPlay {
                        PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                          metronome: answerMetronome,
                                          fileName: contentSection.name,
                                          onStart: {return nil})
                    }
                    else {
                        if let fittedScore = self.fittedScore {
                            PlayRecordingView(buttonLabel: "Hear Your \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                              metronome: answerMetronome,
                                              fileName: contentSection.name,
                                              onStart: {return fittedScore})
                        }
                    }
                }
                
                restoreQuestionView()
                nextStepsView()
                
                //Spacer() //Keep - required to align the page from the top
            }
            .onAppear() {
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                    analyseStudentRhythm()
                }
                else {
                    answerMetronome.setTempo(tempo: questionTempo, context: "AnswerMode::OnAppear")
                }
                ///Load score again since it may have changed due student simplifying the rhythm. The parent of this view that loaded the original score is not inited again on a retry of a simplified rhythm.
                //score = contentSection.getScore(staffCount: questionType == .melodyPlay ? 2 : 1, onlyRhythm: questionType != .melodyPlay)

                ///Disable bar editing in answer mode
                score.barEditor = nil
                score.setHiddenStaff(num: 1, isHidden: false)
                
                ///Set the chord triad links
                if questionType == .melodyPlay {
                    score.addTriadNotes()
                }
                self.originalScore = contentSection.parseData(staffCount: 1, onlyRhythm: true)
                self.scoreCurrentBarCount = score.getBarCount()
            }
            .onDisappear() {
                audioRecorder.stopPlaying()
            }
        )
    }
}

struct ClapOrPlayView: View {
    let contentSection: ContentSection
    @ObservedObject var logger = Logger.logger
    @Binding var answerState:AnswerState
    @Binding var answer:Answer
    let id = UUID()
    let questionType:QuestionType
    @State var tryNumber: Int = 0
    
    ///Score is created here and shared between the present view and the answer view. The present view might cause the contents of score to change with a rhythm simplifying edit.
    ///It appears to be pass to the child view by refernece since changes to score in the present view propagate tp the answer view as required
    //@State
    var score:Score

    init(questionType:QuestionType, contentSection:ContentSection, answerState:Binding<AnswerState>, answer:Binding<Answer>) {
        self.questionType = questionType
        self.contentSection = contentSection
        _answerState = answerState
        _answer = answer
        self.score = contentSection.parseData(staffCount: questionType == .melodyPlay ? 2 : 1, onlyRhythm: questionType == .melodyPlay ? false : true)
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
        VStack {
            if answerState  != .submittedAnswer {
                ClapOrPlayPresentView(
                    contentSection: contentSection,
                    score: score,
                    answerState: $answerState,
                    answer: $answer,
                    tryNumber: $tryNumber,
                    questionType: questionType)
                .frame(width: UIScreen.main.bounds.width)
                Spacer()
            }
            else {
                if shouldShowAnswer() {
                    ZStack {
                        ClapOrPlayAnswerView(contentSection: contentSection,
                                             score: score,
                                             answerState: $answerState,
                                             tryNumber: $tryNumber,
                                             answer: answer,
                                             questionType: questionType)
                        if Settings.shared.useAnimations {
                            if !contentSection.isExamTypeContentSection() {
                                if !(self.questionType == .melodyPlay) {
                                    FlyingImageView(answer: answer)
                                }
                            }
                        }
                    }
                }
                Spacer() //Force it to align from the top
            }
        }
        .background(Settings.shared.colorBackground)

        .onDisappear {
            let metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "")
            metronome.stopTicking()
            metronome.stopPlayingScore()
        }
    }

}
