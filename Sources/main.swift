//
//  File.swift
//  
//
//

import Foundation

let validOptions = ["l", "w", "c", "L", "m"]
var flags: [String] = []
var files: Array<String>.SubSequence = []
let fileManager = FileManager.default
var totalBytes = 0
var totalWords = 0
var totalLines = 0
var totalMaxLine = 0
var totalChars = 0

func setDefaults() {
    flags = Array(validOptions.prefix(3))
    if CommandLine.arguments.count > 1 && CommandLine.arguments[1].first != "-" {
        files = CommandLine.arguments.suffix(from: 1)
    }
}

if CommandLine.arguments.count > 1 {
    if CommandLine.arguments[1].first == "-" {
        for c in CommandLine.arguments[1].dropFirst() {
            if !validOptions.contains(String(c)) {
                print("wc: illegal option -- \(c)")
                print("usage: wc [-Lclmw] [file ...]")
                exit(-1)
            } else {
                flags.append(String(c))
            }
        }
        files = CommandLine.arguments.suffix(from: 2)
    } else {
        setDefaults()
    }
}
else {
    setDefaults()
}

let showLines = flags.contains("l")
let showWords = flags.contains("w")
let showBytes = flags.contains("c")
let showLongestLine = flags.contains("L")
let showChars = flags.contains("m")
var showTotals = false

if (files.count == 0) {
    let inputHandle = FileHandle.standardInput
    if var inputData = inputHandle.availableData as Data? {
        while true {
            if #available(macOS 10.15.4, *) {
                let chunk = try inputHandle.read(upToCount: 1024)
                if (chunk == nil) {
                    break
                }
                inputData.append(chunk!)
            } else {
                // Fallback on earlier versions
            }
        }
        let _ = wordCount(fileName: "input", inputData)
    }
}

func printCounts(_ fileName: String, lines:Int, words:Int, bytes:Int, maxLine: Int) {
    if showLines {
        print("\(String(format: "%8d", lines))", terminator: "")
    }
    if showWords {
        print("\(String(format: "%8d", words))", terminator: "")
    }
    if showBytes {
        print("\(String(format: "%8d", bytes))", terminator: "")
    }
    if showLongestLine {
        print(" \(String(format: "%8d", maxLine))", terminator: "")
    }
    print(" \(fileName)", terminator: "\n")
}

for index in files.indices {
    let fileName = files[index]
    if (fileManager.fileExists(atPath: fileName)) {
        if let data = fileManager.contents(atPath: fileName) {
            totalBytes += data.count
            let lines = wordCount(fileName: fileName, data)
            showTotals = totalLines > lines
        }
    } else {
        print("wc: \(fileName): open: No such file or directory")
    }
}

func wordCount(fileName: String, _ data: Data) -> Int {
    let bytes = data.count
    let fileContent = String(data: data, encoding: .utf8)!
    var lines = 0
    var words = 0
    var maxLine = 0
    
    if (showWords) {
        let wordsInFile = fileContent.components(separatedBy: .whitespacesAndNewlines)
        let nonEmptyWords = wordsInFile.filter { !$0.isEmpty }
        words = nonEmptyWords.count
        totalWords += words
    }
    if (showLines || showLongestLine) {
        let fileLines = fileContent.components(separatedBy: .newlines)
        lines = fileLines.count - 1
        totalLines += lines
        if let longestLine = fileLines.max(by: { $0.count < $1.count }) {
            maxLine = longestLine.count
            totalMaxLine = max(totalMaxLine, maxLine)
        }
    }
    
    printCounts(fileName, lines: lines, words: words, bytes: bytes, maxLine: maxLine)
    return lines
}

if (showTotals) {
    printCounts("total", lines: totalLines, words: totalWords, bytes: totalBytes, maxLine: totalMaxLine)
}
