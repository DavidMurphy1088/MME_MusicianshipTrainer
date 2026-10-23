import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit
import CommonLibrary
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        // Here you could update the controller if needed.
    }
}

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
   
//struct ContentSectionInstructionsView: UIViewRepresentable {
//    var htmlDocument:String
//
//    func makeUIView(context: Context) -> WKWebView {
//        let view = WKWebView()
//        //view.backgroundColor = UIColor.white
//        return view
//    }
//    
//    func updateUIView(_ uiView: WKWebView, context: Context) {
//        //let cssString = "body { background-color: white !important; }" // Force background color
//        //let modifiedHTML = "<style>\(cssString)</style>\(htmlDocument)"
//        //uiView.loadHTMLString(modifiedHTML.trimmingCharacters(in: .whitespaces), baseURL: nil)
//        uiView.loadHTMLString(htmlDocument.trimmingCharacters(in: .whitespaces), baseURL: nil)
//    }
//}

struct InstructionsView: View {
    var contentSection:ContentSection
    let audioInstructionsFileName:String?
    let instructions:String?

    var body: some View {
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
                        //ContentSectionInstructionsView(htmlDocument: instructions)
                        ContentSectionWebView(htmlDocument: instructions, contentSection: contentSection)
                        NarrationView(contentSection: contentSection, htmlDocument: instructions, context: "Instructions")
                    }
                }
            }
        }
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
            else {
                //Logger.logger.reportError(contentSection, "getTipsTricksData \(contentSection.getPathTitle()) file:\(filename) Segments:\(pathSegments)")
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
    
    func getInstructionsName(contentSection: ContentSection) -> String {
        let len = contentSection.getPathAsArray().count
        if len == 1 {
            return "Musicianship Overview"
        }
        if len == 2 {
            if contentSection.getPathAsArray()[1].contains("Exam"){
                return "Exam Instructions"
            }
            else {
                return "Practice Mode Overview"
            }
        }
        if len == 3{
            return "Test Instruction"
        }
        return ""
    }
    
    var body: some View {
        VStack {
            //InstructionsView(contentSection: contentSection, audioInstructionsFileName: self.audioInstructionsFileName, instructions: self.instructions)
            
            HStack {
                if contentSection.getPathAsArray().count == 1 {
                    Spacer()
                    Button(action: {
                        self.promptForLicense = true
                    }) {
                        VStack {
                            VStack {
                                //Text("Licences")
                                Text("Subscriptions")
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
                                Image(systemName: "applelogo")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.title)
                            }
                        }
                    }
                }
                Spacer()
                NavigationLink(destination: InstructionsView(contentSection: contentSection,
                                                             audioInstructionsFileName: self.audioInstructionsFileName,
                                                             instructions: self.instructions)) {
                    VStack {
                        Text(getInstructionsName(contentSection: contentSection))
                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : UIGlobalsCommon.navigationFont)
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.largeTitle)
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
                        let urlStr = "https://storage.googleapis.com/musicianship_trainer/NZMEB/" +
                        contentSection.getPath() + "." + SettingsMT.shared.getAgeGroup() + ".video.mp4"
                        let allowedCharacterSet = CharacterSet.urlQueryAllowed
                        if let encodedString = urlStr.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                            if let url = URL(string: encodedString) {
                                //Run Safari externally
                                //UIApplication.shared.open(url)
                                //isVideoPresented = true
                                //let safariViewController = SFSafariViewController(url: url)
                                //SafariView(url: url)
                                if let window = UIApplication.shared.windows.first {
                                    let vc = UIHostingController(rootView: SafariView(url: url))
                                    vc.modalPresentationStyle = .fullScreen
                                    window.rootViewController?.present(vc, animated: true, completion: nil)
                                }

                            }
                        }
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
                    ///Use external Safari broswer- the in-app browser has no sound sometimes ...
//                    .sheet(isPresented: $isVideoPresented) {
//                        let urlStr = "https://storage.googleapis.com/musicianship_trainer/NZMEB/" +
//                        contentSection.getPath() + "." + SettingsMT.shared.getAgeGroup() + ".video.mp4"
//                        let allowedCharacterSet = CharacterSet.urlQueryAllowed
//                        if let encodedString = urlStr.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
//                            if let url = URL(string: encodedString) {
//                                GeometryReader { geo in
//                                    VStack {
//                                        VideoPlayer(player: AVPlayer(url: url))
//                                    }
//                                    .frame(height: geo.size.height)
//                                    .onAppear() {
//                                        //AudioManager.shared.pause("VideoPlayer .OnAppear", pause: true)
//                                    }
//                                    .onDisappear() {
//                                        //AudioManager.shared.pause("VideoPlayer .OnDisappear", pause: false)
//                                    }
//                                }
//                            }
//                        }
//                    }
                }
                
                if contentSection.getPathAsArray().count > 2 {
                    if SettingsMT.shared.isLicensed() {
                        Spacer()
                        Button(action: {
                            DispatchQueue.main.async {
                                ///pickIndex fixes the old 0...c range (could pick one past the end). Dice roll is decorative only.
                                if let r = DiceShuffle.pickIndex(count: contentSection.subSections.count, avoiding: contentSection.selectedIndex) {
                                    DiceShuffle.shared.roll()
                                    contentSection.setSelected(r)
                                }
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
                    }
                }
                if self.parentsData != nil {
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
            LicenseManagerView(contentSection: contentSection, email: SettingsMT.shared.configuredLicenceEmail)
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
                                .frame(width: UIGlobalsCommon.screenBounds.width, height: UIGlobalsCommon.screenBounds.height)
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
                                .frame(width: UIGlobalsCommon.screenBounds.width, height: UIGlobalsCommon.screenBounds.height)
                                .opacity(UIGlobalsMT.shared.backgroundImageOpacity)
                        }
                        //ScrollViewReader { proxy in
                        VStack {
                            ContentSectionHeaderView(contentSection: contentSection)
                                .padding()
                                //.frame(height: 0.1 * UIGlobalsCommon.screenBounds.height)
                            SectionsNavigationView(contentSection: contentSection)
                                .padding()
                        }
                        //}
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
            ScrollView {
                ConfigurationView(isPresented: $isShowingConfiguration,
                                  settings: newSettings)
            }
            
        }
        .onChange(of: isShowingConfiguration) { showingConfig in
            if !SettingsMT.shared.configuredLicenceEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if showingConfig {
                    self.emailLicenseIsValidPriorConfig = LicenceManager.shared.emailIsLicensed(email:SettingsMT.shared.configuredLicenceEmail)
                }
                else {
                    if !self.emailLicenseIsValidPriorConfig {
                        if LicenceManager.shared.emailIsLicensed(email:SettingsMT.shared.configuredLicenceEmail) {
                            DispatchQueue.main.async {
                                showLicenseChange = true
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showLicenseChange) {
            Alert(title: Text("Licensing"), message: Text("Your email \(SettingsMT.shared.configuredLicenceEmail) \nis now licensed"), dismissButton: .default(Text("OK")))
        }
    }
}

struct SectionsNavigationView:View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var contentSection:ContentSection
    @ObservedObject var licenceManager = LicenceManager.shared
    @State var homeworkIndex:Int?
    @State var showHomework = false
    @State var licenseInfoPresented = false
    ///Height of one navigation row's content, measured on screen. Used to size the exam review list.
    @State private var measuredRowHeight:CGFloat = 0

//    struct HomeworkView: View {
//        @ObservedObject var contentSection:ContentSection
//        @Environment(\.presentationMode) var presentationMode
//
//        func msg(contentSection:ContentSection) -> String {
//            var s = ""
//            guard let answer = contentSection.storedAnswer else {
//                return "This is homework to do"
//            }
//            if answer.correct {
//                s = "Homework done - Good Job!"
//            }
//            else {
//                s = "Homework was done but it wasn't correct. You need to retry it."
//            }
//
//            return s
//        }
//        
//        func getColor(contentSection:ContentSection) -> Color {
//            guard let answer = contentSection.storedAnswer else {
//                return Color.orange
//            }
//
//            if answer.correct {
//                return Color.green
//            }
//            else {
//                return Color.red
//            }
//        }
//        
//        var body: some View {
//            VStack(spacing: 20) {
//                Text("Homework for week of Monday 27th")
//                    .font(.title)
//                Image("homework_girl_transparent")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 180)
//                    .padding()
//                    .padding()
//
//                Text(msg(contentSection:contentSection)).foregroundColor(getColor(contentSection: contentSection)).font(.title)
//                Text("")
//                Button("Dismiss") {
//                    presentationMode.wrappedValue.dismiss()
//                }
//            }
//            .padding()
//        }
//    }
    
//    func homeworkImage(contentSection:ContentSection) -> some View {
//        var color = Color.black
//        if let answer = contentSection.storedAnswer {
//            if answer.correct {
//                color = Color.green
//            }
//            else {
//                color = Color.red
//            }
//        }
//        else {
//            color = Color.orange
//        }
//
//        let im = Image("hw")
//            .resizable()
//            .scaledToFit()
//            .frame(width: 30)
//            .foregroundColor(color)
//            .overlay(Circle().stroke(color, lineWidth: 2)) // Stroke around a circular image
//        return im
//    }
    
//    func log() -> String {
//        print("==== Sections NAVIGATION View", contentSection.getPathAsArray(), contentSection.subSections.count)
//        return ""
//    }
    
    ///Need to be separate View to force the image to change immediately after answer is made
//    struct HomeworkStatusIconView:View {
//        @ObservedObject var contentSection:ContentSection
//        var body: some View {
//            HStack {
//                Text("Homework:").padding(.vertical)
//                if let rowImage = contentSection.getGradeImage() {
//                    rowImage
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 40.0)
//                }
//            }
//        }
//    }
    
    func getScore(contentSection: ContentSection) -> Int {
        var score = 0
        for s in contentSection.getNavigableChildSections() {
            if let answer = s.storedAnswer {
                if answer.wasCancelled {
                    return -1
                }
                if answer.correct {
                    score += 1
                }
            }
        }
        return score
    }
    
    func getGradeImage(contentSection: ContentSection) -> Image? {
        var name = ""
        if contentSection.isExamTypeContentSection() {
            //test section group header
            if !contentSection.hasStoredAnswers() {
                return nil
            }
            else {
                let score = getScore(contentSection: contentSection)
                if score == contentSection.getNavigableChildSections().count {
                    name = "checkmark_ok" //grade_a"
                }
                else {
                    if score < 0 {
                        name = "delete_icon" //cancelled
                    }
                    else {
                        name = "checkmark_ok" //grade_b"
                    }
                }
            }
        }
        else {
            //individual tests
            if !contentSection.homeworkIsAssigned {
                return nil
            }
            else {
                if let answer = contentSection.storedAnswer {
                    if answer.correct {
                        name = "grade_a"
                    }
                    else {
                        name = "grade_b"
                    }
                }
                else {
                    name = "todo_transparent"
                }
            }
        }
        var image:Image
        image = Image(name)
        return image
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
        if exNum <= 1 {
            return true
        }
        guard let grade = contentSection.parentSearch(testCondition: {section in
                    return section.name.contains("Grade")
        }) else {
            return true
        }
        return SettingsMT.shared.isLicensed()
    }
    
    ///True when this row is a question inside an exam that has already been answered (exam review mode)
    func isAnsweredExamQuestion(contentSection:ContentSection) -> Bool {
        guard let parent = contentSection.parent, parent.isExamTypeContentSection() else {
            return false
        }
        guard let answer = contentSection.storedAnswer else {
            return false
        }
        return !answer.wasCancelled
    }

    ///Whether this answered question was marked right or wrong.
    ///Type_3 (sight reading) is only marked when played on the on-screen keyboard; acoustic piano recordings
    ///(and sight reading answers saved before marking was added) show "Not Graded" instead of a tick or cross.
    func isMarkedQuestionType(contentSection:ContentSection) -> Bool {
        if contentSection.type == "Type_3" {
            return contentSection.storedAnswer?.sightReadingGraded == true
        }
        return ["Type_1", "Type_2", "Type_4", "Type_5"].contains(contentSection.type)
    }

    ///Size of the tick/cross. One fixed size per device so all marks line up in the same column.
    let examMarkSize:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 34 : 26

    ///Green tick or red cross (or "Not Graded") shown at the right of each answered exam question
    @ViewBuilder
    func examQuestionMark(contentSection:ContentSection) -> some View {
        if let answer = contentSection.storedAnswer, isMarkedQuestionType(contentSection: contentSection) {
            Image(systemName: answer.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(answer.correct ? .green : .red)
                .frame(width: examMarkSize, height: examMarkSize)
                .accessibilityLabel(answer.correct ? "Correct" : "Incorrect")
        }
        else {
            ///Ungraded question types (sight reading): "Not Graded" centred on the same vertical line as the ticks and crosses.
            ///The text sits in an overlay on a mark-sized frame so the column position is identical to the tick/cross rows.
            Color.clear
                .frame(width: examMarkSize, height: examMarkSize)
                .overlay(
                    Text("Not Graded")
                        .font(UIDevice.current.userInterfaceIdiom == .pad ? .callout : .caption)
                        .foregroundColor(.secondary)
                        .fixedSize()
                )
        }
    }

    ///True when this list shows the questions of an exam that has been taken (exam review mode)
    func isExamReview() -> Bool {
        return contentSection.isExamTypeContentSection() && !contentSection.hasExamModeChildren() && contentSection.hasStoredAnswers()
    }

    ///Screen height left for the list in exam review mode: the screen minus the safe areas (status bar, home indicator)
    ///and the navigation bar. In exam review mode there is no header above the list.
    func examReviewAvailableHeight() -> CGFloat {
        var safeTop:CGFloat = 0
        var safeBottom:CGFloat = 0
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) ?? scenes.first?.windows.first {
            safeTop = window.safeAreaInsets.top
            safeBottom = window.safeAreaInsets.bottom
        }
        let navigationBarHeight:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 50 : 44
        return UIGlobalsCommon.screenBounds.height - safeTop - safeBottom - navigationBarHeight - 8
    }

    ///Keep the tallest measured row height (used to size the exam review and topic lists)
    func recordRowHeight(_ height:CGFloat) {
        if height > measuredRowHeight + 0.5 {
            DispatchQueue.main.async {
                measuredRowHeight = height
            }
        }
    }

    ///In exam review mode the list is sized to show every question without scrolling, using the measured row height
    ///(see recordRowHeight) plus the list row insets and the list's own padding and border.
    ///It never exceeds the space on screen; only if the questions cannot all fit even then does the list scroll.
    ///Elsewhere the original height is kept.
    func listHeight(rowCount:Int) -> CGFloat {
        let screenHeight = UIGlobalsCommon.screenBounds.height
        let defaultHeight = screenHeight * 0.45
        let examReview = isExamReview()
        let topicList = isTopicList()
        if !examReview && !topicList {
            return defaultHeight
        }
        ///Fallback estimate until the first row has been measured
        let estimatedRow:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 52 : 42
        let contentRow = measuredRowHeight > 0 ? measuredRowHeight : estimatedRow
        ///List row top/bottom insets and separator, with a little slack so rounding never forces a scroll
        let rowHeight = max(contentRow + 20, 44)
        ///.padding() around the list (16 top + 16 bottom) and the rounded border, plus one extra row of room.
        ///Testing showed the list's own row spacing makes it about one row short otherwise, on both iPad and iPhone.
        let needed = CGFloat(rowCount + 1) * rowHeight + 48
        if examReview {
            return min(needed, examReviewAvailableHeight())
        }
        ///Topic list: the header with its buttons (Instructions, Tips and Tricks, Video...) sits above the list,
        ///so leave room for it. Never smaller than the original height, so nothing gets shorter than before.
        let headerAllowance:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 170 : 150
        let available = examReviewAvailableHeight() - headerAllowance
        return max(defaultHeight, min(needed, available))
    }

    ///True for a list of topics (e.g. Visual Intervals, Clapping...) as opposed to a list of examples:
    ///every row opens a further list rather than a single question. Not exam lists.
    func isTopicList() -> Bool {
        if contentSection.isExamTypeContentSection() {
            return false
        }
        let children = contentSection.getNavigableChildSections()
        if children.isEmpty {
            return false
        }
        return children.allSatisfy { $0.getNavigableChildSections().count > 0 }
    }

    func isExamCancelled(contentSection:ContentSection) -> Bool {
        if !contentSection.isExamTypeContentSection() {
            return false
        }
        if !contentSection.hasStoredAnswers() {
            return false
        }
        let score = getScore(contentSection: contentSection)
        return score < 0
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
                    HStack {
                        if !isExampleLicensed(contentSection: contentSections[index]) {
                            ZStack {
                                HStack {
                                    Spacer()
                                    Text(contentSections[index].getTitle())
                                        .font(UIGlobalsCommon.navigationFont).foregroundColor(.gray)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    if UIDevice.current.userInterfaceIdiom != .phone {
                                        let msg = "This content requires a\nsubscription"
                                        Text(msg)
                                    }
                                    Button(action: {
                                        licenseInfoPresented.toggle()
                                    }) {
                                        VStack {
                                            Image(systemName: "questionmark.circle")
                                        }
                                    }
                                }
                                ///Required to force SwiftUI's horz line beween Nav links to run full width when text is centered
                                HStack {
                                    Text("")
                                    Spacer()
                                }
                            }
                            //.padding()
                        }
                        else {
                            NavigationLink(destination:
                                            ContentSectionView(contentSection: contentSections[index]),
                                           tag: index,
                                           selection: $contentSection.selectedIndex
                            ) {
                                ZStack {
                                    HStack {
                                        Spacer()
                                        Text(contentSections[index].getTitle())
                                            .font(UIGlobalsCommon.navigationFont)
                                            .padding(.vertical, 8)
                                        Spacer()
                                    }
                                    
                                    ///Required to force SwiftUI's horz line beween Nav links to run full width when text is centered
                                    HStack {
                                        Text("")
                                        Spacer()
                                    }
                                    if let rowImage = getGradeImage(contentSection: contentSections[index]) {
                                        HStack {
                                            Spacer()
                                            if isExamCancelled(contentSection: contentSections[index]) {
                                                Text("Cancelled")
                                            }
                                            rowImage
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40.0)
                                            Text("    ")
                                        }
                                    }
                                    ///Exam review: green tick or red cross at the right of each answered question
                                    if isAnsweredExamQuestion(contentSection: contentSections[index]) {
                                        HStack {
                                            Spacer()
                                            examQuestionMark(contentSection: contentSections[index])
                                            Text("    ")
                                        }
                                    }
                                }
                                ///Measure the row's height so the exam review list can be sized to show all questions
                                .background(
                                    ///(List rows don't pass SwiftUI preferences out of the List, so the height is stored directly)
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear { recordRowHeight(geo.size.height) }
                                            .onChange(of: geo.size.height) { height in recordRowHeight(height) }
                                    }
                                )
                            }
                            .disabled(!isExampleLicensed(contentSection: contentSections[index]))
                            .disabled(isExamCancelled(contentSection: contentSections[index]))
                        }
                    }
                    ///End of Nav link view
                    //.background(Color.clear)
                    //.padding()
                }
                
                ///End of List
                .listStyle(PlainListStyle()) // Removes default List styling
                .roundedBorderRectangle()
                .padding()
                ///Force list view height to stop it taking whole height of screen
                ///In exam review mode the list is made tall enough to show all questions (see listHeight)
                .frame(height: listHeight(rowCount: contentSections.count))

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
                .popover(isPresented: $licenseInfoPresented) {
                    VStack {
                        Text("Access to content for this grade requires a subscription.")
                        Text("Please see the Subscription information on the grade entry page.")
                    }
                    .padding()
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
    @State var showConfirmExit = false
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
    
    func examImage() -> some View {
        VStack {
            Image("judge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIGlobalsCommon.screenBounds.height / 4.0)
        }
    }
    
    func getExamInstructions() -> String {
        var text = "The exam has \(contentSection.getQuestionCount()) questions. Before starting the exam be sure to choose your preferences in the configuration screen for:"
        text += "\n\n• Using an acoustic piano or the built in virtual keyboard for sight reading"
        text += "\n"
        return text
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
                        ScrollView {
                            VStack {
                                Text(getExamInstructions())
                                    .defaultTextStyle()
                                    .padding()
                            }
                        }
                        .roundedBorderRectangle().padding()
                        .frame(height: UIGlobalsCommon.screenBounds.height / 5.0)
                        
                        let msg = UIDevice.current.userInterfaceIdiom == .phone ? "Rhythm Tolerance" : "Please set the rhythm tolerance you'd like to use for the exam."
                        RhythmToleranceView(contextText: msg)
                            //.frame(width: UIGlobalsCommon.screenBounds.width / 2.0)
                        Button(action: {
                            self.examState = .examStarted
                            AudioRecorder.shared.stopPlaying()
                        }) {
                        VStack {
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
                                showConfirmExit = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Exit Exam").defaultButtonStyle().padding()
                                }
                            }
                            ///For some unknwon reason an Alert does not show, so use ActionSheet instead
                            .actionSheet(isPresented: $showConfirmExit) {
                                ActionSheet(
                                    title: Text("Options"),
                                    message: Text("Are you really sure? You cannot restart an exam you exit from"),
                                    buttons: [
                                        .default(Text("Exit Exam")) {
                                            for s in contentSections {
                                                let answer = Answer()
                                                answer.wasCancelled = true
                                                s.setStoredAnswer(answer: answer, ctx: "")
                                                s.saveAnswerToFile(answer: answer)
                                            }
                                            presentationMode.wrappedValue.dismiss()
                                        },
                                        .default(Text("Continue Exam")) {
                                        },
                                        .cancel() {
                                        }
                                    ]
                                )
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
            showConfirmExit = false
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
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

