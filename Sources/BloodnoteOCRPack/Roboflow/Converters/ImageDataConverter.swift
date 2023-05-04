//
//  ImageDataConverter.swift
//  Bloodnote OCR
//
//  Created by Tymoteusz Stokarski on 14/12/2022.
//

import UIKit

protocol ImageDataConverterProtocol {
    func createData(from image: UIImage, compressionQuality: CGFloat) -> Data?
}

class ImageDataConverter: ImageDataConverterProtocol {
    
    public func createData(from image: UIImage, compressionQuality: CGFloat = 1.0) -> Data? {
        let newWidth = (RecognitionThresholds.defaultImageHeight / image.size.height) * image.size.width
        let convertedImage = image.desaturated().resized(newWidth: newWidth)
        //    .brightened(RecognitionThresholds.photoBrightness)
          //  .desaturated()
            .contrasted(RecognitionThresholds.photoContrast)
        let imageData = convertedImage.jpegData(compressionQuality: compressionQuality)
        let fileContent = imageData?.base64EncodedString()
        let postData = fileContent!.data(using: .utf8)
        return postData
    }
    
}

extension UIImage {

    func desaturated() -> UIImage {
        let context = CIContext(options: nil)
        var ciimage: CIImage? = nil
        if let CGImage = self.cgImage {
            ciimage = CIImage(cgImage: CGImage)
        }
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciimage, forKey: kCIInputImageKey)
        filter?.setValue(NSNumber(value: 0.0), forKey: kCIInputSaturationKey)
        let result = filter!.value(forKey: kCIOutputImageKey) as? CIImage
        var cgImage: CGImage? = nil
        if let result {
            cgImage = context.createCGImage(result, from: result.extent)
        }
        return UIImage(cgImage: cgImage!)
    }

    func contrasted(_ value: CGFloat = 3.0) -> UIImage {
        let inputImage = CIImage(image: self)!
        let parameters = [
            "inputContrast": NSNumber(value: value)
        ]
        let outputImage = inputImage.applyingFilter("CIColorControls", parameters: parameters)

        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }

    func brightened(_ value: CGFloat = 0.3) -> UIImage {
        let inputImage = CIImage(image: self)!
        let parameters = [
            "inputBrightness": NSNumber(value: value)
        ]
        let outputImage = inputImage.applyingFilter("CIColorControls", parameters: parameters)

        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }

    func saturated(_ value: CGFloat = 1.0) -> UIImage {
        let inputImage = CIImage(image: self)!
        let parameters = [
            "inputSaturation": NSNumber(value: value)
        ]
        let outputImage = inputImage.applyingFilter("CIColorControls", parameters: parameters)

        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }

    func resized(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }


}
