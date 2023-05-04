//
//  RecognitionThreshold.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 16/12/2022.
//

import Foundation

struct RecognitionThresholds {
    
    static var minimumConfidence: Double {
        0.4
    }
    
    static var minimumConfidenceForOne: Double {
        0.35
    }
    
    static var minimumYChangeToDefineNewRow: Double {
        30
    }

    static var defaultImageHeight: Double  {
        650
    }
    
    static var photoBrightness: Double {
        0.2
    }
    
    static var photoContrast: Double {
        2.0
    }
    
    // For detecting new number in row on height digits difference
    static var minimumHeightDifferenceMultiplier: Double {
        0.2
    }
    
    // For detecting new number in row on space after last digit
    static var minimumWidthDifferenceMultiplier: Double {
        0.9
    }
    
}
