
import Foundation
import SwiftUI
import StoreKit
import CommonLibrary

public struct LicenseManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    let contentSection:ContentSection
    let email:String
    @ObservedObject var iapManager = IAPManager.shared
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
        let products: [SKProduct] = Array(IAPManager.shared.availableProducts.values)
        let filteredProducts = products.filter { product in {
            let grade = contentSection.getPathTitle().replacingOccurrences(of: " ", with: "_")
            return product.productIdentifier.hasPrefix("NZMEB") && product.productIdentifier.contains(grade)
        }()
        }
        return filteredProducts
    }
    
    struct InfoView:View {
        let contentSection:ContentSection
        let yearString:String
        public var body: some View {
            VStack {
                Text("Access to some content is restricted without this license.").padding()
                Text("Purchasing this license provides you with unlimited access to all the practice examples and practice exams for \(contentSection.getPathTitle()) NZMEB Musicianship for calendar year \(yearString).").padding()
                //Text("Free licensing is available for NZMEB teachers.").padding()
                Text("Free licensing is available for NZMEB teachers. Please contact sales@musicmastereducation.co.nz for more details.").padding()

            }
        }
    }
    
    public var body: some View {
        VStack {
            Text("\(contentSection.getPathTitle()) License").font(.title).padding()
            if let license = SettingsMT.shared.getNameOfLicense(grade: contentSection.name, email: email) {
                VStack {
                    Text("Your current license is ").padding()
                    Text("\(license)").font(.title).bold().foregroundColor(.green)
                }
                .padding()
                Text("This license provides you with unlimited access to all the practice examples and practice exams for \(contentSection.getPathTitle()) NZMEB Musicianship.").padding().padding().padding()
            }
            else {
                if iapManager.isLicenseAvailable(grade: contentSection.name) {
                    List {
                        ForEach(getProducts(), id: \.self) { product in
                            HStack {
                                Text(product.localizedTitle)
                                Spacer()
                                let currency = product.priceLocale.localizedString(forCurrencyCode: product.priceLocale.currencyCode!)
                                Text(currency ?? "")
                                let price:String = product.price.description
                                Text(price)
                            }
                        }
                    }
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
                        Text("Purchase in process. Please standby...").foregroundColor(.green).padding()
                    }
                    else {
                        Button(action: {
                            iapManager.buyProduct(grade: contentSection.name)
                        }) {
                            Text("Purchase")
                                .font(.title)
                                .padding()
                        }
                    }
                }
                else {
                    Text("Sorry, no license is available yet")
#if targetEnvironment(simulator)
                    Text("SIMULATOR CANNOT DO LICENSING")
#endif
                }
            }
            VStack {
                Button(action: {
                    iapManager.restoreTransactions()
                }) {
                    Text("Restore Licenses")
                        .font(.title)
                        .padding()
                }
            }

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

