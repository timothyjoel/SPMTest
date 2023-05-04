//
//  PredictionResponse.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 13/12/2022.
//

import Foundation

public struct RecognitionResponse: Codable {
    public var predictions: [RecognizedDigit]
    public let image: ImageData
}
