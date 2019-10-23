//
//  ViewController.swift
//  CountWhitePixels
//
//  Created by Robert Ryan on 10/22/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {

    private var processType: ImageProcessor.ProcessType?
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        return formatter
    }()

    @IBAction func countWhiteNonParallelized(_ sender: Any) {
        processType = .singleThreaded
        pickImage()
    }

    @IBAction func countWhiteParallelized(_ sender: Any) {
        processType = .multiThreaded
        pickImage()
    }

    @IBAction func countWhiteParallelizedOptimized(_ sender: Any) {
        processType = .multiThreadedOptimized
        pickImage()
    }

    func pickImage() {
        let picker = UIImagePickerController()
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true)

        guard
            let processType = processType,
            let image = info[.originalImage] as? UIImage
        else { return }

        ImageProcessor().processPixels(in: image, processType: processType) { result in
            let message: String

            switch result {
            case .failure(let error):
                message = error.localizedDescription

            case let .success(pixelCount, processingTime, totalTime):
                if
                    let countString      = self.formatter.string(for: pixelCount),
                    let processingString = self.formatter.string(for: processingTime),
                    let totalString      = self.formatter.string(for: totalTime)
                {
                    message = """
                        Found: \(countString) pixels.
                        Total: \(totalString) sec.
                        For loop: \(processingString) sec.
                        """
                } else {
                    message = "Error."
                }
            }

            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .default))
            self.present(alert, animated: true)
        }
    }
}
