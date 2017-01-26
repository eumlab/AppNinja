//
//  Parser.swift
//  AppNinja
//
//  Created by YuanZhou on 5/10/15.
//  Copyright (c) 2015 EUMLab. All rights reserved.
//

import Foundation

open class Parser {
    open var headers: [String] = []
    open var rows: [Dictionary<String, String>] = []
    open var columns = Dictionary<String, [String]>()
    var delimiter = CharacterSet(charactersIn: ",")
    
    public init(contentsOfURL url: URL, delimiter: CharacterSet) throws {
        let csvString: String?
        do {
            csvString = try String(contentsOf: url, encoding: String.Encoding.utf8)
        } catch _ {
            csvString = nil
        };
        if let csvStringToParse = csvString {
            self.delimiter = delimiter
            
            let newline = CharacterSet.newlines
            var lines: [String] = []
            csvStringToParse.trimmingCharacters(in: newline).enumerateLines { line, stop in lines.append(line) }
            
            self.headers = self.parseHeaders(fromLines: lines)
            self.rows = self.parseRows(fromLines: lines)
            self.columns = self.parseColumns(fromLines: lines)
        }
    }
    
    public convenience init(contentsOfURL url: URL) throws {
        let comma = CharacterSet(charactersIn: ",")
        try self.init(contentsOfURL: url, delimiter: comma)
    }
    
    func parseHeaders(fromLines lines: [String]) -> [String] {
        return lines[0].components(separatedBy: self.delimiter)
    }
    
    func parseRows(fromLines lines: [String]) -> [Dictionary<String, String>] {
        var rows: [Dictionary<String, String>] = []
        
        for (lineNumber, line) in lines.enumerated() {
            if lineNumber == 0 {
                continue
            }
            
            var row = Dictionary<String, String>()
            let values = line.components(separatedBy: self.delimiter)
            for (index, header) in self.headers.enumerated() {
                let value = values[index]
                row[header] = value
            }
            rows.append(row)
        }
        
        return rows
    }
    
    func parseColumns(fromLines lines: [String]) -> Dictionary<String, [String]> {
        var columns = Dictionary<String, [String]>()
        
        for header in self.headers {
            let column = self.rows.map { row in row[header]! }
            columns[header] = column
        }
        
        return columns
    }

}
