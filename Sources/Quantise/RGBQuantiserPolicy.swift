// Copyright © 2024 Splendid Things. All rights reserved.

import Foundation

public struct RGBQuantiserPolicy: QuantiserPolicy {

    public init() {}

    public struct Element: Hashable {
        public let r, g, b: UInt8

        public init(
            r: UInt8,
            g: UInt8,
            b: UInt8
        ) {
            self.r = r
            self.g = g
            self.b = b
        }
    }

    public func quantise(_ element: Element, at quantisationLevel: Int) -> Element {
        Element(
            r: element.r / UInt8(quantisationLevel),
            g: element.g / UInt8(quantisationLevel),
            b: element.b / UInt8(quantisationLevel)
        )
    }

    public struct Statistics {
        public let r: UInt64
        public let g: UInt64
        public let b: UInt64
        public let count: UInt64

        public var average: Element {
            Element(
                r: UInt8(Double(r) / Double(count).rounded(.toNearestOrAwayFromZero)),
                g: UInt8(Double(g) / Double(count).rounded(.toNearestOrAwayFromZero)),
                b: UInt8(Double(b) / Double(count).rounded(.toNearestOrAwayFromZero))
            )
        }
    }

    public func statistics(for element: Element) -> Statistics {
        Statistics(
            r: UInt64(element.r),
            g: UInt64(element.g),
            b: UInt64(element.b),
            count: 1
        )
    }

    public func combineStatistics(_ l: Statistics, _ r: Statistics) -> Statistics {
        Statistics(
            r: r.r + l.r,
            g: r.g + l.g,
            b: r.b + l.b,
            count: r.count + l.count
        )
    }
}
