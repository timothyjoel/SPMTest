//
//  RecognizedDigit.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 13/12/2022.
//

import Foundation

public struct RecognizedDigit: Codable, Equatable {
    
    public var x, y: Double
    public var width, height: Int
    public var predictionClass: String
    public var confidence: Double
    
    public var xAndWidth: Double {
        Double(width) + x
    }
    
    public var yAndHeight: Double {
        Double(height) + y
    }

    public enum CodingKeys: String, CodingKey {
        case x, y, width, height
        case predictionClass = "class"
        case confidence
    }
    
}
