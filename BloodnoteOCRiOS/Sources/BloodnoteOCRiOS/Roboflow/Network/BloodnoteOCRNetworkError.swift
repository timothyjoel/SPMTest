//
//  BloodnoteOCRNetworkError.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 14/12/2022.
//

import Foundation

public enum BloodnoteOCRNetworkError: Error {
    
    public typealias StatusCode = Int
    case encoding(Error)
    case error(for: StatusCode)
    case decoding(Error)
    case urlError(URLError)
    case unknown
}
