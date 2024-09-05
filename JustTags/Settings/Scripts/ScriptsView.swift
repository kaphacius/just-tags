//
//  ScriptsView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/06/2024.
//

import SwiftUI

struct ScriptsView: View {
    
    @State var shell: String = ""
    @State var script: String = "foo bar"
    
    var body: some View {
        VStack {
            HStack {
                Text("shell")
                TextField("", text: $shell, prompt: Text("/bin/sh"))
            }
            
            TextEditor(text: $script)
                .monospaced()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("run") {
                run()
            }
        }
        .padding()
        .frame(width: 600.0, height: 450.0)
    }
    
    private func run() {
        do {
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c", script]
            task.launchPath = shell
            task.standardInput = nil
            task.launch()
            
            print("launch")
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)!
            
            print("output", output)
        } catch {
            print(error)
        }
    }
}

#Preview {
    ScriptsView()
}
