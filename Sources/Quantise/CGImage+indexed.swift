// Copyright © 2024 Splendid Things. All rights reserved.

import CoreGraphics

extension CGImage {
    enum IndexedError: Error {
        case cantMakeContext
        case unknownColour
        case cantMakeColourSpace
        case cantMakeProvider
        case cantMakeImage
    }

    public func indexed(in colourSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) throws ->  CGImage {
        let inputBuffer = try rgb8Pixels(in: colourSpace)

        let quantiser = Quantiser(maximumQuanta: 256, policy: RGBQuantiserPolicy())

        let quantisation = quantiser.quantisation(of: inputBuffer)

        let outputColours = quantisation.statistics.flatMap { statistics in
            let rgb = statistics.average
            return [rgb.r, rgb.g, rgb.b]
        }

        let outputSpace = CGColorSpace(
            indexedBaseSpace: CGColorSpaceCreateDeviceRGB(),
            last: 255,
            colorTable: outputColours
        ) 

        guard let outputSpace else { throw IndexedError.cantMakeColourSpace }

        let indexPixels = try inputBuffer.map { rgb -> UInt8 in
            guard let slot = quantisation.quantise(rgb) else {
                throw IndexedError.unknownColour
            }

            return UInt8(slot)
        }

        let provider = CFDataCreate(
            nil,
            indexPixels,
            indexPixels.count
        ).flatMap { 
            CGDataProvider(data: $0)
        }

        guard let provider else { throw IndexedError.cantMakeProvider }

        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: outputSpace,
            bitmapInfo: CGBitmapInfo(),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )

        guard let image else { throw IndexedError.cantMakeImage }

        return image
    }

    public func rgb8Pixels(in space: CGColorSpace = CGColorSpaceCreateDeviceRGB()) throws -> [RGBQuantiserPolicy.RGB8] {
        let pixelCount = width * height

        var buffer = [UInt32](repeating: 0, count: pixelCount)
        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: space,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw IndexedError.cantMakeContext
        }

        context.draw(
            self,
            in: CGRect(x: 0, y: 0, width: width, height: height),
            byTiling: false
        )

        return buffer.map(RGBQuantiserPolicy.RGB8.init(abgr:))
    }
}

// MARK: -

extension RGBQuantiserPolicy.RGB8 {
    init(abgr: UInt32) {
        self.init(
            r: UInt8((abgr) & 0xff),
            g: UInt8((abgr >> 8) & 0xff),
            b: UInt8((abgr >> 16) & 0xff)
        )
    }
}
