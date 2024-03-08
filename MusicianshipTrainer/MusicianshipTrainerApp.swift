import SwiftUI
import AVFoundation
import CommonLibrary
import StoreKit

enum LaunchScreenStep {
    case firstStep
    case secondStep
    case finished
}

final class LaunchScreenStateManager: ObservableObject {
    @MainActor @Published private(set) var state: LaunchScreenStep = .firstStep

    @MainActor func dismiss() {
        Task {
            state = .secondStep
            //try? await Task.sleep(for: Duration.seconds(1))
            sleep(1)
            self.state = .finished
        }
    }
}

class Opacity : ObservableObject {
    @Published var imageOpacity: Double = 0.0
    var launchTimeSecs:Double
    var timer:Timer?
    var ticksPerSec = 30.0
    var duration = 0.0
    
    init(launchTimeSecs:Double) {
        self.launchTimeSecs = launchTimeSecs
        let timeInterval = 1.0 / ticksPerSec
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                let opacity = sin((self.duration * Double.pi * 1.0) / self.launchTimeSecs)
                self.imageOpacity = opacity
                if self.duration >= self.launchTimeSecs {
                    self.timer?.invalidate()
                }
                self.duration += timeInterval
            }
        }
    }
}

struct LaunchScreenView: View {
    static var staticId = 0
    var id = 0
    @ObservedObject var opacity:Opacity
    @State var durationSeconds:Double
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager // Mark 1
    
    init(launchTimeSecs:Double) {
        self.opacity = Opacity(launchTimeSecs: launchTimeSecs)
        self.durationSeconds = launchTimeSecs
        self.id = LaunchScreenView.staticId
        LaunchScreenView.staticId += 1
    }

    func appVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(appVersion).\(buildNumber)"
    }
    
    func log() {
        //print("LaunchScreenView ", "id:", id, "state:", launchScreenState.state, "opac:", opacity.imageOpacity, "dur:", durationSeconds, "id:")
    }
    
    @ViewBuilder
    private var image: some View {  // Mark 3
        GeometryReader { geo in
            //hack: for some reason there are 2 instances of LaunchScreenView. The first starts showing too early ??
            //if id == 1 {
                VStack {
                    ///Image causes title to be truncated on phone
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image("NZMEB_logo_splash_screen")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width * 0.40)
                                .opacity(self.opacity.imageOpacity)
                            Spacer()
                        }
                        Spacer()
                    }
                    VStack(alignment: .center) {
                        //VStack {
                            Text("NZMEB Musicianship Trainer").font(.title)
                            Text("")
                            Text("© 2024 Musicmaster Education LLC.")//.font(.title3)
                        //}
                        //.position(x: geo.size.width * 0.5, y: geo.size.height * 0.85)
                        .opacity(self.opacity.imageOpacity)
                        Text("Version \(appVersion())")
                        Text("")
                        Text("")
                    }
                }
            //}
        }
    }
    
    var body: some View {
        ZStack {
            //backgroundColor  // Mark 3
            image  // Mark 3
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
#if targetEnvironment(simulator)
        ///Simulator asks for password every time even though its signed in with Apple ID. By design for IAP purchasing... :(
        ///Code to run on the Simulator
        print("Running on the Simulator, will not load IAP licenses")
#else
        SKPaymentQueue.default().add(LicenceManager.shared) ///Do this as early as possible so manager is a queue observer
        LicenceManager.shared.verifyStoredSubscriptionReceipt(ctx: "App starting") ///Get the current validity of any locally stored subscription receipt
        LicenceManager.shared.requestProducts() ///Get products
        ///LicenceManager.shared.restoreTransactions() ///No need - the last subscription receipt received is stored locally. If not (e.g. nmew device) user does 'Restore Subscriptions'
#endif
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        Logger.logger.log(self, "Version.Build \(appVersion).\(buildNumber)")
        
        //Make navigation titles at top larger font
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.font : UIFont.systemFont(ofSize: 24, weight: .bold)]
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        var statusMsg = ""
        switch status {
        case .authorized:
            statusMsg = "The user has previously granted access to the microphone."
        case .notDetermined:
            statusMsg = "The user has not yet been asked to grant microphone access."
        case .denied:
            statusMsg = "The user has previously denied access."
        case .restricted:
            statusMsg = "The user can't grant access due to restrictions."
        @unknown default:
            statusMsg = "unknown \(status)"
        }
        Logger.logger.log(self, "Microphone access:\(statusMsg))")
        return true
    }
}

@main
struct MusicianshipTrainerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    ///Must be @State to notify view when loaded
    @ObservedObject var exampleData:ExampleData
    @StateObject var launchScreenState = LaunchScreenStateManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var logger = Logger.logger
    static let productionMode = true
    let settings:SettingsMT = SettingsMT.shared
    
    //product licensed by grade 14Jun23
    let rootContentSection:ContentSection// = ContentSection(parent: nil, name: "", type: "")//ContentSection(parent: nil, name: "Grade 1", type: ContentSection.SectionType.none)
    var launchTimeSecs = 4.5
    let launchScreen = LaunchScreenView(launchTimeSecs: 4.5)

    init() {
        //Playback supposedly gives better playback than play and record. So only set record when needed
        //AudioManager.shared.initAudio("MusicianshipTrainerApp")
        rootContentSection = ContentSection(parent: nil, name: "", type: "")
        exampleData = ExampleData(sheetName: SettingsMT.shared.useTestData ? "ContentSheetID_TEST" : "ContentSheetID", rootContentSection: rootContentSection)
    }
    
    func getStartContentSection() -> ContentSection {
        var cs:ContentSection
        //if MusicianshipTrainerApp.productionMode {
            cs = rootContentSection//.subSections[1].subSections[0] //NZMEB, Grade 1
        //}
        //else {
            //cs = MusicianshipTrainerApp.root.subSections[1].subSections[0].subSections[0] //NZMEB, Grade 1, practice
        //}
        return cs
    }
    
    func getDataLoadedStatus() -> RequestStatus {
        return self.exampleData.dataStatus
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if launchScreenState.state == .finished {
                    if getDataLoadedStatus() == RequestStatus.success {
                        ContentNavigationView(contentSection: getStartContentSection())
                        ///No colour here appears to make a difference. i.e. be visible
                            //.background(Color(red: 0.0, green: 0.7, blue: 0.7))
                    }
                    else {
                        if getDataLoadedStatus() == RequestStatus.waiting {
                            Spacer()
                            Image(systemName: "hourglass.tophalf.fill")
                                .resizable()
                                .frame(width: 30, height: 60)
                                .foregroundColor(Color.blue)
                                .padding()
                            Text("")
                            Text("Loading Content...").font(.headline)
                            Spacer()
                        }
                        else {
                            VStack {
                                Text("Sorry, we could not create an internet conection.").font(.headline).foregroundColor(.red).padding()
                                Text("Please try again.").font(.headline).foregroundColor(.red).padding()
                                Text(" ").padding()
                                if let errMsg = logger.errorMsg {
                                    Text("Error:\(errMsg)").padding()
                                }
                            }
                        }
                    }
                }
                if MusicianshipTrainerApp.productionMode  {
                    if launchScreenState.state != .finished {
                        launchScreen
                        //LaunchScreenView(launchTimeSecs: launchTimeSecs)
                    }
                }
            }
            .environmentObject(launchScreenState)
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + launchTimeSecs) {
                    self.launchScreenState.dismiss()
                }
            }
        }
    }
}

