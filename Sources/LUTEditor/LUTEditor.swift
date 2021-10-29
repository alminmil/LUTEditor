//
//  File.swift
//
//
//  Created by Suren Hakobyan on 4/30/20.
//

import Foundation
import UIKit

public class LUTEditor {
    
    public init() {}
    
    public func filterFor3DLut(data: NSData, dimension: Int) -> CIFilter {
        let colorCube = CIFilter(name: "CIColorCubeWithColorSpace")!
        colorCube.setValue(dimension, forKey: "inputCubeDimension")
        colorCube.setValue(data, forKey: "inputCubeData")
        return colorCube
    }
    
    public func applyFilter(image: CIImage, filter: CIFilter) ->  CIImage? {
        filter.setValue(image, forKey: kCIInputImageKey)
        let colorSpace = image.cgImage?.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        filter.setValue(colorSpace, forKey: "inputColorSpace")
        return filter.outputImage
    }
    
    private func apply1DLutFilter(image: UIImage, data: NSData, dimension: Int) ->  UIImage?{
        //currently we are not supporting 1D Lut filter functionality.
        return nil
    }
}
