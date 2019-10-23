//
//  ImageProcessor.swift
//  CountWhitePixels
//
//  Created by Robert Ryan on 10/22/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//
// swiftlint:disable large_tuple

import UIKit

class ImageProcessor {
    enum ProcessType {
        case singleThreaded
        case multiThreaded
        case multiThreadedOptimized
    }

    enum ImageProcessorError: Error {
        case unableToGetCgImage
        case unableToCreateContext
        case unableToGetContextData
    }

    func processPixels(in image: UIImage,
                       processType: ProcessType,
                       completion: @escaping (Result<(Int, Double, Double), Error>) -> Void) {
        DispatchQueue.global().async {
            let startOverall = CACurrentMediaTime()

            guard let inputCGImage = image.cgImage else {
                DispatchQueue.main.async { completion(.failure(ImageProcessorError.unableToGetCgImage))}
                return
            }

            let colorSpace       = CGColorSpaceCreateDeviceRGB()
            let width            = inputCGImage.width
            let height           = inputCGImage.height
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width
            let bitmapInfo       = RGBA32.bitmapInfo

            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            else {
                DispatchQueue.main.async { completion(.failure(ImageProcessorError.unableToCreateContext))}
                return
            }
            context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            guard let pointer = context.data else {
                DispatchQueue.main.async { completion(.failure(ImageProcessorError.unableToGetContextData))}
                return
            }

            let buffer = pointer.bindMemory(to: RGBA32.self, capacity: width * height)

            let startProcessing = CACurrentMediaTime()

            let count: Int
            switch processType {
            case .singleThreaded:
                count = self.countPixelsNonParallel(in: buffer, width: width, height: height)

            case .multiThreaded:
                count = self.countPixelsParallel(in: buffer, width: width, height: height)

            case .multiThreadedOptimized:
                count = self.countPixelsParallelOptimized(in: buffer, width: width, height: height)
            }

            let now = CACurrentMediaTime()
            DispatchQueue.main.async {
                completion(.success((count, now - startProcessing, now - startOverall)))
            }
        }
    }
}

private extension ImageProcessor {
    /// Original pixel processing routine

    func countPixelsOriginal(in pixelBuffer: UnsafeMutablePointer<RGBA32>, width: Int, height: Int) -> Int {
        var count = 0

        for column in 0 ..< width {
            for row in 0 ..< height {
                let offset = row * width + column
                if pixelBuffer[offset] == .white {
                    count += 1
                }
            }
        }

        return count
    }

    /// Original pixel processing routine, processing by row rather than by column

    func countPixelsNonParallel(in pixelBuffer: UnsafeMutablePointer<RGBA32>, width: Int, height: Int) -> Int {
        var count = 0

        for row in 0 ..< height {
            for column in 0 ..< width {
                let offset = row * width + column
                if pixelBuffer[offset] == .white {
                    count += 1
                }
            }
        }

        return count
    }

    /// Simple parallelized process
    ///
    /// This takes the simple algorithm and dispatches each row of the image to separate thread.
    ///
    /// In this case, the amount of work per thread is so small that it's actually slower than the single-threaded solution.

    func countPixelsParallel(in pixelBuffer: UnsafeMutablePointer<RGBA32>, width: Int, height: Int) -> Int {
        var count = 0
        let lock = DispatchQueue(label: "...")

        DispatchQueue.concurrentPerform(iterations: height) { row in
            var subTotal = 0
            for column in 0 ..< width {
                let offset = row * width + column
                if pixelBuffer[offset] == .white {
                    subTotal += 1
                }
            }

            lock.async { count += subTotal }
        }

        var total = 0
        lock.sync { total = count }
        return total
    }

    /// Parallelized process w striding
    ///
    /// By adding striding, we:
    ///  * reduce the amount of synchronization that needs to happen
    ///  * reduce the amount of overhead associated with dispatching code to some background thread, doing it 20 (or 21) times rather than thousands of times

    func countPixelsParallelOptimized(in pixelBuffer: UnsafeMutablePointer<RGBA32>, width: Int, height: Int) -> Int {
        var count = 0
        let lock = NSLock()

        let stride = height / 20
        let iterations = Int((Double(height) / Double(stride)).rounded(.up))

        DispatchQueue.concurrentPerform(iterations: iterations) { iteration in
            var subTotal = 0
            let range = iteration * stride ..< min(height, (iteration + 1) * stride)
            for row in range {
                for column in 0 ..< width {
                    let offset = row * width + column
                    if pixelBuffer[offset] == .white {
                        subTotal += 1
                    }
                }
            }

            lock.sync { count += subTotal }
        }

        return count
    }
}
