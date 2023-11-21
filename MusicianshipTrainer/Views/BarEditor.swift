import Foundation
import SwiftUI
import CommonLibrary

///Show the bar view based on the positions of the bar lines
struct BarEditorView: View {
    @ObservedObject var score:Score
    @ObservedObject var barEditor:BarEditor
    @State private var showHelp = false
    
    init (score:Score) {
        self.score = score
        self.barEditor = score.barEditor!
    }
    
    func getNoteCountsPerBar() -> [Int] {
        var result:[Int] = []
        let entries = score.scoreEntries
        var count = 0
        for entry in entries {
            if entry is BarLine {
                result.append(count)
                count = 0
            }
            if entry is TimeSlice {
                count += 1
            }
        }
        result.append(count)
        return result
    }
    
    ///Return the bar index number and the start and end x span of the bar's postion on the UI
    func getPositions() -> [(Int, CGFloat, CGFloat)] {
        var barLineCovers:[(CGFloat, CGFloat)] = []
        var totalBarLengths = 0.0
        for p in score.barLayoutPositions.positions {
            barLineCovers.append((p.value.minX, p.value.maxX))
            totalBarLengths += p.value.maxX - p.value.minX
        }
        let sortedBarLineCovers = barLineCovers.sorted{ $0.0 < $1.0}
        ///The barLayoutPositions dont include the last bar. So calculate the average width per note and make the last bar that width * the number of notes in the last bar
        var noteCounts = getNoteCountsPerBar()
        let noteCount = noteCounts.dropLast().reduce(0, +)
        var avgLen = 0.0
        if noteCount > 0 {
            avgLen = totalBarLengths / Double(noteCount)
        }
        var barCovers:[(Int, CGFloat, CGFloat)] = []
        let startEdgeWidth = 40.0
        let endBarLen = avgLen * Double(noteCounts[noteCounts.count-1])
        var nextX = startEdgeWidth

        for i in 0..<sortedBarLineCovers.count {
            barCovers.append((i, nextX, sortedBarLineCovers[i].0)) //sortedBarLineCovers[i].0))
            nextX = sortedBarLineCovers[i].1
        }
        barCovers.append((sortedBarLineCovers.count, nextX, nextX + endBarLen * 3.0))
        return barCovers
    }
    
    func getColor(way:Bool) -> Color {
        return way ? Color.indigo.opacity(0.25) : Color.blue.opacity(0.1)
    }
           
    var body: some View {
        if let barEditor = score.barEditor {
            let iconWidth = score.lineSpacing * 3.0
            ZStack {
                ForEach(getPositions(), id: \.self.0) { indexAndPos in
                    let barWidth = (indexAndPos.2 - indexAndPos.1)
                    HStack {
                        if indexAndPos.0 < barEditor.selectedBarStates.count {
                            if barEditor.selectedBarStates[indexAndPos.0] {
                                if score.scoreEntries.count > 1 {
                                    //Text("Delete Bar \(indexAndPos.0+1)").defaultTextStyle()
                                    HStack {
                                        Button(action: {
                                            barEditor.reWriteBar(targetBar: indexAndPos.0, way: .delete)
                                        }) {
                                            Image("delete_icon")
                                                .resizable()
                                                .foregroundColor(.red)
                                                .frame(width: iconWidth, height: iconWidth)
                                        }
                                        .padding()
                                        Button(action: {
                                            barEditor.reWriteBar(targetBar: indexAndPos.0, way: .doNothing)
                                        }) {
                                            Text("Cancel").bold().defaultTextStyle()
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                    .position(x:indexAndPos.2 - barWidth/2.0, y:0)
                    .frame(height: score.lineSpacing * 12.0)
                    //.border(Color .green, width: 2)
                    
                    ///Hilite every bar with shading
                    GeometryReader { geometry in
                        if indexAndPos.0 < barEditor.selectedBarStates.count {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getColor(way: barEditor.selectedBarStates[indexAndPos.0]))
                                .frame(width: barWidth, height: score.lineSpacing * 8.0) //130
                                .onTapGesture {
                                    barEditor.toggleState(indexAndPos.0)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                                .position(x:indexAndPos.2 - barWidth / 2.0, y:geometry.size.height / 2.0)
                        }
                    }
                }
            }
            
            .onAppear() {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    showHelp = true
                    Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
                        showHelp = false
                    }
                }
            }
            .popover(isPresented: $showHelp) {
                Text("Click any bar to select it. Then click the red cross to remove the bar.").padding(20)
            }
        }
    }
}
