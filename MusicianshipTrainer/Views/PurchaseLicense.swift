
import Foundation
import SwiftUI
import StoreKit
import CommonLibrary

public struct LicenseManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    let contentSection:ContentSection
    let email:String
    @ObservedObject var iapManager = LicenceManager.shared
    @State var isPopupPresented = false
    var yearString = ""
    
    public init(contentSection:ContentSection, email:String) {
        self.contentSection = contentSection
        self.email = email
        let currentYear = Calendar.current.component(.year, from: Date())
        let formatter = NumberFormatter()
        formatter.numberStyle = .none // This ensures no comma formatting
        yearString = formatter.string(from: NSNumber(value: currentYear)) ?? ""
    }
    
    func getProducts() -> [SKProduct] {
        let products = LicenceManager.shared.purchaseableProducts.values.sorted { (product1, product2) -> Bool in
            return product1.price.compare(product2.price) == .orderedAscending
        }
//        let filteredProducts = products.filter { product in {
//            let grade = contentSection.getPathTitle().replacingOccurrences(of: " ", with: "_")
//            if product.productIdentifier.hasPrefix("MT") { 
//                return true
//            }
//            return product.productIdentifier.hasPrefix("NZMEB") && product.productIdentifier.contains(grade)
//        }()
//        }
        //return filteredProducts
        return products
    }
    
    struct InfoView:View {
        let contentSection:ContentSection
        let yearString:String
        public var body: some View {
            VStack() {
                let info = "Access to some content is restricted without a subscription.\n\nPurchasing a subscription provides you with access to all the NZMEB Musicianship practice examples and practice exams."
                //\n\nFree licensing is available for NZMEB teachers. Please contact sales@musicmastereducation.co.nz for more details."
                Text(info).padding()
            }
        }
    }
    
    func getSubscriptionName() -> String {
        if let licence = SubscriptionTransactionReceipt.load() {
            return licence.getDescription()
        }
        else {
            return "No stored subscription"
        }
    }
    
    public var body: some View {
        VStack {
            Text("Available Subscriptions").font(.title).padding()
            //if let license = LicenceManager.shared.getNameOfStoredSubscription(email: email) {
            if SettingsMT.shared.isLicensed() {
                VStack {
                    Text("Your current subscription is ").padding()
                    if LicenceManager.shared.emailIsLicensed(email:SettingsMT.shared.configuredLicenceEmail) {
                        Text("Teacher email \(SettingsMT.shared.configuredLicenceEmail)").foregroundColor(.green).bold().padding()
                    }
                    else {
                        Text(getSubscriptionName()).foregroundColor(.green).bold().padding()
                    }
                }
                .padding()
                Text("This subscription provides you with access to all the NZMEB Musicianship practice examples and practice exams.").padding().padding().padding()
            }
            else {
                if iapManager.isLicenseAvailableToPurchase(grade: contentSection.name) {
                    ///A plain VStack (not a List) so both subscription plans are shown in full without scrolling.
                    ///A List only gets the height left over by the rest of the screen, which forced scrolling.
                    VStack(spacing: 0) {
                        ForEach(getProducts(), id: \.self) { product in
                            HStack {
                                Text(product.localizedTitle)
                                Spacer()
                                let currency = product.priceLocale.localizedString(forCurrencyCode: product.priceLocale.currencyCode!)
                                Text(currency ?? "")
                                let price:String = product.price.description
                                Text(price)
                                Button(action: {
                                    //iapManager.buyProduct(grade: contentSection.name)
                                    iapManager.buyProductSubscription(product: product)
                                }) {
                                    Text("Purchase")
                                        .font(.title2)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            Divider()
                        }
                    }
                    .roundedBorderRectangle()
                    .padding()
                    .navigationTitle("Available Products")
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button(action: {
                            isPopupPresented.toggle()
                        }) {
                            VStack {
                                Image(systemName: "questionmark.circle")
                            }
                        }
                        .padding()
                        .popover(isPresented: $isPopupPresented) {
                            InfoView(contentSection: contentSection, yearString: yearString)
                        }
                    }
                    else {
                        HStack {
                            Text("                  ").padding()
                            InfoView(contentSection: contentSection, yearString: yearString)
                            Text("                  ").padding()
                        }
                    }
                    if iapManager.isInPurchasingState {
                        Text("Purchase in progress. Please standby...").font(.title).foregroundColor(.green).bold().padding()
                    }

                }
                else {
                    Text("Sorry, no subscription is available yet")
#if targetEnvironment(simulator)
                    Text("SIMULATOR CANNOT DO LICENSING")
#endif
                }
            }
            VStack {
                Button(action: {
                    iapManager.restoreTransactions()
                }) {
                    Text("Restore Subscriptions")
                        .font(.title)
                        .padding()
                }
            }

            ///App Store Guideline 3.1.2: the subscription screen must show auto-renewal terms and working links
            ///to the Terms of Use (EULA) and the Privacy Policy.
            VStack(spacing: 6) {
                Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your Apple Account settings.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 20) {
                    Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("Privacy Policy", destination: URL(string: "https://www.musicmastereducation.co.nz/NZMEB_MusicianshipTrainer/privacypolicy.html")!)
                }
                .font(.footnote)
            }
            .padding(.horizontal)

            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Dismiss")
                        .font(.title)
                        .padding()
                }
            }
        }
    }
}

