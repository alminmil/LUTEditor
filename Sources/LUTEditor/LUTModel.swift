//
//  File.swift
//  
//
//  Created by Suren Hakobyan on 5/7/20.
//

import Foundation

public struct LUTModel {
    
    public let data: NSData
    public let dimension: Int
    
    public init(data: NSData, dimension: Int){
        self.data = data
        self.dimension = dimension
    }
}
