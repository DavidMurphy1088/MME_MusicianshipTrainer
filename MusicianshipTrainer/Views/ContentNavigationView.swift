import SwiftUI
import CoreData
import CommonLibrary

struct ProductIntroView: View {
    var body: some View {
            VStack  (alignment: .center) {
                Text("Musicianship")
                    .font(.system(size: 42))
                    .fontWeight(.bold)
                    //.padding()

                Text("Trainer")
                    .font(.system(size: 42))
                    .fontWeight(.bold)
                    //.padding()
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Image("NZMEB_logo_bird_transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.height * 0.20)
                        .padding()
                }
            }
            //.padding()
    }
}

struct ContentNavigationView: View {
    let contentSection:ContentSection
    @State private var isShowingConfiguration = false
    @State private var selectedContentIndex: Int? = 0 //has to be optional for the case nothing is selected

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    VStack {
                        Image("app_background_navigation")
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .opacity(UIGlobalsMT.shared.backgroundImageOpacity)
                    }
                    VStack {
                        ProductIntroView()
                        HStack {
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                Text("      ")
                            }
                            else {
                                Text("                                          ")
                            }
                            VStack {
                                List(contentSection.subSections) { contentSection in
                                    NavigationLink(destination: ContentSectionView(contentSection: contentSection)) {
                                        ZStack {
                                            HStack {
                                                Spacer()
                                                Text(contentSection.getTitle()).padding()
                                                    .font(UIGlobalsCommon.navigationFont)
                                                    .listRowBackground(Color.clear)
                                                Spacer()
                                            }
                                            ///Required to force SwiftUI's horz line beween Nav links to run full width when text is centered
                                            HStack {
                                                Text("")
                                                    .listRowBackground(Color.clear)
                                                Spacer()
                                            }
                                        }
                                    }
                                    //.listRowBackground(Color.clear)
                                    .disabled(!contentSection.isActive)
                                    .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0.0 : 0.0)
                                }
                                .background(Color.clear) // Makes List background transparent
                                .listStyle(PlainListStyle()) // Removes default List styling
                                .roundedBorderRectangle()
                            }
                            .frame(height: UIScreen.main.bounds.height * (UIGlobalsCommon.isLandscape() ? 0.33 : 0.40))
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                Text("      ")
                            }
                            else {
                                Text("                                          ")
                            }
                       }
                        .sheet(isPresented: $isShowingConfiguration) {
                            let newSettings = SettingsMT(copy: SettingsMT.shared)
                            ConfigurationView(isPresented: $isShowingConfiguration,
                                              settings: newSettings
                            )
                        }
                    }
                }
            }

            //.navigationTitle(topic.name) ?? ignored??
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingConfiguration = true
                    }) {
                        let x = log1(contentSection)
                        Image(systemName: "music.note.list")
                            .foregroundColor(.blue)
                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .largeTitle)
                    }
                }
            }
        }
        //On iPad, the default behavior of NavigationView is to display as a master-detail view in a split view layout. This means that the navigation view will be visible only when the app is running in a split-screen mode, such as in Split View or Slide Over.
        //When running the app in full-screen mode on an iPad, the NavigationView will collapse to a single view, and the navigation links will be hidden. This behavior is by design to provide a consistent user experience across different device sizes and orientations.
        .navigationViewStyle(StackNavigationViewStyle()) // Use StackNavigationViewStyle - turns off the split navigation on iPad
    }
    
    func log1(_ cs:ContentSection) {
        print("======== CONFIG", contentSection.getPathAsArray())
    }
}
