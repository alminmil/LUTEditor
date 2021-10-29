import XCTest
@testable import LUTEditor

struct Resource {
    let name: String
    let type: String
    let url: URL

    init(name: String, type: String, sourceFile: StaticString = #file, sub: String? = nil) throws {
        self.name = name
        self.type = type

        // The following assumes that your test source files are all in the same directory, and the resources are one directory down and over
        // <Some folder>
        //  - Resources
        //      - <resource files>
        //  - <Some test source folder>
        //      - <test case files>
        let testCaseURL = URL(fileURLWithPath: "\(sourceFile)", isDirectory: false)
        let testsFolderURL = testCaseURL.deletingLastPathComponent()
        let pathComponent = (sub == nil ? "Resources": "Resources/" + sub!)
        let resourcesFolderURL = testsFolderURL.deletingLastPathComponent().appendingPathComponent(pathComponent, isDirectory: true)
        self.url = resourcesFolderURL.appendingPathComponent("\(name).\(type)", isDirectory: false)
    }
}

final class LUTParserTests: XCTestCase {
    
    func testParseNahSuccess() {
        let file = try! Resource(name: "Nah", type: "CUBE", sub: "Cubes")
        let url = file.url
        let parser = try! LUTParser(url: url)
        
        XCTAssertTrue(parser.titleCount == 1)
        XCTAssertTrue(parser.title == "Nah")
        
        XCTAssertTrue(parser.minCount == 1)
        XCTAssertTrue(parser.domainMin.count == 3)
        
        for i in 0..<3 {
            XCTAssertTrue(parser.domainMin[i] == 0.0)
        }
        
        XCTAssertTrue(parser.maxCount == 1)
        XCTAssertTrue(parser.domainMax.count == 3)
        
        for i in 0..<3 {
            XCTAssertTrue(parser.domainMax[i] == 1.0)
        }
        
        XCTAssertNotNil(parser.lut3D)
        XCTAssertTrue(parser.lut3D!.count == 32)
        
        let raw = parser.lut3D![0][0][0]
        XCTAssert(raw[0] == 0.177521)
        XCTAssert(raw[1] == 0.141174)
        XCTAssert(raw[2] == 0.182068)
    }
    
    func testParse1DSuccess() {
        let file = try! Resource(name: "Rec.709 to Linear", type: "cube", sub: "Cubes")
        let url = file.url
        let parser = try! LUTParser(url: url)
        
        XCTAssertNil(parser.title)
        
//        XCTAssertTrue(parser.minCount == 1) domain max and min are missing in this lut
        XCTAssertTrue(parser.domainMin.count == 3)
        
        for i in 0..<3 {
            XCTAssertTrue(parser.domainMin[i] == 0.0)
        }
        
//        XCTAssertTrue(parser.maxCount == 1) domain max and min are missing in this lut
        XCTAssertTrue(parser.domainMax.count == 3)
        
        for i in 0..<3 {
            XCTAssertTrue(parser.domainMax[i] == 1.0)
        }
        
        XCTAssertNotNil(parser.lut1D)
        XCTAssertTrue(parser.lut1D!.count == 4096)
        
        let raw = parser.lut1D![0]
        XCTAssert(raw[0] == 0.0)
        XCTAssert(raw[1] == 0.0)
        XCTAssert(raw[2] == 0.0)
    }

    static var allTests = [
        ("testParseSuccess", testParseNahSuccess),
    ]
}
