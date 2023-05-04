//
//  RoboflowService.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 14/12/2022.
//

import Combine
import UIKit
import os.log

protocol RoboflowServiceProtocol {
    
    var baseURL: String { get }
    
    var imageConverter: ImageDataConverterProtocol { get set }
    var responseConverter: RoboflowResponseConverterProtocol { get set }
    var urlSession: URLSession { get set }
    
}


public class BloodnoteOCRService: RoboflowServiceProtocol  {

    var baseURL: String { "https://detect.roboflow.com/" }

    var imageConverter: ImageDataConverterProtocol = ImageDataConverter()
    var responseConverter: RoboflowResponseConverterProtocol = RoboflowResponseConverter()
    var urlSession = URLSession.shared

    public init() { }
    
    public func analyze(image: UIImage) -> AnyPublisher<OCRResult?, BloodnoteOCRNetworkError> {
        return urlSession
            .dataTaskPublisher(for: createURLRequest(image: image))
            .tryMap { data, response -> Data in
                guard let httpUrlResponse = response as? HTTPURLResponse else {
                    os_log(.error, log: .network, "HTTP Response error")
                    throw BloodnoteOCRNetworkError.unknown }
                guard 200 ... 299 ~= httpUrlResponse.statusCode else { throw BloodnoteOCRNetworkError.error(for: httpUrlResponse.statusCode) }
                return data
            }
            .tryMap { data -> RecognitionResponse in
                do {
                    return try JSONDecoder().decode(RecognitionResponse.self, from: data)
                } catch let error {
                    os_log(.error, log: .network, "Decoding error")
                    throw BloodnoteOCRNetworkError.decoding(error)
                }
            }
            .mapError({ error -> BloodnoteOCRNetworkError in
                switch error {
                case is Swift.DecodingError:
                    os_log(.error, log: .network, "Decoding error")
                    return BloodnoteOCRNetworkError.decoding(error)
                case let urlError as URLError:
                    return .urlError(urlError)
                case let error as BloodnoteOCRNetworkError:
                    return error
                default:
                    return .unknown
                }
            })
            .receive(on: DispatchQueue.main)
            .map({ [weak self] response -> OCRResult? in
                os_log(.default, log: .network, "Received response with data")
//                let predictions = response.predictions.filter( { $0.predictionClass != "-" })
//                var newResponse = response
//                newResponse.predictions = predictions
//                newResponse.predictions.forEach { digit in
//                    print("***\n")fb
//                    print(digit)
//                    print("***\n")
//                }
                return self?.responseConverter.convert(response)
            })
            .eraseToAnyPublisher()
    }
    
    private func createURLRequest(image: UIImage) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL)!)
        let imageData = image.resized(newWidth: 650)
            .desaturated()
            .brightened(0.35)
            .contrasted(4.0)
            .jpegData(compressionQuality: 1.0)
        let fileContent = imageData?.base64EncodedString()
        let postData = fileContent!.data(using: .utf8)
        let httpBody = postData
        request.url?.append(component: RoboflowModelConfiguration.workspace)
        request.url?.append(component: String(RoboflowModelConfiguration.modelVersion))
        request.url?.append(queryItems: [URLQueryItem(name: "api_key", value: RoboflowModelConfiguration.apiKey), URLQueryItem(name: "name", value: "YOUR_IMAGE.jpg")])
        request.timeoutInterval = Double.infinity
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = httpBody
        return request
    }
    
}

extension OSLog {

    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Recognition Engine
    static let ocr = OSLog(subsystem: subsystem, category: "ocr")

    /// Networking
    static let network = OSLog(subsystem: subsystem, category: "ocr")

}
