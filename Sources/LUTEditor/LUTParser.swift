//
//  File.swift
//  
//
//  Created by Suren Hakobyan on 4/30/20.
//

import Foundation

public class LUTParser {

    typealias TableRow = [Float]
    typealias Table1D = [TableRow]
    typealias Table2D = [Table1D]
    typealias Table3D = [Table2D]
    
    enum LUTError: String, Error {
        case nonCompliantLineSeparator = "This file uses non-compliant line separator."
        case incorrectTitleFormat = "Incorrect Title Format."
        case incorrectValueFormat = "Incorrect value Format."
        case sizeOutOfRange = "Size out of range."
        case domainBoundsReversed = "Domain bounds reserved."
        case notSupportedSize = "Size not supported"
    }
    
    let lutString: String
    
    var title: String?
    var domainMin: TableRow = [0.0, 0.0, 0.0]
    var domainMax: TableRow = [1.0, 1.0, 1.0]
    var lut1D: Table1D?
    var lut3D: Table3D?
    
    // read keywords
    var titleCount = 0
    var sizeCount = 0
    var minCount = 0
    var maxCount = 0
    
    // MARK: Initializers
    
    public init(url: URL) throws {
        lutString = try String(contentsOf: url, encoding: String.Encoding.utf8)
        try parse()
    }
    
    // MARK: Public methods
    
    public func generateLutModel() throws -> LUTModel {
        var cubeData: [Float]!
        let size: Int!
        var offset = 0
        
        
        if  let lut1D = lut1D {
            size = lut1D.count
            cubeData = [Float](repeating: 0, count: size * 4)
            for i in 0..<lut1D.count {
                var red = lut1D[i][0]
                var green = lut1D[i][1]
                var blue = lut1D[i][2]
                let alpha: Float = 1.0
                
                red = (red - domainMin[0]) / (domainMax[0] - domainMin[0]);
                green = (green - domainMin[1]) / (domainMax[1] - domainMin[1]);
                blue = (blue - domainMin[2]) / (domainMax[2] - domainMin[2]);
                
                cubeData[offset]   = red
                cubeData[offset+1] = green
                cubeData[offset+2] = blue
                cubeData[offset+3] = alpha
                offset += 4
            }
        } else if let lut3D = lut3D {
            size = lut3D.count
            cubeData = [Float](repeating: 0, count: size * size * size * 4)
            for b in 0..<lut3D.count {
                for g in 0..<lut3D.count  {
                    for r in 0..<lut3D.count {
                        var red = lut3D[r][g][b][0]
                        var green = lut3D[r][g][b][1]
                        var blue = lut3D[r][g][b][2]
                        let alpha: Float = 1.0
                        
                        red = (red - domainMin[0]) / (domainMax[0] - domainMin[0]);
                        green = (green - domainMin[1]) / (domainMax[1] - domainMin[1]);
                        blue = (blue - domainMin[2]) / (domainMax[2] - domainMin[2]);
                        
                        cubeData[offset]   = red
                        cubeData[offset+1] = green
                        cubeData[offset+2] = blue
                        cubeData[offset+3] = alpha
                        offset += 4
                    }
                }
            }
        } else {
            throw LUTError.notSupportedSize
        }
        
        return LUTModel(data: NSData(bytes: cubeData, length: cubeData.count * MemoryLayout<Float>.size), dimension:size)
    }
    
    // MARK: Private methods
    
    private func parse() throws {
        guard let seperator = detectLineSeperator() else { throw LUTError.nonCompliantLineSeparator }
        let lines = lutString.components(separatedBy: seperator)

        let commentMarker: Character = "#"
        let quoteMarker: Character = "\"";
        
        var tableIndex = 0
        
        for i in 0..<lines.count {
            let line = lines[i]
            
            if line.isEmpty { continue; } // skip blanks
            
            let firstChar = line.first!
            
            if firstChar == commentMarker { continue } // skip comments
            
            // lines of table data come after keywords
            if "+" < firstChar && firstChar < ":" {
                tableIndex = i
                break
            }
            
            if let range = line.range(of: "TITLE" + " "), titleCount == 0 {
                let withoutKeyword = line[range.upperBound...]
                guard let firstIndex = withoutKeyword.firstIndex(of: quoteMarker), let lastIndex = withoutKeyword.lastIndex(of: quoteMarker) else {
                    throw LUTError.incorrectTitleFormat
                }
                
                title = String(line[line.index(after: firstIndex)..<lastIndex])
                titleCount += 1
            } else if let range = line.range(of: "DOMAIN_MIN" + " "), minCount == 0  {
                let withoutKeyword = line[range.upperBound...]
                
                try parse(raw: &domainMin, from: String(withoutKeyword))
                minCount += 1
            } else if let range = line.range(of: "DOMAIN_MAX" + " "), maxCount == 0  {
                let withoutKeyword = line[range.upperBound...]
                
                try parse(raw: &domainMax, from: String(withoutKeyword))
                maxCount += 1
            } else if let range = line.range(of: "LUT_1D_SIZE" + " "), sizeCount == 0  {
                let withoutKeyword = line[range.upperBound...]
                
                guard let number = Int(withoutKeyword), number > 2, number < 65536 else {
                    throw LUTError.sizeOutOfRange
                }
                
                let row = TableRow(repeating: 0.0, count: 3)
                lut1D = Table1D(repeating: row, count: number)
                sizeCount += 1
                
            } else if let range = line.range(of: "LUT_3D_SIZE" + " "), sizeCount == 0  {
                let withoutKeyword = line[range.upperBound...]
                
                guard let number = Int(withoutKeyword), number > 2, number < 256 else {
                    throw LUTError.sizeOutOfRange
                }
                
                let row = TableRow(repeating: 0.0, count: 3)
                let table1D = Table1D(repeating: row, count: number)
                let table2D = Table2D(repeating: table1D, count: number)
                lut3D = Table3D(repeating: table2D, count: number)
                sizeCount += 1
            }
        }
            
        guard sizeCount > 0 else { throw LUTError.sizeOutOfRange }
        guard domainMin[0] <= domainMax[0], domainMin[1] <= domainMax[1], domainMin[2] <= domainMax[2] else { throw LUTError.domainBoundsReversed }
            
        if lut1D != nil {
            for (x, _) in lut1D!.enumerated() {
                let line = lines[tableIndex]
                try parse(raw: &lut1D![x], from: line)
                tableIndex += 1
            }
        } else if lut3D != nil {
            for (b, _) in lut3D!.enumerated() {
                for (g, _) in lut3D![b].enumerated() {
                    for (r, _) in lut3D![b][g].enumerated() {
                        let line = lines[tableIndex]
                        try parse(raw: &lut3D![r][g][b], from: line)
                        tableIndex += 1
                    }
                }
            }
        } else {
            throw LUTError.sizeOutOfRange
        }
    }
    
    private func parse(raw: inout TableRow, from string:String) throws {
        let numbers = string.components(separatedBy: " ")
        assert(numbers.count == 3)
        for i in 0..<3 {
            guard let value = Float(numbers[i]) else { throw LUTError.incorrectValueFormat}
            raw[i] = value
        }
    }
    
    private func detectLineSeperator() -> String? {
        
        let newLineSeperator = "\n"
        let carriageReturnSeperator = "\r"
        let newLineCarriageReturnSeperator = "\r\n"
        for i in 0..<255 {
            let character = lutString[lutString.index(lutString.startIndex, offsetBy: i)]
            if character == newLineSeperator.first { return newLineSeperator }
            if character == carriageReturnSeperator.first { return carriageReturnSeperator }
            if character == newLineCarriageReturnSeperator.first { return newLineCarriageReturnSeperator }
        }
        return nil
    }
}
