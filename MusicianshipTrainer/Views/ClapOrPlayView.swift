import SwiftUI
import CommonLibrary
import AVFoundation

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
    @State private var originalScore:Score?

    @State private var startWasShortended = false
    @State private var endWasShortended = false
    @State private var rhythmWasSimplified = false
    @State var examInstructionsWereNarrated = false
    @State var countDownTimeLimit:Double = 30.0
    @State var presentInstructions = false
    
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
        
        ///Some iPads too short in landscape mode
        score.heightPaddingEnabled = UIGlobalsCommon.isLandscape() ? false : true
        self.rhythmHeard = self.questionType == .rhythmVisualClap ? true : false
    }
    
    func examInstructionsDone(status:RequestStatus) {
    }
    
    func getInstruction(mode:QuestionType, grade:Int, examMode:Bool) -> String? {
        var result = ""
        let bullet = "\u{2022}" + " "
        var linefeed = "\n"
        if !UIGlobalsCommon.isLandscape() {
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
            if !SettingsMT.shared.useAcousticKeyboard {
                result += "play the melody."
            }
            else {
                result += "play the melody and the final chords."
            }
            result += "\(linefeed)\(bullet)When you have finished, stop the recording."
            
        default:
            result = ""
        }
        return result.count > 0 ? result : nil
    }
    
    func getStudentTappingAsAScore() -> Score? {
        if let values = self.answer.rhythmValues {
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
        return practiceText
    }
    
    func rhythmIsCorrect() -> Bool {
        guard let tapValues = answer.rhythmValues else {
            return false
        }
        let tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        let fittedScore = score.fitScoreToQuestionScore(userScore:tappedScore,
                                                        onlyRhythm: questionType == .melodyPlay ? false : true,
                                                        tolerancePercent: UIGlobalsMT.shared.rhythmTolerancePercent
                                                        ).0
        if fittedScore.errorCount() == 0 && fittedScore.getAllTimeSlices().count > 0 {
            return true
        }
        return false
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
                    tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.getTempo())
                } else {
                    audioRecorder.startRecording(fileName: contentSection.name)
                }
            }
            return true
        }
        return false
    }
    
    func nextStepText() -> String? {
        var next:String? 
        if questionType == .melodyPlay {
            if contentSection.getExamTakingStatus() == .inExam {
                next = "Submit Your Answer"
            }
            else {
                ///For acoustic piano no point to go to answer mode - so set text ""
                next = SettingsMT.shared.useAcousticKeyboard ? nil : "See The Answer"
            }
        }
        else {
            next = contentSection.getExamTakingStatus() == .inExam ? "Submit" : "Check"
            next! += " Your Answer"
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
                    //metronome.stopTicking() dont delete this line yet Jan 1 2024, let them tap with metronome on if they started it
                    score.barEditor = nil
                    if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                        self.isTapping = true
                        tapRecorder.startRecording(metronomeLeadIn: false, metronomeTempoAtRecordingStart: metronome.getTempo())
                    } else {
                        if SettingsMT.shared.useAcousticKeyboard {
                            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                                audioRecorder.startRecording(fileName: contentSection.name)
                            }
                        }
                        else {
                            answer.sightReadingNotePitches = []
                            answer.sightReadingNoteTimes = []
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
                        let hand = (questionType == .melodyPlay && !SettingsMT.shared.useAcousticKeyboard) ? " Right Hand" : ""
                        Text("Start Recording \(hand)")
                            .defaultButtonStyle(enabled: rhythmHeard || questionType != .intervalAural)
                    }
                }
                .disabled(!(rhythmHeard || questionType != .intervalAural))
            }
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
                    hintButtonView("Remove Rhythm Start", selected: startWasShortended)
                }
                .padding()
                Button(action: {
                    score.createBarEditor(onEdit: scoreEditedNotification)
                    //score.barEditor?.notifyFunction = self.notifyScoreEditedFunction
                    score.barEditor?.reWriteBar(targetBar: score.getBarCount()-1, way: .delete)
                    self.endWasShortended = true
                }) {
                    hintButtonView("Remove Rhythm End", selected: endWasShortended)
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
                            hintButtonView("Put Back Question Rhythm", selected: false)
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
                    //if UIDevice.current.userInterfaceIdiom != .phone {
                        ToolsView(score: score, helpMetronome: helpMetronome())
                    //}
                }

                if questionType == .rhythmVisualClap || questionType == .melodyPlay {
                    //ScoreSpacerView()
                    ScoreView(score: score, widthPadding: false).padding()
                    //ScoreSpacerView()
                }
                
                ///Option for editing the rhythm and restoring the rhythm to the original if the rhythm was edited
                if answerState != .recording {
                    if contentSection.getExamTakingStatus() != .inExam {
                        HStack {
                            if let instruction = self.getInstruction(mode: self.questionType, 
                                                                     grade: contentSection.getGrade(),
                                                                     examMode: contentSection.getExamTakingStatus() == .inExam) {
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
                                    .padding()
                                }
                            }
                            
                            if questionType == .melodyPlay {
                                if answerState != .recording {
                                    CountdownTimerView(size: 50.0, timerColor: .blue, timeLimit: $countDownTimeLimit, startNotification: {}, endNotification: {})
                                        .padding()
                                        .roundedBorderRectangle()
                                        .padding()
                                }
                            }

                            if questionType == .rhythmVisualClap {
                                if score.getBarCount() > 1 {
                                    ///Enable bar manager to edit out bars in the given rhythm
                                    HStack {
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
                                    }
                                    .roundedBorderRectangle()
                                }
                            }
                            //if questionType != .melodyPlay {
                            RhythmToleranceView(contextText: nil)
                            //}

                        }
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

                }
                
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap {
                    if answerState == .recording {
                        TappingView(isRecording: $isTapping, tapRecorder: tapRecorder, onDone: {
                            answerState = .recorded
                            self.isTapping = false
                            ///Record end of playing to calculate the last note's duration
                            answer.rhythmValues = self.tapRecorder.stopRecording(score:score)
                            answer.rhythmTolerancePercent = UIGlobalsMT.shared.rhythmTolerancePercent
                            isTapping = false
                        })
                    }
                }
                
                if questionType == .melodyPlay {
                    if !SettingsMT.shared.useAcousticKeyboard {
                        if answerState == .recording {
                            SightReadingPianoView(answer:answer, score: score)
                        }
                    }
                }
                
                if questionType == .melodyPlay {
                    if answerState == .recording {
                        Button(action: {
                            answerState = .recorded
                            if SettingsMT.shared.useAcousticKeyboard {
                                audioRecorder.stopRecording()
                                answer.recordedData = self.audioRecorder.getRecordedAudio(fileName: contentSection.name)
                            }
                            answer.sightReadingNoteTimes.append(Date())
                        }) {
                            Text("Stop Recording")
                                .defaultButtonStyle()
                        }
                        .padding()
                    }
                }

                //Check answer
                if answerState == .recorded {
                    if let buttonText = nextStepText() {
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
                                Text(buttonText).submitAnswerButtonStyle()
                            }
                            .padding()
                        }
                    }
                }
                
            }
            .font(.system(size: UIDevice.current.userInterfaceIdiom == .phone ? UIFont.systemFontSize : UIFont.systemFontSize * 1.6))
            .sheet(isPresented: $presentInstructions) {
                if let instruction = self.getInstruction(mode: self.questionType, 
                                                         grade: contentSection.getGrade(),
                                                         examMode: contentSection.getExamTakingStatus() == .inExam) {
                    instructionView(instruction: instruction)
                }
            }
            .onAppear() {
                score.clearAllStatus()
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
                metronome.setAllowTempoChange("ClapOrPlayPresentView", allow: true)
                if questionType == .melodyPlay {
                    score.addTriadNotes()
                }
                //self.rhythmTolerancePercent = UIGlobalsMT.shared.rhythmTolerancePercent
                self.originalScore = contentSection.parseData(staffCount: 1, onlyRhythm: true)
            }
            .onDisappear() {
                self.audioRecorder.stopPlaying()
                self.metronome.stopTicking()
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

    @State private var score:Score
    @State var hoveringForHelp = false
    @State var originalScore:Score?
    @State var scoreCurrentBarCount:Int = 0

    private var questionType:QuestionType
    private var answer:Answer
    let questionTempo = 90
    let melodyAnalyser = MelodyAnalyser()
    
    init(contentSection:ContentSection, score:Score, answerState:Binding<AnswerState>, tryNumber:Binding<Int>, answer:Answer, questionType:QuestionType) {
        self.contentSection = contentSection
        self.score = score
        self.questionType = questionType
        self.answerMetronome = Metronome.getMetronomeWithCurrentSettings(ctx:"ClapOrPlayAnswerView")
        self.answer = answer
        _answerState = answerState
        _tryNumber = tryNumber
        answerMetronome.setSpeechEnabled(enabled: self.speechEnabled)
    }
    
    func analyseStudentMelody() {
        if let answer = contentSection.storedAnswer {
            let tappedScore = melodyAnalyser.makeScoreFromTaps(questionScore: score, questionTempo: 60,
                                                               tapPitches: answer.sightReadingNotePitches,
                                                               tapTimes: answer.sightReadingNoteTimes
            )
            tappedScore.label = "Your Melody"
            self.fittedScore = tappedScore
        }
    }
    
    func analyseStudentSubmittal() {
        var tappedScore:Score? = nil
        if questionType == .melodyPlay {
            answer.makeNoteValues()
        }
        guard let tapValues = answer.rhythmValues else {
            return
        }
        tappedScore = tapRecorder.getTappedAsAScore(timeSignatue: score.timeSignature, questionScore: score, tapValues: tapValues)
        guard let tappedScore = tappedScore else {
            return
        }
        if questionType == .melodyPlay {
            tappedScore.label = "Your Melody"
            ///Add note pitches from the piano to the score
            var pitchIndex = 0
            for timeslice in tappedScore.getAllTimeSlices() {
                let notes = timeslice.getTimeSliceNotes(staffNum: 0)
                if notes.count > 0 {
                    notes[0].midiNumber = answer.sightReadingNotePitches[pitchIndex]
                    pitchIndex += 1
                }
            }
        }

        ///Checks -
        ///1) all notes in the question have taps at the same time location
        ///2) no taps are in a location where there is no question note
        ///
        ///If the student got the test correct then ensure that what they saw that they tapped exaclty matches the question.
        ///Otherwise, try to make the studnets tapped score look the same as the question score up until the point of error
        ///(e.g. a long tap might correctly represent either a long note or a short note followed by a rest. So mark the tapped score accordingingly

        let fitted = score.fitScoreToQuestionScore(userScore:tappedScore, 
                                                   onlyRhythm: questionType == .melodyPlay ? false : true,
                                                   tolerancePercent: UIGlobalsMT.shared.rhythmTolerancePercent)
        self.fittedScore = fitted.0
        
        let feedback = fitted.1
        
        if self.fittedScore == nil {
            return
        }
        else {
            ///Some iPads too short in landscape mode
            self.fittedScore!.heightPaddingEnabled = UIGlobalsCommon.isLandscape() ? false : true
        }

        self.answerMetronome.setAllowTempoChange("analyseStudentSubmittal", allow: false)
        self.answerMetronome.setTempo(tempo: self.questionTempo, context: "ClapOrPlayAnswerView")

        if let fittedScore = self.fittedScore {
            if fittedScore.errorCount() == 0 && fittedScore.getAllTimeSlices().count > 0 {
                feedback.correct = true
                feedback.feedbackExplanation = "Good job!"
                if let recordedTempo = tappedScore.tempo {
                    self.answerMetronome.setAllowTempoChange("analyseStudentSubmittal GOOD RHYTHM", allow: true)
                    self.answerMetronome.setTempo(tempo: recordedTempo, context: "ClapOrPlayAnswerView")
                    let questionTempo = Metronome.getMetronomeWithCurrentSettings(ctx: "for clap answer").getTempo()
                    let tolerance = Int(CGFloat(questionTempo) * 0.2)
                    if questionType == .rhythmVisualClap || questionType == .melodyPlay {
                        feedback.feedbackExplanation! +=
                        " Your tempo was \(recordedTempo)."
                    }
                    //rhythmTolerance = UIGlobalsMT.shared.rhythmTolerancePercent
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
            if let rhythmTolerance = answer.rhythmTolerancePercent {
                let tol = RhytmTolerance.getToleranceName(rhythmTolerance)
                if feedback.feedbackExplanation != nil {
                    if feedback.correct == false {
                        feedback.feedbackExplanation! +=  "\n• "
                    }
                    feedback.feedbackExplanation! += " The rhythm tolerance was set at \(tol)."
                }
            }

            self.fittedScore!.setStudentFeedback(studentFeedack: feedback)
        }
    }
    
    func helpMetronome() -> String {
        let lname = questionType == .melodyPlay ? "melody" : "rhythm"
        let practiceText = "You can tap the picture of the metronome to practise along with the tick."
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
                
                if SettingsMT.shared.isContentSectionLicensed(contentSection:contentSection) {
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
                ToolsView(score: score, helpMetronome: helpMetronome())
                ScoreView(score: score, widthPadding: false).padding()

                if let fittedScore = self.fittedScore {
                    ScoreView(score: fittedScore, widthPadding: false).padding()
                }

                HStack {
                    PlayRecordingView(buttonLabel: "Hear The Given \(questionType == .melodyPlay ? "Melody" : "Rhythm")",
                                      //score: getCurrentScore(),
                                      metronome: answerMetronome,
                                      fileName: contentSection.name,
                                      onStart: {return score})

                    if questionType == .melodyPlay && SettingsMT.shared.useAcousticKeyboard {
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
                if questionType == .rhythmVisualClap || questionType == .rhythmEchoClap ||
                    (questionType == .melodyPlay && !SettingsMT.shared.useAcousticKeyboard) {
                    analyseStudentSubmittal()
                    //answerMetronome.setTempo(tempo: questionTempo, context: "AnswerMode::OnAppear")
                }
                else {
                    analyseStudentMelody()
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
                if answerState  != .submittedAnswer {
                    ///ScrollView Forces everthing to top align, not center align. Top of metronome truncated but still operable.
                    ///Without ScrollView various screens can't see all buttons
                    ScrollView {
                        ClapOrPlayPresentView(
                            contentSection: contentSection,
                            score: score,
                            answerState: $answerState,
                            answer: $answer,
                            tryNumber: $tryNumber,
                            questionType: questionType)
                        .frame(width: UIScreen.main.bounds.width)
                    }
                }
                else {
                    if shouldShowAnswer() {
                        ScrollView {
                            ZStack {
                                ClapOrPlayAnswerView(contentSection: contentSection,
                                                     score: score,
                                                     answerState: $answerState,
                                                     tryNumber: $tryNumber,
                                                     answer: answer,
                                                     questionType: questionType)
                                if SettingsMT.shared.useAnimations {
                                    if !contentSection.isExamTypeContentSection() {
                                        if !(self.questionType == .melodyPlay) {
                                            FlyingImageView(answer: answer)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //Spacer() //Force it to align from the top
                }
            }
        }
        //.background(Settings.shared.colorBackground)
        .background(Color(.white))

        .onDisappear {
            let metronome = Metronome.getMetronomeWithCurrentSettings(ctx: "")
            metronome.stopTicking()
            metronome.stopPlayingScore()
        }
    }

}
