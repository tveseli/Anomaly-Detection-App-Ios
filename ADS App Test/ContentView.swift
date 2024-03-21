//
//  ContentView.swift
//  ADS App Test
//
//  Created by Aaron Beckley on 3/10/24.
//

import SwiftUI
import AnomalyDetection
import Charts
import UniformTypeIdentifiers


//https://www.hackingwithswift.com/forums/swiftui/looking-for-help-how-to-select-and-open-an-existing-data-file-with-a-document-browser/3953
struct InputDoument: FileDocument {

    static var readableContentTypes: [UTType] { [.plainText] }

    var input: String

    init(input: String) {
        self.input = input
    }

    init(configuration: FileDocumentReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        input = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: input.data(using: .utf8)!)
    }

}

//https://stackoverflow.com/questions/32313938/parsing-csv-file-in-swift
struct Csv {
    var Time: String
    var Value: Double
}


//https://programmingwithswift.com/numbers-only-textfield-with-swiftui/
//https://stackoverflow.com/questions/32814779/check-if-input-is-float-in-swift
//https://stackoverflow.com/questions/47232491/how-to-filter-characters-from-a-string-in-swift-4s
class InputsForDetect: ObservableObject {
    @Published var alpha = "0.05" {
        didSet {
            
            let filtered = alpha.filter { "0123456789.".contains($0) }//{ $0.isNumber }
          
            if alpha != filtered {
                alpha = filtered
            }
             
        }
    }
    @Published var max_anoms = "0.2" {
        didSet {
            let filtered = max_anoms.filter { "0123456789.".contains($0) }//{ $0.isNumber }
          
            if max_anoms != filtered {
                max_anoms = filtered
            }
            
            
        }
        
    }
    @Published var period = "7" {
        didSet {
            let filtered = period.filter { "0123456789".contains($0) }//{ $0.isNumber }
          
            if period != filtered {
               period = filtered
            }
            
            
        }
        
    }
    
    
    
    
    
    
}



struct ContentView: View {
    
    let symbolSize: CGFloat = 200
    let lineWidth: CGFloat = 3
    @State private var document: InputDoument = InputDoument(input: "")
    @State private var documentold: InputDoument = InputDoument(input: "")//.input
    @State private var isImporting: Bool = false
    //@State private var csv: [Csv] = [Csv]()
    @State private var series: [Double] = [Double]()
    @State private var anomLocations: [user_size_t] = [user_size_t]()
    @State private var Anomslist: [Double] = [Double]() //puts the actual anom values here
    
    @State private var alpha_old: Double = 0.05
    @State private var period_old: user_size_t = 7
    @State private var max_anoms_old: Double = 0.2
    @State private var direction_old: String = "Both"
    
    
    @ObservedObject var input = InputsForDetect()
    //https://codingwithrashid.com/how-to-create-dropdown-menu-using-picker-in-ios-swiftui/
    @State private var selectedDirection = "Both"
    //https://www.hackingwithswift.com/quick-start/swiftui/how-to-fix-cannot-assign-to-property-self-is-immutable
    @State var DatatoDisplay: [AnomData.Series] = AnomData.firstAnoms
    let directions = ["Both", "Positive", "Negative"]
    
    var body: some View {
        HStack {
                    Button(action: { isImporting = true}, label: {
                        Text("Select Data File")
                    })
                    //Text(document.input)
        }.padding().fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                if selectedFile.startAccessingSecurityScopedResource() {
                    guard let input = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    document.input = input
                } else {
                    // Handle denied access
                }
            } catch {
                // Handle failure.
                print("Unable to read file contents")
                print(error.localizedDescription)
            }
        }
        
        VStack {
            Chart {
                ForEach(DatatoDisplay) { series in
                    ForEach(series.data, id: \.time) { element in
                        LineMark(
                            x: .value("Time", element.time),
                            y: .value("Value", element.data)
                        )//.lineStyle(StrokeStyle(lineWidth: 0))
                        .foregroundStyle(by: .value("Color", element.color))
                        .lineStyle(by: .value("Color", element.color))
                        
                        
                    }
                    //.foregroundStyle(by: .value("Test", series.name))
                    .symbol(by: .value(series.name, series.name))
                }
                
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 0))
                .symbolSize(symbolSize)
            }.chartSymbolScale([
                DatatoDisplay[0].name: Circle().strokeBorder(lineWidth: lineWidth),
            ])
            .chartForegroundStyleScale([
                //"Test": .blue,
                "Anom": .red,
                "Value": .blue,
            ])
            Text("The Anomalies are: \(Anomslist)")
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint).padding()
            #if os(macOS)
            //https://stackoverflow.com/questions/70122838/set-width-of-textfield-in-swiftui
            //https://stackoverflow.com/questions/58103186/how-can-i-get-data-from-observedobject-with-onreceive-in-swiftui
            //https://developermemos.com/posts/on-receive-modifier-swiftui
            Text("Alpha")
            TextField("Alpha", text: $input.alpha).frame(width: 200).multilineTextAlignment(.center)
            Text("Max Anoms")
            TextField("Max Anoms", text: $input.max_anoms).frame(width: 200).multilineTextAlignment(.center)
            Text("Period")
            TextField("Period", text: $input.period).frame(width: 200).multilineTextAlignment(.center)
            Text("Direction")
            Picker("Select a Direction", selection: $selectedDirection) {
                        ForEach(directions, id: \.self) {
                            Text($0)
                        }
                    }.frame(width: 200).multilineTextAlignment(.center)
     
            #else
            ScrollView {
                //https://stackoverflow.com/questions/70122838/set-width-of-textfield-in-swiftui
                //https://stackoverflow.com/questions/58103186/how-can-i-get-data-from-observedobject-with-onreceive-in-swiftui
                //https://developermemos.com/posts/on-receive-modifier-swiftui
                Text("Alpha")
                TextField("Alpha", text: $input.alpha).frame(width: 500).multilineTextAlignment(.center).keyboardType(.decimalPad)
                Text("Max Anoms")
                TextField("Max Anoms", text: $input.max_anoms).frame(width: 500).multilineTextAlignment(.center).keyboardType(.decimalPad)
                Text("Period")
                TextField("Period", text: $input.period).frame(width: 500).multilineTextAlignment(.center).keyboardType(.decimalPad)
                Text("Direction")
                Picker("Select a Direction", selection: $selectedDirection) {
                    ForEach(directions, id: \.self) {
                        Text($0)
                    }
                }.frame(width: 500).multilineTextAlignment(.center)
                    .padding()
            }.scrollDismissesKeyboard(.interactively)
            #endif
                
                       
        }.onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { _ in
            var series = [Double]()
            var timeSeries = [String]()
            var CsvArray = [Csv]()
            
           
            
            
          
    
            
            let alpha = $input.alpha
            let max_anoms = $input.max_anoms
            let period = $input.period
            let direction = $selectedDirection
            //var res AnomalyDetector
            //add check to see if value same as previous before running anom detect to save cpu
            
            if Double(alpha.wrappedValue) ?? 0.05 != alpha_old || Double(max_anoms.wrappedValue) ?? 0.2 != max_anoms_old || user_size_t(period.wrappedValue) ?? 7 != period_old || direction.wrappedValue != direction_old || document.input != documentold.input {
                //https://stackoverflow.com/questions/32313938/parsing-csv-file-in-swift
                if document.input != "" || document.input != documentold.input {
                    let rows = $document.input.wrappedValue.components(separatedBy: "\n")
                    //print(rows)
                    
                    for row in rows {
                        let columns = row.components(separatedBy: ",")
                        if columns.count == 2 {
                            let Time = columns[0]
                            let Value = Double(columns[1].filter { "0123456789.-".contains($0) }) ?? 0.0
                            
                            let csv = Csv(Time: Time, Value: Value)
                            CsvArray.append(csv)
                            
                        }
                        
                        
                    }
                    
                    for i in CsvArray.indices {
                        series.append(CsvArray[i].Value)
                        timeSeries.append(CsvArray[i].Time)
                    }
                    documentold.input = document.input
                    
                    
                    
                } else {
                
                    series = [5.0, 9.0, 2.0, 9.0, 0.0, 6.0, 3.0, 8.0, 5.0, 18.0,
                              7.0, 8.0, 8.0, 0.0, 2.0, -5.0, 0.0, 5.0, 6.0, 7.0,
                              3.0, 6.0, 1.0, 4.0, 4.0, 4.0, 30.0, 7.0, 5.0, 8.0]
                }
                
                
                var res = [user_size_t]()
                Anomslist = [Double]()
                
                var graphTemp = [AnomData.Series(name: "Graph", data: [])]
                
                
                var time = 1
                if timeSeries.isEmpty {
                    for i in series.indices {
                        graphTemp[0].data.append((color: "Value", time: String(time), data: series[i])) //timeSeries[i]
                        time += 1
                    }
                } else {
                    for i in series.indices {
                        graphTemp[0].data.append((color: "Value", time: timeSeries[i], data: series[i])) //timeSeries[i]
                        time += 1
                    }
                }
                
                
                
                
                
                do {
                    res = try AnomalyDetector(alpha: Double(alpha.wrappedValue) ?? 0.05, max_anoms: Double(max_anoms.wrappedValue) ?? 0.2, direction: direction.wrappedValue, verbose: false).fit(series: series, period: user_size_t(period.wrappedValue) ?? 7)
                //print(res)
                    
                } catch {
                print("Could not resolve")
                
                }
                
               
                
                for i in res {
                    graphTemp[0].data[Int(i)].color = "Anom"
                    Anomslist.append(series[Int(i)])
                }
                
              
             
                
                DatatoDisplay = graphTemp
                
                
                alpha_old = Double(alpha.wrappedValue) ?? 0.05
                max_anoms_old = Double(max_anoms.wrappedValue) ?? 0.2
                period_old = user_size_t(period.wrappedValue) ?? 7
                direction_old = direction.wrappedValue
                
             
                
                
            }
            
            
            
            
            
        }
        .padding()
    }
    
}
//https://www.hackingwithswift.com/example-code/language/how-to-conform-to-the-equatable-protocol
class AnomData {
    
    
    
    struct Series: Identifiable {
        //https://developer.apple.com/documentation/charts/creating-a-chart-using-swift-charts
        
        var name: String
        var data: [(color: String, time: String, data: Double)]
        
        var id: String { name }
        
        
    }
  
    
    static let firstAnoms: [Series] = [
        .init(name: "Test", data: [
            (color: "Value", time: "1", data: 5.0),
            (color: "Value", time: "2", data: 9.0),
            (color: "Value", time: "3", data: 2.0),
            (color: "Value", time: "4", data: 9.0),
            (color: "Value", time: "5", data: 0.0),
            (color: "Value", time: "6", data: 6.0),
            (color: "Value", time: "7", data: 3.0),
            (color: "Value", time: "8", data: 8.0),
            (color: "Value", time: "9", data: 5.0),
            (color: "Anom", time: "10", data: 18.0),
            (color: "Value", time: "11", data: 7.0),
            (color: "Value", time: "12", data: 8.0),
            (color: "Value", time: "13", data: 8.0),
            (color: "Value", time: "14", data: 0.0),
            (color: "Value", time: "15", data: 2.0),
            (color: "Anom", time: "16", data: -5.0),
            (color: "Value", time: "17", data: 0.0),
            (color: "Value", time: "18", data: 5.0),
            (color: "Value", time: "19", data: 6.0),
            (color: "Value", time: "20", data: 7.0),
            (color: "Value", time: "21", data: 3.0),
            (color: "Value", time: "22", data: 6.0),
            (color: "Value", time: "23", data: 1.0),
            (color: "Value", time: "24", data: 4.0),
            (color: "Value", time: "25", data: 4.0),
            (color: "Value", time: "26", data: 4.0),
            (color: "Anom", time: "27", data: 30.0),
            (color: "Value", time: "28", data: 7.0),
            (color: "Value", time: "29", data: 5.0),
            (color: "Value", time: "30", data: 8.0),
        
        ]
             
             )]
    
    
}


/*
 #Preview {
 ContentView()
 .padding()
 }
 */
