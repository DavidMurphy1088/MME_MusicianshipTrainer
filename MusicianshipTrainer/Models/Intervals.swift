import Foundation

///The same pitch difference can be a different interval depending on how its written
///e.g. pitch interval 6 can be an augmented 4th or diminished 5th. They are differentiated by the number of notes the interval spans. i.e. how it is written.
///e.g. an augmented fourth from midi 60=C 4th spans D,E,F (notes=3) whereas a diminished fifth spans D,E,F,G (notes=4)
///So pitch difference 6 exists in 2 groups
class IntervalGroup : Comparable, Hashable {
    var name:String
    var intervals:[Int]
    var noteSpan:Int
    @Published var enabled:Bool = true
    
    static func == (lhs: IntervalGroup, rhs: IntervalGroup) -> Bool {
        return lhs.name == rhs.name
    }

    static func < (lhs: IntervalGroup, rhs: IntervalGroup) -> Bool {
        return lhs.name < rhs.name
    }

    init(name:String, noteSpan:Int, intervals:[Int]) {
        self.intervals = intervals
        self.name = name
        self.noteSpan = noteSpan
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
//    func setEnabled(way:Bool) {
//        DispatchQueue.main.async {
//            self.enabled = way
//        }
//    }
}

class Intervals : ObservableObject {
    var intervalNames:[IntervalGroup]
    var intervalsPerColumn:Int
    @Published var enabledChanged = false

    init(grade:Int, questionType:QuestionType) {
        let ageGroup = Settings.shared.getAgeGroup()
        self.intervalNames = []
        
        if grade >= 1 {
            ///Grade 1 calls both minor and major third just a 3rd
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Second" : "2nd", noteSpan: 1, intervals:[1,2,3]))
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Third" : "3rd", noteSpan: 2, intervals:[3,4]))
        }

        if grade >= 2 {
            ///Intervals (visual): The entrant will be shown three notes, and will be asked to identify the intervals as either a second, third, fourth or fifth.

            ///Perfect and augmented 4ths
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Fourth" : "4th", noteSpan: 3, intervals:[5,6]))
            
            ///Diminished, perfect and augmented 5ths
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Fifth" : "5th", noteSpan: 4, intervals:[6,7,8]))

        }
        if grade >= 3 && questionType == .intervalVisual {
            ///The entrant will be shown three notes, and will be asked to identify the intervals as either a second, third, fourth, fifth, sixth, seventh or octave.
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Sixth" : "6th", noteSpan: 5, intervals:[8,9,10]))
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Seventh" : "7th", noteSpan: 6, intervals:[10,11]))
            intervalNames.append(IntervalGroup(name: ageGroup == Settings.shared.AGE_GROUP_11_PLUS ? "Octave" : "Octave", noteSpan: 7, intervals:[12]))
        }
        self.intervalsPerColumn = Int(Double((self.intervalNames.count + 1)) / 2.0)
        if intervalsPerColumn == 0 {
            intervalsPerColumn = 1
        }
    }
    
    ///Selected is used for hints. Hints can disable a number of incorrect intervals to make the question easier
    ///Enable intervals randomly and ensure 1/2 are enabled
    func setRandomSelected(correctIntervalName:String) {
        var correctIndex = 0

        for i in 0..<intervalNames.count {
            if intervalNames[i].name == correctIntervalName {
                correctIndex = i
            }
            intervalNames[i].enabled = true
        }
        if correctIntervalName.count == 0 {
            return
        }
        var enabledIndexes:[Int] = []// = Array(repeating: false, count: intervalNames.count)

        enabledIndexes.append(correctIndex)
        let required = (intervalNames.count + 1) / 2
        while enabledIndexes.count < required {
            let random = Int.random(in: 0..<intervalNames.count)
            if !enabledIndexes.contains(random) {
                enabledIndexes.append(random)
            }
        }
        for i in 0..<intervalNames.count {
            //intervalNames[i].setEnabled(way: enabledIndexes.contains(i))
            intervalNames[i].enabled = enabledIndexes.contains(i)
        }
        DispatchQueue.main.async {
            self.enabledChanged.toggle()
        }
    }
    
    func getInterval(intervalName:String) -> IntervalGroup? {
        for group in intervalNames {
            if group.name == intervalName {
                return group
            }
        }
        return nil
    }
    
    func getVisualColumnCount() -> Int {
        return (intervalNames.count + self.intervalsPerColumn/2) / self.intervalsPerColumn
    }
    
    func getVisualColumns(col:Int) -> [IntervalGroup] {
        var result:[IntervalGroup] = []
        //let start = col * intervalsPerColumn
        for i in 0..<intervalsPerColumn {
            let index = i + col * intervalsPerColumn
            if index < intervalNames.count {
                result.append(intervalNames[index])
            }
        }
        return result
    }
    
    func getExplanation(grade:Int, offset1:Int, offset2:Int) -> String {
        var explanation = ""
        if grade == 1 {
            if offset1 % 2 == 0 {
                explanation = "A line to a "
                if offset2 % 2 == 0 {
                    explanation += "line is a skip"
                }
                else {
                    explanation += "space is a step"
                }
            }
            else {
                explanation = "A space to a "
                if offset2 % 2 == 0 {
                    explanation += "line is a step"
                }
                else {
                    explanation += "space is a skip"
                }
            }
        }
        else {
            if offset1 % 2 == 0 && offset2 % 2 == 0 {
                explanation = "A line to a line is an odd interval"
            }
            else {

                if abs(offset1 % 2) == 1 && abs(offset2 % 2) == 1 {
                    explanation = "A space to a space is an odd interval"
                }
                else {
                    if offset1 % 2 == 0 {
                        explanation = "A line to a space is an even interval"
                    }
                    else {
                        explanation = "A space to a line is an even interval"
                    }
                }
            }
        }
        return explanation
    }
}
