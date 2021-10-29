import XCTest
@testable import LUTEditor

final class LUTEditorTests: XCTestCase {
    
    let generateOutput = false
    
    func testPalmaNahExample() {
        test(image: "palma", imageExtension: "jpg", cube: "Nah", cubeExtension: "CUBE")
    }
    
    func testFlowerCustomExample() {
        test(image: "flower", imageExtension: "png", customData: customFilterData(), dimension: 2)
    }
    
    func testPhotoCustomExample() {
        test(image: "photo", imageExtension: "jpg", customData: customFilterData(), dimension: 2)
    }
    
    func testPhotoCowboyExample() {
        test(image: "photo", imageExtension: "jpg", cube: "Urban cowboy", cubeExtension: "CUBE")
    }
    
    func testPhotoKodakExample() {
        test(image: "photo", imageExtension: "jpg", cube: "DCI-P3 Kodak 2383 D60", cubeExtension: "cube")
    }
    
    func testRusminKodakExample() {
        test(image: "Rusmin", imageExtension: "jpg", cube: "DCI-P3 Kodak 2383 D60", cubeExtension: "cube")
    }

    func testFlowerKodakExample() {
        test(image: "flower", imageExtension: "png", cube: "DCI-P3 Kodak 2383 D60", cubeExtension: "cube")
    }
    
//    func testFlower1DLutExample() { // Lut 1D currently not supported
//        test(image: "flower", imageExtension: "png", cube: "Rec.709 to Linear", cubeExtension: "cube")
//    }
    
//    func testFlowerLinerToSRGBExample() {
//        test(image: "flower", imageExtension: "png", cube: "Linear to sRGB", cubeExtension: "cube")
//    }
    
    private func test(image: String, imageExtension: String, cube: String, cubeExtension: String) {
        let sourceImageFile = try! Resource(name: image, type: imageExtension, sub: "Images")
        let sourceCIImage = CIImage(contentsOf: sourceImageFile.url)!
        
        let cubeFile = try! Resource(name: cube, type: cubeExtension, sub: "Cubes")
        let parser = try! LUTParser(url: cubeFile.url)
        
        let editor = LUTEditor()
        
        guard let lut = try? parser.generateLutModel() else {
            XCTAssert(false)
            return
        }
        
        let filter = editor.filterFor3DLut(data: lut.data, dimension: lut.dimension)
        guard let filteredImage = editor.applyFilter(image: sourceCIImage, filter: filter) else {
            XCTAssert(false)
            return
        }
        let outputImage = UIImage(ciImage: filteredImage)
        let outputImageData = outputImage.pngData()
        
        let destinationImageFile = try! Resource(name: image + "_" + cube, type: imageExtension, sub: "Output")
        if generateOutput { try! outputImageData?.write(to: destinationImageFile.url) }
        let destinationImageData = try! Data(contentsOf: destinationImageFile.url)
        XCTAssert(outputImageData == destinationImageData)
    }
    
    private func test(image: String, imageExtension: String, customData: NSData, dimension: Int) {
        let sourceImageFile = try! Resource(name: image, type: imageExtension, sub: "Images")
        let sourceCIImage = CIImage(contentsOf: sourceImageFile.url)!
        
        let editor = LUTEditor()
        let filter = editor.filterFor3DLut(data: customData, dimension: dimension)
        guard let filteredImage = editor.applyFilter(image: sourceCIImage, filter: filter) else {
            XCTAssert(false)
            return
        }
        let outputImage = UIImage(ciImage: filteredImage)
        XCTAssertNotNil(outputImage)
        
        let outputImageData = outputImage.pngData()
        
        let destinationImageFile = try! Resource(name: image + "_custom", type: imageExtension, sub: "Output")
        if generateOutput { try! outputImageData?.write(to: destinationImageFile.url) }
        let destinationImageData = try! Data(contentsOf: destinationImageFile.url)
        
        XCTAssert(outputImageData == destinationImageData)
    }
    
    private func customFilterData() -> NSData {
        let cubeData: [Float] = [0, 0, 0, 1,
        0.1, 0, 1, 1,
        0, 1, 0, 1,
        1, 1, 0, 1,
        0, 0, 1, 1,
        1, 0, 1, 1,
        0, 1, 1, 1,
        1, 1, 1, 1]
        return NSData(bytes: cubeData, length: cubeData.count * MemoryLayout<Float>.size)
    }
    
    static var allTests = [
        ("testNahExample", testPalmaNahExample),
    ]
}
