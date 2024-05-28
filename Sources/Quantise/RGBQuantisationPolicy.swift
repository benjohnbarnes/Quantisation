// Copyright © 2024 Splendid Things. All rights reserved.

import Foundation

struct RGBQuantisationPolicy: QuantiserPolicy {
    struct Element: Hashable {
        let r, g, b: UInt8
    }

    func quantise(_ element: Element, at quantisationLevel: Int) -> Element {
        Element(
            r: element.r / UInt8(quantisationLevel),
            g: element.g / UInt8(quantisationLevel),
            b: element.b / UInt8(quantisationLevel)
        )
    }

    struct Statistics {
        let r: UInt64
        let g: UInt64
        let b: UInt64
        let count: UInt64

        var average: Element {
            Element(
                r: UInt8(Double(r) / Double(count).rounded(.toNearestOrAwayFromZero)),
                g: UInt8(Double(g) / Double(count).rounded(.toNearestOrAwayFromZero)),
                b: UInt8(Double(b) / Double(count).rounded(.toNearestOrAwayFromZero))
            )
        }
    }

    func statistics(for element: Element) -> Statistics {
        Statistics(
            r: UInt64(element.r),
            g: UInt64(element.g),
            b: UInt64(element.b),
            count: 1
        )
    }

    func combineStatistics(_ l: Statistics, _ r: Statistics) -> Statistics {
        Statistics(
            r: r.r + l.r,
            g: r.g + l.g,
            b: r.b + l.g,
            count: r.count + l.count
        )
    }
}
