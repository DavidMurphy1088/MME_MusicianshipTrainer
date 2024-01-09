import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit
import CommonLibrary

///The view that runs a specifc example type
struct ContentTypeView: View {
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
//            if Settings.shared.companionOn {
//                if contentSection.homeworkIsAssigned {
//                    contentSection.setStoredAnswer(answer: answer.copyAnwser(), ctx: "ContentTypeView DISAPPEAR")
//                    contentSection.saveAnswerToFile(answer: answer.copyAnwser())
//                }
//            }
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
                    TextToSpeech.shared.speakText(contentSection: contentSection, context: context, htmlContent: htmlDocument)
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
            TextToSpeech.shared.stop()
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
        let view = WKWebView()
        view.backgroundColor = UIColor.white
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let cssString = "body { background-color: white !important; }" // Force background color
        let modifiedHTML = "<style>\(cssString)</style>\(htmlDocument)"
        uiView.loadHTMLString(modifiedHTML.trimmingCharacters(in: .whitespaces), baseURL: nil)
        //uiView.loadHTMLString(htmlDocument.trimmingCharacters(in: .whitespaces), baseURL: nil)
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
    @State private var audioInstructionsFileName:String? = nil
    @State var promptForLicense = false
    @State private var parentsData:String?=nil
    //@State private var parentsExists = false
    
    func getInstructions(bypassCache:Bool)  {
        var pathSegments = contentSection.getPathAsArray()
        if pathSegments.count < 1 {
            return
        }
        let filename = "Instructions" //instructionContent.contentSectionData.data[0]
        pathSegments.append(SettingsMT.shared.getAgeGroup())
        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                self.instructions = document
            }
        }
    }
    
    func getTipsTricksData(bypassCache: Bool)  {
        let filename = "Tips_Tricks"
        var pathSegments = contentSection.getPathAsArray()
        pathSegments.append(SettingsMT.shared.getAgeGroup())
        
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
        pathSegments.append(SettingsMT.shared.getAgeGroup())
        self.parentsData = nil
        
        googleAPI.getDocumentByName(pathSegments: pathSegments, name: filename, reportError: false, bypassCache: bypassCache) {status,document in
            if status == .success {
                //self.parentsExists = true
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
                        //.padding()
                        //.background(UIGlobals.colorNavigationBackground)
                        //.background(Color(.secondarySystemBackground))
                    }
                }
            }
            
            HStack {
                if contentSection.getPathAsArray().count == 1 {
                    Spacer()
                    Button(action: {
                        self.promptForLicense = true
                    }) {
                        VStack {
                            VStack {
                                Text("Licenses")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
                                Image(systemName: "applelogo")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.title)
                            }
                        }
                    }
                }
                if tipsAndTricksExists {
                    Spacer()
                    NavigationLink(destination: ContentSectionWebView(htmlDocument: tipsAndTricksData!, contentSection: contentSection)) {
                        VStack {
                            Text("Tips and Tricks")
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
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
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
                                Image(systemName: "video")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.largeTitle)
                            }
                        }
                    }
                    .sheet(isPresented: $isVideoPresented) {
                        let urlStr = "https://storage.googleapis.com/musicianship_trainer/NZMEB/" +
                        contentSection.getPath() + "." + SettingsMT.shared.getAgeGroup() + ".video.mp4"
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
                            let c = contentSection.subSections.count
                            let r = Int.random(in: 0...c)
                            contentSection.setSelected(r)
                        }
                    }) {
                        VStack {
                            VStack {
                                Text("Random Pick")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
                                Image(systemName: "tornado")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.title)
                            }                            
                        }
                    }
                    
                    .disabled(!SettingsMT.shared.isContentSectionLicensed(contentSection: contentSection))
                }
                if let parents = self.parentsData {
                    Spacer()
                    NavigationLink(destination: ContentSectionWebView(htmlDocument: parentsData!, contentSection: contentSection)) {
                        VStack {
                            Text("Parents")
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
                            Image(systemName: "text.bubble")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                    }
                }
                
//                if Settings.shared.companionOn {
//                    if contentSection.getPathAsArray().count == 2 {
//                        Spacer()
//                        Button(action: {
//                        }) {
//                            NavigationLink(destination: SetHomeworkView(contentSection: contentSection)) {
//                                VStack {
//                                    Text("Set Homework")
//                                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
//                                    Image(systemName: "highlighter")
//                                        .foregroundColor(.black)
//                                        .font(.title)
//                                }
//                            }
//                        }
//                    }
//                }
                Spacer()
            }
            .padding()
            if SettingsMT.shared.showReloadHTMLButton {
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
        .roundedBorderRectangle()
        .sheet(isPresented: $promptForLicense) {
            LicenseManagerView(contentSection: contentSection, email: SettingsMT.shared.licenseEmail)
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

struct ContentSectionView: View {
    @ObservedObject var contentSection:ContentSection
    @State private var showNextNavigation: Bool = true
    @State private var endOfSection: Bool = false
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer:Answer = Answer()
    @State var isShowingConfiguration:Bool = false
    @State var showLicenseChange:Bool = false
    @State var emailLicenseIsValidPriorConfig = false
    
    let id = UUID()
    
    init (contentSection:ContentSection) { //, contentSectionView:(any View), parentSelectionIndex:Binding<Int?>) {
        self.contentSection = contentSection
    }
    
//    func log() -> String {
//        print("==== ContentSectionView", contentSection.getPathAsArray())
//        return ""
//    }
    
    var body: some View {
        VStack {
           
            if contentSection.getNavigableChildSections().count > 0 {
                if contentSection.isExamTypeContentSection() {
                    ///Navigating to a specific exam
                    ///No ContentSectionHeaderView in any exam mode content section except the exam start
                    ZStack {
                        VStack {
                            Image("app_background_navigation")
                                .resizable()
                                .scaledToFill() // Scales the image to fill the view
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                .opacity(UIGlobalsMT.shared.backgroundImageOpacity)
                        }

                        VStack {
                            if contentSection.hasExamModeChildren() {
                                ContentSectionHeaderView(contentSection: contentSection)
                                //.border(Color.red)
                                //.padding(.vertical, 0)
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
                    }
                }
                else {
                    ZStack {
                        VStack {
                            Image("app_background_navigation")
                                .resizable()
                                .scaledToFill() // Scales the image to fill the view
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                .opacity(UIGlobalsMT.shared.backgroundImageOpacity)
                        }
                        ScrollViewReader { proxy in
                            ContentSectionHeaderView(contentSection: contentSection)
                                .padding()
                            
                            SectionsNavigationView(contentSection: contentSection)
                                .padding()
                        }
                    }
                }
            }
            else {
                ContentTypeView(contentSection: self.contentSection,
                                answerState: $answerState,
                                answer: $answer)
                .onDisappear() {
//                    if SettingsMT.shared.companionOn {
//                        if contentSection.homeworkIsAssigned {
//                            contentSection.setStoredAnswer(answer: answer.copyAnwser(), ctx: "ContentSectionView DISAPPEAR")
//                            contentSection.saveAnswerToFile(answer: answer.copyAnwser())
//                        }
//                    }
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
//            if contentSection.getPathAsArray().count == 1 {
//                let licenseManager = IAPManager.shared
//            }
        }
        .onDisappear() {
            AudioRecorder.shared.stopPlaying()
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
            let newSettings = SettingsMT(copy: SettingsMT.shared)
            ConfigurationView(isPresented: $isShowingConfiguration,
                              settings: newSettings)
            
        }
        .onChange(of: isShowingConfiguration) { showingConfig in
            if !SettingsMT.shared.licenseEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if showingConfig {
                    self.emailLicenseIsValidPriorConfig = IAPManager.shared.emailIsLicensed(email:SettingsMT.shared.licenseEmail)
                }
                else {
                    if !self.emailLicenseIsValidPriorConfig {
                        if IAPManager.shared.emailIsLicensed(email:SettingsMT.shared.licenseEmail) {
                            DispatchQueue.main.async {
                                showLicenseChange = true
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showLicenseChange) {
            Alert(title: Text("Licensing"), message: Text("Your email \(SettingsMT.shared.licenseEmail) is now licensed"), dismissButton: .default(Text("OK")))
        }

    }
}

struct SectionsNavigationView:View {
    @ObservedObject var contentSection:ContentSection
    @State var homeworkIndex:Int?
    @State var showHomework = false
    
//    func log(cs:ContentSection) -> String {
//        print("🤢 ===================== SectionsNavigationView [", cs.getPath(),
////              //"]  ISCS", cs.isExamTypeContentSection(), "Stored", cs.hasStoredAnswers(),
//////              "child", cs.hasExamModeChildren(),
////              "HOMEWORK", contentSection.homeworkIsAssigned
////        )
//        return ""
//    }
    
    struct HomeworkView: View {
        @ObservedObject var contentSection:ContentSection
        @Environment(\.presentationMode) var presentationMode
        
        func msg(contentSection:ContentSection) -> String {
            var s = ""
            guard let answer = contentSection.storedAnswer else {
                return "This is homework to do"
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
                Text("Homework for week of Monday 27th")
                    .font(.title)
                Image("homework_girl_transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .padding()
                    .padding()

                Text(msg(contentSection:contentSection)).foregroundColor(getColor(contentSection: contentSection)).font(.title)
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
//        print("==== Sections NAVIGATION View", contentSection.getPathAsArray(), contentSection.subSections.count)
//        return ""
//    }
    
    ///Need to be separate View to force the image to change immediately after answer is made
    struct HomeworkStatusIconView:View {
        @ObservedObject var contentSection:ContentSection
        var body: some View {
            HStack {
                Text("Homework:").padding(.vertical)
                if let rowImage = contentSection.getGradeImage() {
                    rowImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40.0)
                }
            }
        }
    }
    
    func isExampleLicensed(contentSection:ContentSection) -> Bool {
        ///Licenses example depending on its example numbers
        if contentSection.getPathAsArray().count < 3 {
            return true
        }
        let parts = contentSection.name.split(separator: " ")
        if parts.count != 2 {
            return true
        }
        guard let exNum = Int(parts[1]) else {
            return true
        }
        if exNum <= 2 {
            return true
        }
        guard let grade = contentSection.parentSearch(testCondition: {section in
                    return section.name.contains("Grade")
        }) else {
            return true
        }
        return SettingsMT.shared.isContentSectionLicensed(contentSection:contentSection)
        //print("  +++ grade", grade.name, lic)
        //return license != nil
    }
    
    ///The list of examples. The navigation link takes the user  to the specific question next
    var body: some View {
        VStack {
            let contentSections = contentSection.getNavigableChildSections()
            //let log = log()
            
            ScrollViewReader { proxy in
                List(Array(contentSections.indices), id: \.self) { index in
                    ///selection: A bound variable that causes the link to present `destination` when `selection` becomes equal to `tag`
                    ///tag: The value of `selection` that causes the link to present `destination`..
                    
                    NavigationLink(destination:
                                    ContentSectionView(contentSection: contentSections[index]),
                                   tag: index,
                                   selection: $contentSection.selectedIndex
                    ) {
                        ZStack {
                            HStack {
                                ZStack {
                                    HStack {
                                        Spacer()
                                        Text(contentSections[index].getTitle())
                                            .font(UIGlobalsCommon.navigationFont)
                                            .padding(.vertical, 8)
                                        Spacer()
                                    }
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
                                        if SettingsMT.shared.companionOn {
                                            //Show correct answer icon for a homework question
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    homeworkIndex = index
                                                    showHomework.toggle()
                                                }) {
                                                    HomeworkStatusIconView(contentSection: contentSections[index])
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                                .sheet(isPresented: $showHomework) {
                                                    HomeworkView(contentSection: contentSections[index])
                                                }
                                                Text("        ").font(.system(size: 18, weight: .regular, design: .monospaced))
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
                    .disabled(!isExampleLicensed(contentSection: contentSections[index]))
                    //.backgroundColor(isExampleLicensed(contentSection: contentSections[index]) ? Color.black : Color.lightGray)
                    ///End of Nav link view
                    //.background(Color.clear)
                    //.padding()
                }
                
                ///End of List
                .listStyle(PlainListStyle()) // Removes default List styling
                .roundedBorderRectangle()
                .padding()
                ///Force list view height to stop it taking whole height of screen
                .frame(height: UIScreen.main.bounds.height * (UIGlobalsCommon.isLandscape() ? 0.45 : 0.45))

                ///This color matches the NavigationView background which cannot be changed.
                ///i.e. any other colour here causes the navigation link rows to have a different background than the background of the navigationView's own background
                .listRowBackground(Color(.clear))

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
            ///End of Scroll View
        }
        ///End of VStack
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
    
    func examImage() -> some View {
        VStack {
            Image("judge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width / 3.0)
        }
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
                    examImage()
                    Text("Preparing the exam ...").defaultButtonStyle()
                }
                if examState == .narrated {
                    VStack {
                        examImage()
                        HStack {
                            RhythmToleranceView(contextText: "Please set the rhythm tolerance you'd like to use for the exam.")
                                .frame(width: UIScreen.main.bounds.width / 2.0)
                        }
                        Button(action: {
                            self.examState = .examStarted
                            AudioRecorder.shared.stopPlaying()
                        }) {
                            VStack {
                                //Text(examInstructionsStatus).padding().font(.title)
                                Text("The exam has \(contentSection.getQuestionCount()) questions").defaultTextStyle().padding()
                                Text("Start the Exam").defaultButtonStyle().padding()
                            }
                            .padding()
                            .roundedBorderRectangle().padding()
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
                            examImage()
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
                            VStack {
                                examImage()
                                Text("Submit Your Exam").defaultButtonStyle()
                            }
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

