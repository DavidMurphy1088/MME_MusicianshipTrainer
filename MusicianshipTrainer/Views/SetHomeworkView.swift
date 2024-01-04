import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit
import Foundation
import CommonLibrary

// Extension to get the ordinal day suffix
extension Date {
    func daySuffix() -> String {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: self)
        switch dayOfMonth {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

class ExType : Identifiable, ObservableObject, Hashable {
    static func == (lhs: ExType, rhs: ExType) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    let parent: Week
    var name:String
    @Published var examples: Int = 0
    @Published var correct: Int = 0
    @Published var incorrect: Int = 0

    init(_ parent:Week, _ name:String, _ correct: Int, _ incorrect: Int) {
        self.name = name
        self.parent = parent
        self.correct = correct
        self.incorrect = incorrect
        self.examples = correct + incorrect
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class Week: Identifiable, ObservableObject {
    let id = UUID()
    var exTypes:[ExType] = []
    var date: Date
    @Published var dateStr: String
    
    init(date: Date) {
        self.date = date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d'\(date.daySuffix())' MMM"
        self.dateStr = dateFormatter.string(from: date)
        var correct = 0
        var incorrect = 0
        
        for i in 0..<5 {
            if date < Date() {
                let r = Int.random(in: 0..<3)
                let total = 9 + r
                incorrect = Int.random(in: 0..<3)
                correct = total - incorrect
            }
            var name = ""
            switch i {
            case 0:
                name = "Visual Intervals"
            case 1:
                name = "Clapping"
            case 2:
                name = "Sight Reading"
            case 3:
                name = "Aural Intervals"
            case 4:
                name = "Echo Clap"
            default:
                name = ""
            }
            exTypes.append(ExType(self, name, correct, incorrect))
        }
    }
    
    func totalCorrect(_ way:Bool) -> Int {
        var tot = 0
        for e in exTypes {
            if way {
                tot += e.correct
            }
            else {
                tot += e.incorrect
            }
        }
        return tot
    }
}

class Weeks : ObservableObject {
    @Published var weeks:[Week] = []
}

struct SetHomeworkView: View {
    let contentSection: ContentSection
    @ObservedObject var weeks = Weeks()
    let fontSize = 24.0
    @State var status:String = ""
    
    var body: some View {
        Text("Set Homework").font(.title).bold()
        //Text(contentSection.getTitle()).font(.title)
        //ScrollView {
            List {
                ForEach($weeks.weeks, id: \.id) { $week in
                    WeekRow(week: week, contentSection: contentSection, fontSize: fontSize)
                }
            }
            .onAppear() {
                weeks.weeks = []
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(identifier: "Pacific/Auckland")
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let now = Date()
                var calendar = Calendar.current
                calendar.timeZone = TimeZone(identifier: "Pacific/Auckland")!
                let weekdayComponents = calendar.dateComponents([.weekday], from: now)
                let daysToSubtract = weekdayComponents.weekday! - 2
                let daysToAdd = daysToSubtract <= 0 ? (daysToSubtract - 7) : -daysToSubtract
                guard let lastMonday = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                    return
                }
                guard let previousMonday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastMonday)) else {
                    return
                }
                dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                guard let startDate = Calendar.current.date(byAdding: .day, value: 1 - 4*7, to: previousMonday) else {
                    return
                }
                
                var date = startDate
                for _ in 0..<10 {
                    let week = Week(date: date)
                    weeks.weeks.append(week)
                    if let date1 = Calendar.current.date(byAdding: .day, value: 7, to: date) {
                        date = date1
                    }
                }
            }
        //}
//        VStack {
//            Button(action: {
//                status = "Set Examples"
//            }) {
//                VStack {
//                    Text("Set Homework Examples")
//                        .font(.title)
//                        .padding()
//
//                }
//                .padding()
//            }
//            Text(status)
//        }
    }
}

struct WeekRow: View {
    @ObservedObject var week: Week
    let contentSection: ContentSection
    let fontSize:CGFloat

    @State private var isExpanded: Bool = false
    @State private var sliderValue: Double = 1

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ZStack {
                    HStack {
                        Text(week.dateStr)
                            .onTapGesture {
                                withAnimation {
                                    self.isExpanded.toggle()
                                }
                            }
                        Spacer()
                    }
                    if week.date < Date() {
                        HStack {
                            Spacer()
                            Text("     ")
                            Text("Examples ")
                            let n = String(format: "%2d", week.totalCorrect(true) + week.totalCorrect(false))
                            Text(n).font(.title).bold()
                            Spacer()
                            HStack {
                                Text("Correct")
                                let n = String(format: "%2d", week.totalCorrect(true))
                                Text(n).foregroundColor(.green).font(.title).bold()
                            }
                            Spacer()
                            HStack {
                                Text("Incorrect")
                                let n = String(format: "%2d", week.totalCorrect(false))
                                Text(n).foregroundColor(.red).font(.title).bold()
                            }
                            Spacer()
                        }
                    }
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .onTapGesture {
                        withAnimation {
                            self.isExpanded.toggle()
                        }
                    }
            }
            
            if isExpanded {
                VStack {
                    NavigationView {
                        List(week.exTypes, id: \.self) { exType in
                        //ForEach(week.exTypes, id: \.id) { exType in
                            TypeRow(contentSection: contentSection, exType: exType, date: week.date, fontSize: fontSize)
                        }
                        .listStyle(PlainListStyle())
                    }
                    .listStyle(PlainListStyle()) // Removes default List styling
                    .navigationViewStyle(StackNavigationViewStyle()) // Forces a full screen presentation
                    .frame(height: 220)
                    .edgesIgnoringSafeArea(.all)
                }
                .padding()
            }
        }
    }
}

struct TypeRow: View {
    let contentSection: ContentSection
    @ObservedObject var exType: ExType
    var date:Date
    let fontSize:CGFloat
    @State private var isExpanded: Bool = false
    @State private var sliderValue: Double = 1
    
    @State var exampleSection:ContentSection? = nil
    @State var answerState:AnswerState = .notEverAnswered
    @State var answer:Answer = Answer()
    
    func getErrorExamples(type:String) -> ContentSection? {
        let errs = contentSection.contentSearch(testCondition: {section in
            if let stored = section.storedAnswer {
                if !stored.correct {
                    return true
                }
            }
            return false
        })
        for e in errs {
            if e.getPath().contains(type) {
                return e
            }
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            HStack {
                Text("  ")
                Text(exType.name)
                Spacer()
            }
            HStack {
                Text("                                 ")
                Text("Examples ")
                var n1 = String(format: "%2d", exType.examples)
                Text(n1)
                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                    .bold()
                if date < Date() {
                    Text("   Correct")
                    let n2 = String(format: "%2d", exType.correct)
                    Text(n2)
                        .foregroundColor(.green)
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .bold()
                    Text("   Incorrect")
                    let n3 = String(format: "%2d", exType.incorrect)
                    Text(n3)
                        .foregroundColor(.red)
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .bold()
                    if exType.incorrect > 0 {
                        if let example = exampleSection {
                            NavigationLink("\(example.name)", destination: ContentTypeView(contentSection: example,
                                                                                           answerState:$answerState,
                                                                                           answer: $answer))
                            //.accentColor(.blue)
                            .foregroundColor(.blue)
                        }
                    }
                        
                }
                Spacer()
            }
            .onAppear {
                exampleSection = getErrorExamples(type: exType.name)
                if let e = exampleSection {
                    if let a = e.storedAnswer {
                        self.answer = a
                    }
                }
                self.answerState = .submittedAnswer
            }

            HStack {
                Text("                           ")
                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                Slider(value: Binding(
                    get: { Double(exType.examples) },
                    set: {
                        exType.examples = Int($0)
                    }
                ), in: 0...10, step: 1)
                .opacity(Date() < date ? 1.0 : 0.0)
                Text("              ")
                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
            }
        }
    }
}
