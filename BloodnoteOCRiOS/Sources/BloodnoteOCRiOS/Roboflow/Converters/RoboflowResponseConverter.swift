//
//  RoboflowResponseConverter.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 14/12/2022.
//

import Foundation
import os.log

protocol RoboflowResponseConverterProtocol {
    func convert(_ response: RecognitionResponse) -> OCRResult?
}

class RoboflowResponseConverter: RoboflowResponseConverterProtocol  {
    
    public func convert(_ response: RecognitionResponse) -> OCRResult? {
        let filteredData = filteredByConfidence(response)
        let rows = createRows(from: filteredData)
        let numbers = createNumbersFromRows(rows)
        let result = createResultObject(from: numbers)
        return result
    }
    
    private func createResultObject(from numbers: [RecognitionNumber]) -> OCRResult?  {
        guard numbers.count >= 3 else { return nil }
        guard numbers[0].number > numbers[1].number else { return nil }
        let sys = numbers[0].number
        let dia = numbers[1].number
        let pulse = numbers[2].number
        return OCRResult(sys: sys, dia: dia, pulse: pulse)
    }
    
    private func filteredByConfidence(_ response: RecognitionResponse) -> [RecognizedDigit] {
        return response.predictions.filter({
            // 1 seems to have slightly lower results
            if $0.predictionClass == "1" {
                return $0.confidence >= RecognitionThresholds.minimumConfidenceForOne
            } else {
                return $0.confidence >= RecognitionThresholds.minimumConfidence
            }
        })
    }
    
    private func createRows(from filteredData: [RecognizedDigit]) -> [[RecognizedDigit]] {
        var rows = [[RecognizedDigit]]()
        filteredData.forEach { prediction in
            if let row = rows.firstIndex(where: { recognizedRow in
                recognizedRow.contains { assignedPrediction in
                    // Prerequisite to check whether digit is in same row as existing one
                    abs(prediction.y - assignedPrediction.y) <= CGFloat(RecognitionThresholds.minimumYChangeToDefineNewRow)
                }
            }) {
                rows[row].append(prediction) // Append exising recognized row
            } else {
                rows.append([prediction]) // Start new row
            }
        }
        return sortedByY(rows)
    }
    
    private func createNumbersFromRows(_ rows: [[RecognizedDigit]]) -> [RecognitionNumber] {
        let definedNumbers = createNumbersAsDigitsArraysFromDigits(rows)
        let numbersAsDigits = filteredForSameSpotRecognition(definedNumbers)
        let numbers = createNumbersFromDigits(numbersAsDigits)
        let threeDisplayableNumbers = filteredForThreeLargestNumbers(numbers)
        let finalNumbers = threeDisplayableNumbers.map { $0.number > 300 ? RecognitionNumber(number: $0.number / 10, x: $0.x, y: $0.y, height: $0.height, width: $0.width, confidence: $0.confidence) : $0 }

        return finalNumbers
    }

    private func createNumbersFromDigits(_ numbersAsDigits: [[RecognizedDigit]]) -> [RecognitionNumber] {
        let numbers: [RecognitionNumber] = numbersAsDigits.map { obtainedDigits in
            var digits = obtainedDigits
            if digits.count >= 3 && digits.first?.predictionClass == "4" {
                digits[0].predictionClass = "1"
            }
            let predictedNumber = Int(digits.map { $0.predictionClass }.reduce("", +)) ?? 0
            let x = digits.first?.x ?? 0
            let y = digits.first?.y ?? 0
            let width = digits.map( { Double($0.width) }).reduce(0, +) / Double(digits.count)
            let height = digits.map( { Double($0.height) }).reduce(0, +) / Double(digits.count)
            let confidence = digits.map( { $0.confidence }).reduce(0, +) / Double(digits.count)
            return RecognitionNumber(number: predictedNumber, x: x, y: y, height: height, width: width, confidence: confidence)
        }
        let filteredNumbers = numbers.filter { $0.number >= 10 && $0.number < 999 }
        return filteredNumbers
    }
    
    private func sortedByY(_ rows: [[RecognizedDigit]]) -> [[RecognizedDigit]] {
        return rows.sorted { value1, value2 in
            let max = value1.map { $0.y }.max() ?? 0
            let max2 = value2.map { $0.y }.max() ?? 0
            return max < max2
        }
    }
    
    private func createNumbersAsDigitsArraysFromDigits(_ rows: [[RecognizedDigit]]) -> [[RecognizedDigit]] {
        let rowsSortedByX = rows.map { $0.sorted(by: { $0.x < $1.x }) }
        var definedNumbers = [[RecognizedDigit]]()
        // Find separate numbers in each row
        for row in 0..<rowsSortedByX.count {
            for index in 0..<rowsSortedByX[row].count {
                // Start first number in detected row
                if index == 0 {
                    definedNumbers.append([rowsSortedByX[row][index]])
                    // Check
                    // - if after digit there is free space of more than 70% of this digit's width and if so, add next number
                    // - if previous digit has signiticantly (30%) different height than the current one and if so, add next number
                } else if rowsSortedByX[row][index].x - rowsSortedByX[row][index - 1].xAndWidth > Double(rowsSortedByX[row][index].width) * RecognitionThresholds.minimumWidthDifferenceMultiplier ||
                            Double(abs(rowsSortedByX[row][index].height - rowsSortedByX[row][index - 1].height)) > Double(rowsSortedByX[row][index - 1].height) * RecognitionThresholds.minimumHeightDifferenceMultiplier  {
                    // Start new number that was in the same row as other number
                    definedNumbers.append([rowsSortedByX[row][index]])
                } else {
                    // Add digit to already existing number
                    let lastIndex = definedNumbers.count - 1
                    definedNumbers[lastIndex].append(rowsSortedByX[row][index])
                }
            }
        }
        return definedNumbers
    }
    
    private func filteredForSameSpotRecognition(_ definedNumbers: [[RecognizedDigit]]) -> [[RecognizedDigit]] {
        let problematicPairs = definedNumbers.map { $0.indexesWithSmallDifference() }.flatMap( { $0 } )
        // If two digits were detected in the same place, pick the one with higher confidence
        let digitsToRemove = problematicPairs.compactMap( { $0.min(by: { $0.confidence < $1.confidence })})
        return definedNumbers.map { definedNumber in
            return definedNumber.filter { digit in
                !digitsToRemove.contains(digit)
            }
        }
    }
    
    private func filteredForThreeLargestNumbers(_ numbers: [RecognitionNumber]) -> [RecognitionNumber] {
        if numbers.count > 3 {
            let thirdHighestHeight = numbers.sorted(by: { $0.height > $1.height })[2].height
            return numbers.filter({ $0.height >= thirdHighestHeight })
        } else {
            return numbers
        }
        
    }
    
}

extension Array where Element == RecognizedDigit {

    func indexesWithSmallDifference() -> [[RecognizedDigit]] {
        indices.dropLast().filter( {
            (self[$0+1].x - self[$0].x) < 5 }).map {
                let new = $0+1
                return [self[$0], self[new]]
            }
    }

}
