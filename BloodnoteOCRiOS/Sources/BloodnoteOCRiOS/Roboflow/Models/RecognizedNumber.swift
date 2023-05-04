//
//  RecognizedNumber.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 13/12/2022.
//

import Foundation

public struct RecognitionNumber {
    
    let number: Int
    let x, y, height, width: Double
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case x, y
        case predictionClass = "class"
        case confidence
    }
    
}
