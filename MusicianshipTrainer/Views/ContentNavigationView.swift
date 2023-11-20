import SwiftUI
import CoreData
import CommonLibrary

struct GradeIntroView: View {
    
    var body: some View {
            VStack  (alignment: .center) {
                Text("Musicianship Trainer")
                    //.font(.title)
                    .font(UIGlobals.font)
                    .fontWeight(.bold)
                    .padding()
                
                
                Text("Grade 1 Piano")
                    .font(UIGlobals.font)
                    .fontWeight(.bold)
                    .padding()
                
                //Image("nzmeb_logo_transparent")
                Image("NZMEB logo aqua bird")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding()
            }
            .padding()
    }
}

struct ContentNavigationView: View {
    let contentSection:ContentSection
    @State private var isShowingConfiguration = false
    @State private var selectedContentIndex: Int? = 0 //has to be optional for the case nothing is selected

    var body: some View {
        NavigationView {
            VStack {
                GradeIntroView()
                ZStack {
                    List(contentSection.subSections) { contentSection in
                        NavigationLink(destination: ContentSectionView(contentSection: contentSection)) {
                            //parentsSelectedContentIndex: $selectedContentIndex)) {
                            ZStack {
                                HStack {
                                    Spacer()
                                    Text(contentSection.getTitle()).padding()
                                        .font(UIGlobals.navigationFont)
                                    Spacer()
                                }
                                ///Required to force SwiftUI's horz line beween Nav links to run full width when text is centered
                                HStack {
                                    Text("")
                                    Spacer()
                                }
                            }
                        }
                        .disabled(!contentSection.isActive)
                        .padding(.vertical, 4)
                    }
                    //.listRowBackground(Color.yellow)
                    .sheet(isPresented: $isShowingConfiguration) {
                        let newSettings = Settings(copy: Settings.shared)
                        ConfigurationView(isPresented: $isShowingConfiguration,
                                          settings: newSettings
                        )
                    }
                }
            }

            //.navigationTitle(topic.name) ?? ignored??
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingConfiguration = true
                    }) {
                        Image(systemName: "music.note.list")
                            .foregroundColor(.blue)
                            //.font(.largeTitle)
                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .largeTitle)
                    }
                }
            }
        }
        //On iPad, the default behavior of NavigationView is to display as a master-detail view in a split view layout. This means that the navigation view will be visible only when the app is running in a split-screen mode, such as in Split View or Slide Over.
        //When running the app in full-screen mode on an iPad, the NavigationView will collapse to a single view, and the navigation links will be hidden. This behavior is by design to provide a consistent user experience across different device sizes and orientations.
        .navigationViewStyle(StackNavigationViewStyle()) // Use StackNavigationViewStyle - turns off the split navigation on iPad
    }
}
