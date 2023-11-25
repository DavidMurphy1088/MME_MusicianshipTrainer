import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit
import CommonLibrary

///The view that runs a specifc example or test
struct ContentTypeView: View {
    //let contentSection:ContentSection
    @ObservedObject var contentSection:ContentSection
    @Binding var answerState:AnswerState
    @Binding var answer:Answer

    func isNavigationHidden() -> Bool {
        ///No exit navigation in exam mode
        if let parent = contentSection.parent {
            if parent.isExamTypeContentSection() && contentSection.storedAnswer == nil {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    var body: some View {
        VStack {
            let type = contentSection.type
           
            if type == "Type_1" {
                IntervalView(
                    questionType: QuestionType.intervalVisual,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_2" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmVisualClap,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_3" {
                ClapOrPlayView (
                    questionType: QuestionType.melodyPlay,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_4" {
                IntervalView(
                    questionType: QuestionType.intervalAural,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
            if type == "Type_5" {
                ClapOrPlayView (
                    questionType: QuestionType.rhythmEchoClap,
                    contentSection: contentSection,
                    answerState: $answerState,
                    answer: $answer
                )
            }
        }
        .navigationBarHidden(isNavigationHidden())
        .onDisappear() {
            AudioRecorder.shared.stopPlaying()
            if Settings.shared.companionOn {
                if contentSection.homeworkIsAssigned {
                    contentSection.setStoredAnswer(answer: answer.copyAnwser(), ctx: "ContentTypeView DISAPPEAR")
                    contentSection.saveAnswerToFile(answer: answer.copyAnwser())
                }
            }
        }
    }
}

struct NarrationView : View {
    let contentSection:ContentSection
    let htmlDocument:String
    let context:String
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    TTS.shared.speakText(contentSection: contentSection, context: context, htmlContent: htmlDocument)
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                        .padding()
                }
                Spacer()
            }
            Spacer()
        }
        .onDisappear() {
            TTS.shared.stop()
        }
    }
}

struct ContentSectionWebViewUI: UIViewRepresentable {
    var htmlDocument:String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlDocument, baseURL: nil)
    }
}

struct ContentSectionWebView: View {
    let htmlDocument:String
    let contentSection: ContentSection
    var body: some View {
        VStack {
            ZStack {
                ContentSectionWebViewUI(htmlDocument: htmlDocument).border(Color.black, width: 1).padding()
                NarrationView(contentSection: contentSection, htmlDocument: htmlDocument, context: "ContentSectionTipsView")
            }
        }
    }
}
   
struct ContentSectionInstructionsView: UIViewRepresentable {
    var htmlDocument:String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlDocument.trimmingCharacters(in: .whitespaces), baseURL: nil)
    }
}

struct ContentSectionHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    var contentSection:ContentSection

    let googleAPI = GoogleAPI.shared
    @State private var isVideoPresented = false
    @State private var instructions:String? = nil
    @State private var tipsAndTricksExists = false
    @State private var tipsAndTricksData:String?=nil
    @State private var parentsExists = false
    @State private var parentsData:String?=nil
    @State private var audioInstructionsFileName:String? = nil
    
    func getInstructions(bypassCache:Bool)  {
        var pathSegments = contentSection.getPathAsArray()
        if pathSegments.count < 1 {
            return
        }
        let filename = "Instructions" //instructionContent.contentSectionData.data[0]
        pathSegments.append(Settings.shared.getAgeGroup())
        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.instructions = document
            }
        }
    }
    
    func getTipsTricksData(bypassCache: Bool)  {
        let filename = "Tips_Tricks"
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(Settings.shared.getAgeGroup())

        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.tipsAndTricksExists = true
                self.tipsAndTricksData = document
            }
        }
    }
    
    func getParentsData(bypassCache: Bool)  {
        let filename = "Parents"
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(Settings.shared.getAgeGroup())

        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.parentsExists = true
                self.parentsData = document
            }
        }
    }

    func getAudio()  {
        let audioContent = contentSection.getChildSectionByType(type: "Audio")
        if let audioContent = audioContent {
            if audioContent.contentSectionData.data.count > 0 {
                audioInstructionsFileName = audioContent.contentSectionData.data[0]
            }
        }
    }

    func getParagraphCount(html:String) -> Int {
        var p = html.components(separatedBy: "<p>").count
        if p > 4 {
            p = 4
        }
        return p
    }
    
    func log(contentSection: ContentSection, index:Int?) -> Bool {
        //print(contentSection.getPathTitle(), "index", index)
        return true
    }
    
    var body: some View {
        VStack {
            VStack {
                if let audioInstructionsFileName = audioInstructionsFileName {
                    Button(action: {
                        AudioRecorder.shared.playAudioFromCloudURL(urlString: audioInstructionsFileName)
                    }) {
                        Text("Aural Instructions").defaultButtonStyle()
                    }
                    .padding()
                }
                
                if let instructions = self.instructions {
                    HStack {
                        ZStack {
                            ContentSectionInstructionsView(htmlDocument: instructions)
                            NarrationView(contentSection: contentSection, htmlDocument: instructions, context: "Instructions")
                        }
                        .frame(height: CGFloat((getParagraphCount(html: instructions)))/12.0 * UIScreen.main.bounds.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIGlobals.cornerRadius).stroke(Color(UIGlobals.borderColor), lineWidth: UIGlobals.borderLineWidth)
                        )
                        .padding()
                        //.background(UIGlobals.colorNavigationBackground)
                        .background(Color(.secondarySystemBackground))
                    }
                }
            }
            
            HStack {
                if tipsAndTricksExists {
                    Spacer()
                    NavigationLink(destination: ContentSectionWebView(htmlDocument: tipsAndTricksData!, contentSection: contentSection)) {
                        VStack {
                            Text("Tips and Tricks")
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.largeTitle)
                        }
                    }
                    Spacer()
                    Button(action: {
                        isVideoPresented.toggle()
                    }) {
                        VStack {
                            VStack {
                                Text("Video")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                                Image(systemName: "video")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.largeTitle)
                            }
                        }
                    }
                    .sheet(isPresented: $isVideoPresented) {
                        let urlStr = "https://storage.googleapis.com/musicianship_trainer/NZMEB/" +
                        contentSection.getPath() + "." + Settings.shared.getAgeGroup() + ".video.mp4"
                        //https://storage.googleapis.com/musicianship_trainer/NZMEB/Grade%201.PracticeMode.Sight%20Reading.11Plus.video.mp4
                        //Grade 1.PracticeMode.Sight Reading.11Plus.video.mp4
                        let allowedCharacterSet = CharacterSet.urlQueryAllowed
                        if let encodedString = urlStr.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                            if let url = URL(string: encodedString) {
                                GeometryReader { geo in
                                    VStack {
                                        VideoPlayer(player: AVPlayer(url: url))
                                    }
                                    .frame(height: geo.size.height)
                                }
                            }
                        }
                    }
                }
                
                if contentSection.getPathAsArray().count > 2 {
                    Spacer()
                    Button(action: {
                        DispatchQueue.main.async {
                            //contentSectionView.randomPick()
                            let c = contentSection.subSections.count
                            let r = Int.random(in: 0...c)
                            contentSection.setSelected(r)
                        }
                    }) {
                        VStack {
                            VStack {
                                Text("Random Pick")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                                Image(systemName: "tornado")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.title)
                            }
                        }
                    }
                }
                if Settings.shared.companionOn {
                    if contentSection.getPathAsArray().count == 2 {
                        Spacer()
                        Button(action: {
                        }) {
                            NavigationLink(destination: SetHomeworkView(contentSection: contentSection)) {
                                VStack {
                                    Text("Set Homework")
                                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                                    Image(systemName: "highlighter")
                                        .foregroundColor(.black)
                                        .font(.title)
                                }
                            }
                        }
                    }
                }
                
                if parentsExists {
                    Spacer()
                    NavigationLink(destination: ContentSectionWebView(htmlDocument: parentsData!, contentSection: contentSection)) {
                        VStack {
                            Text("Parents")
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobals.navigationFont)
                            Image(systemName: "text.bubble")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                    }
                }
                Spacer()
            }
            if Settings.shared.showReloadHTMLButton {
                Button(action: {
                    DispatchQueue.main.async {
                        self.getInstructions(bypassCache: true)
                        self.getTipsTricksData(bypassCache: true)
                        self.getParentsData(bypassCache: true)
                    }
                }) {
                    VStack {
                        Text("")
                        Text("ReloadHTML")
                            .font(.title3)
                            .padding(0)
                    }
                    .padding(0)
                }
            }
            
        }
        .onAppear() {
            getAudio()
            getInstructions(bypassCache: false)
            getTipsTricksData(bypassCache: false)
            getParentsData(bypassCache: false)
        }
        .onDisappear() {
            AudioRecorder.shared.stopPlaying()
        }
    }
}

struct SectionsNavigationView:View {
    @ObservedObject var contentSection:ContentSection
    @State var homeworkIndex:Int?
    @State var showHomework = false
    
    func log(cs:ContentSection) -> String {
//        print("🤢 ===================== SectionsNavigationView [", cs.getPath(),
//              //"]  ISCS", cs.isExamTypeContentSection(), "Stored", cs.hasStoredAnswers(),
////              "child", cs.hasExamModeChildren(),
//              "HOMEWORK", contentSection.homeworkIsAssigned
//        )
        return ""
    }
    
    struct HomeworkView: View {
        @ObservedObject var contentSection:ContentSection
        @Environment(\.presentationMode) var presentationMode
        //@State var setHomework = false
        
        func msg(contentSection:ContentSection) -> String {
            var s = ""
            guard let answer = contentSection.storedAnswer else {
                return "This is homework to do."
            }
            if answer.correct {
                s = "Homework done - Good Job!"
            }
            else {
                s = "Homework was done but it wasn't correct. You need to retry it."
            }

            return s
        }
        
        func getColor(contentSection:ContentSection) -> Color {
            guard let answer = contentSection.storedAnswer else {
                return Color.orange
            }

            if answer.correct {
                return Color.green
            }
            else {
                return Color.red
            }
        }
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Homework for week of Monday 6th")
                    .font(.title)
                Image("homework_girl_transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .padding()
                    .padding()

                Text(msg(contentSection:contentSection)).foregroundColor(getColor(contentSection: contentSection)).font(.title3)
                Text("")
                Button("Dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
        }
    }
    
    func homeworkImage(contentSection:ContentSection) -> some View {
        var color = Color.black
        if let answer = contentSection.storedAnswer {
            if answer.correct {
                color = Color.green
            }
            else {
                color = Color.red
            }
        }
        else {
            color = Color.orange
        }

        let im = Image("hw")
            .resizable()
            .scaledToFit()
            .frame(width: 30)
            .foregroundColor(color)
            .overlay(Circle().stroke(color, lineWidth: 2)) // Stroke around a circular image
        return im
    }
    
//    func log() -> String {
//        print("=========>>>>>>>>>>>>>>>>>>>SectionsNavigationView", contentSection.homeworkIsAssigned, contentSection.getPath())
//        return ""
//    }
    
    ///Need to be separate View to force the image to change immediately after answer is made
    struct HomeworkStatusIconView:View {
        @ObservedObject var contentSection:ContentSection
        var body: some View {
            VStack {
                //Text("\(contentSection.storedAnswer == nil ? 0 : 1)")
                if let rowImage = contentSection.getGradeImage() {
                    rowImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40.0)
                }
            }
        }
    }
    
    ///The list of examples. The navigation link takes the user  to the specific question next
    var body: some View {
        VStack {
            let contentSections = contentSection.getNavigableChildSections()
            
            ScrollViewReader { proxy in
                List(Array(contentSections.indices), id: \.self) { index in
                    ///selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`
                    ///tag: The value of `selection` that causes the link to present `destination`..
                    
                    NavigationLink(destination:
                                    ContentSectionView(contentSection: contentSections[index]),
                                   tag: index,
                                   selection: $contentSection.selectedIndex
                                   //selection: $selectedIndex
                                   //selection: $navigationManager.selectedIndex
                    ) {
                        //let log = log(cs:contentSections[index])
                        ZStack {
                            HStack {
                                ZStack {
                                    HStack {
                                        Spacer()
                                        Text(contentSections[index].getTitle())
                                            .font(UIGlobals.navigationFont)
                                            .padding(.vertical, 8)
                                        Spacer()
                                    }
                                    //let homeworkStatus = log()
                                    if !contentSections[index].homeworkIsAssigned {
                                        //Show correct answer icon for an exam question
                                        if let rowImage = contentSections[index].getGradeImage() {
                                            HStack {
                                                Spacer()
                                                rowImage
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 40.0)
                                                Text("    ")
                                            }
                                        }
                                    }
                                    else {
                                        if Settings.shared.companionOn {
                                            //Show correct answer icon for a homework question
                                            HStack {
                                                Spacer()
                                                Text("                         ").font(.system(size: 18, weight: .regular, design: .monospaced))
                                                Button(action: {
                                                    homeworkIndex = index
                                                    showHomework.toggle()
                                                }) {
                                                    HomeworkStatusIconView(contentSection: contentSections[index])
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                                .sheet(isPresented: $showHomework) {
                                                    //if let index = homeworkIndex {
                                                        HomeworkView(contentSection: contentSections[index])
                                                    //}
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            ///Required to force SwiftUI's horz line beween Nav links to run full width when text is centered
                            HStack {
                                Text("")
                                Spacer()
                            }
                            
                        }
                    }
                }
                ///This color matches the NavigationView background which cannot be changed.
                ///i.e. any other colour here causes the navigation link rows to have a different background than the background of the navigationView's own background
                .listRowBackground(Color(.secondarySystemBackground))
                
                ///If the random row does not require the ScrollViewReader to scroll then the view for that random row is made visible
                ///If the random row does require the ScrollViewReader to scroll then it scrolls, goes into the new child view briefly but then exits back to the parent view
                .onChange(of: contentSection.selectedIndex) { newIndex in
                    if let newIndex = newIndex {
                        proxy.scrollTo(newIndex)
                    }
                }
                .onChange(of: contentSection.postitionToIndex) { newIndex in
                    if let newIndex = newIndex {
                        withAnimation(.linear(duration: 0.5)) {
                            proxy.scrollTo(newIndex)
                        }
                    }
                }
                .onDisappear() {
                    AudioRecorder.shared.stopPlaying()
                }
            }
        }
    }
}

struct ExamView: View {
    @Environment(\.presentationMode) var presentationMode
    let contentSection:ContentSection
    @State var sectionIndex = 0
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer = Answer()
    @State private var showingConfirm = false
    @State private var examState:ExamState = .notStartedLoad
    
    enum ExamState {
        case notStartedLoad
        case loading
        case failedToLoad
        case loadedAndNarrating
        case narrated
        case examStarted
    }
    
    init(contentSection:ContentSection) {
        self.contentSection = contentSection
    }
    
    func showAnswer() -> Int {
        return answer.correct ? 1 : 0
    }
    
    func testFunc() {
        
    }
    
    var body: some View {
        VStack {
            if examState != .examStarted {
                Spacer()
                if examState == .notStartedLoad || examState == .loading  {
                    Text("Exam narration is loading ...").defaultButtonStyle()
                }
                if examState == .failedToLoad {
                    Text("Exam failed to Load").defaultButtonStyle()
                }
                if examState == .loadedAndNarrating {
                    Text("Preparing the exam ...").defaultButtonStyle()
                }
                if examState == .narrated {
                    Button(action: {
                        self.examState = .examStarted
                        AudioRecorder.shared.stopPlaying()
                    }) {
                        VStack {
                            //Text(examInstructionsStatus).padding().font(.title)
                            Text("The exam has \(contentSection.getQuestionCount()) questions").defaultTextStyle().padding()
                            Text("Start the Exam").defaultButtonStyle().padding()
                        }
                    }
                }
                Spacer()
            }
            
            if examState == .examStarted {
                let contentSections = contentSection.getNavigableChildSections()
                if self.answerState == .submittedAnswer {
                    Spacer()
                    if sectionIndex < contentSections.count - 1 {
                        VStack {
                            Spacer()
                            Text("Completed question \(sectionIndex+1) of \(contentSections.count)").defaultTextStyle().padding()
                            Button(action: {
                                contentSections[sectionIndex].setStoredAnswer(answer: answer.copyAnwser(), ctx: "")
                                contentSections[sectionIndex].saveAnswerToFile(answer: answer.copyAnwser())
                                answerState = .notEverAnswered
                                sectionIndex += 1
                            }) {
                                VStack {
                                    Text("Next Exam Question").defaultButtonStyle()
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingConfirm = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Exit Exam").defaultButtonStyle().padding()
                                }
                            }
                            .alert(isPresented: $showingConfirm) {
                                Alert(title: Text("Are you sure?"),
                                      message: Text("You cannot restart an exam you exit from"),
                                      primaryButton: .destructive(Text("Yes, I'm sure")) {
                                    for s in contentSections {
                                        let answer = Answer()
                                        s.setStoredAnswer(answer: answer, ctx: "")
                                        s.saveAnswerToFile(answer: answer)
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }, secondaryButton: .cancel())
                            }
                            .padding()
                        }
                    }
                    else {
                        Spacer()
                        Button(action: {
                            contentSections[sectionIndex].storedAnswer = answer.copyAnwser()
                            contentSections[sectionIndex].saveAnswerToFile(answer: answer.copyAnwser())
                            //Force the parent view to refresh the test lines status
                            contentSection.questionStatus.setStatus(1)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Submit Your Exam").defaultButtonStyle()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                else {
                    ContentTypeView(contentSection: contentSections[sectionIndex],
                                    answerState: $answerState,
                                    answer: $answer)
                }
            }
        }
        //.navigationBarHidden(isNavigationHidden())
        .navigationBarHidden(examState == .examStarted)
        .onAppear() {
            self.sectionIndex = 0
            self.examState = .loading
            contentSection.playExamInstructions(withDelay:true,
                onLoaded: {status in
                    if status == .success {
                        self.examState = .loadedAndNarrating
                    }
                    else {
                        self.examState = .failedToLoad
                    }
                },
                onNarrated: {
                    if self.examState == .loadedAndNarrating {
                        self.examState = .narrated
                    }
                })
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                ///5Nov2023 Added after much research into why the audio player can be given data to play but never plays it
                ///and never throws an error. And therefore never notifies that the audio is narrated
                if self.examState == .loadedAndNarrating {
                    self.examState = .narrated
                }
            }
        }
        .onDisappear() {
            AudioRecorder.shared.stopPlaying()
        }
    }
}

struct ContentSectionView: View {
    @ObservedObject var contentSection:ContentSection
    //@ObservedObject var storedAnswer:Answer
    @State private var showNextNavigation: Bool = true
    @State private var endOfSection: Bool = false
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer:Answer = Answer() //, questionMode: .practice)
    @State var isShowingConfiguration:Bool = false

    let id = UUID()
    
    init (contentSection:ContentSection) { //, contentSectionView:(any View), parentSelectionIndex:Binding<Int?>) {
        self.contentSection = contentSection
    }
    
    var body: some View {
        VStack {
            if contentSection.getNavigableChildSections().count > 0 {
                if contentSection.isExamTypeContentSection() {
                    //No ContentSectionHeaderView in any exam mode content section except the exam start
                    if contentSection.hasExamModeChildren() {
                        ContentSectionHeaderView(contentSection: contentSection)
                            //.border(Color.red)
                            .padding(.vertical, 0)
                        SectionsNavigationView(contentSection: contentSection)
                    }
                    else {
                        if contentSection.hasStoredAnswers() {
                            //Exam was taken
                            SectionsNavigationView(contentSection: contentSection)
                        }
                        else {
                            GeometryReader { geo in
                                ExamView(contentSection: contentSection)
                                    .frame(width: geo.size.width)
                            }
                        }
                    }
                }
                else {
                    ScrollViewReader { proxy in
                        ContentSectionHeaderView(contentSection: contentSection)
                            //.border(Color.red)
                            .padding(.vertical, 0)
                    
                        SectionsNavigationView(contentSection: contentSection)
                        //.border(Color.blue)
                            .padding(.vertical, 0)
                    }
                }
            }
            else {
                ContentTypeView(contentSection: self.contentSection,
                                answerState: $answerState,
                                answer: $answer)
                .onDisappear() {
                    if Settings.shared.companionOn {
                        if contentSection.homeworkIsAssigned {
                            contentSection.setStoredAnswer(answer: answer.copyAnwser(), ctx: "ContentSectionView DISAPPEAR")
                            contentSection.saveAnswerToFile(answer: answer.copyAnwser())
                        }
                    }
                }

            }
        }
        //.background(UIGlobals.colorNavigationBackground)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            if contentSection.storedAnswer != nil {
                self.answerState = .submittedAnswer
                self.answer = contentSection.storedAnswer!
            }
        }
        .onDisappear() {
            AudioRecorder.shared.stopPlaying()
            if Settings.shared.companionOn {
//                if [.doneCorrect, .doneError].contains(contentSection.getHomework()) {
//                    contentSection.setStoredAnswer(answer: answer.copyAnwser())
//                    contentSection.saveAnswerToFile(answer: answer.copyAnwser())
//                }
            }
        }
        .navigationBarTitle(contentSection.getTitle(), displayMode: .inline)//.font(.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingConfiguration = true
                }) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.blue)
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .largeTitle)
                }
            }
        }
        .sheet(isPresented: $isShowingConfiguration) {
            let newSettings = Settings(copy: Settings.shared)
            ConfigurationView(isPresented: $isShowingConfiguration,
                              settings: newSettings)
        }
    }
}

