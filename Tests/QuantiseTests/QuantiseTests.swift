import XCTest
import Quantise

final class QuantiseTests: XCTestCase {

    func test_oneColourQuantiseFindsColour() {
        let subject = Quantiser(maximumQuanta: 1, policy: RGBQuantiserPolicy())
        let quantised = subject.quantisation(of: [.white])

        /// Map should just have white as centre.
        XCTAssertEqual(quantised.statistics.mapValues(\.average), [0: .white])

        /// White should quantise to 0.
        XCTAssertEqual(quantised.quantise(.white), 0)

        /// Nothing else should quantise.
        XCTAssertNil(quantised.quantise(.red))
        XCTAssertNil(quantised.quantise(.green))
        XCTAssertNil(quantised.quantise(.blue))
        XCTAssertNil(quantised.quantise(.black))
    }

    func test_twoColourQuantiseFindsColours() {
        let subject = Quantiser(maximumQuanta: 2, policy: RGBQuantiserPolicy())
        let quantised = subject.quantisation(of: [.black, .white])

        /// Map should just have black and white as centres.
        XCTAssertEqual(quantised.statistics.count, 2)
        XCTAssertEqual(Set(quantised.statistics.values.map(\.average)), Set([.black, .white]))

        /// Nothing else should quantise.
        XCTAssertNil(quantised.quantise(.red))
        XCTAssertNil(quantised.quantise(.green))
        XCTAssertNil(quantised.quantise(.blue))
    }

    func test_quantiseGreysFindsMidPoints() {
        let subject = Quantiser(maximumQuanta: 2, policy: RGBQuantiserPolicy())
        let quantised = subject.quantisation(of: (0...255).map { .grey(UInt8($0)) })

        /// Map should have the two mid greys.
        XCTAssertEqual(quantised.statistics.count, 2)
        XCTAssertEqual(Set(quantised.statistics.values.map(\.average)), Set([.grey(64), .grey(192)]))

        /// Nothing else should quantise.
        XCTAssertNil(quantised.quantise(.red))
        XCTAssertNil(quantised.quantise(.green))
        XCTAssertNil(quantised.quantise(.blue))
    }

    func test_quantiseRedsFindsMidPoints() {
        let subject = Quantiser(maximumQuanta: 2, policy: RGBQuantiserPolicy())
        let quantised = subject.quantisation(of: (0...255).map { .red(UInt8($0)) })

        /// Map should just have mid reds
        XCTAssertEqual(quantised.statistics.count, 2)
        XCTAssertEqual(Set(quantised.statistics.values.map(\.average)), Set([.red(64), .red(192)]))

        /// Other colours should should not quantise.
        XCTAssertNil(quantised.quantise(.green))
        XCTAssertNil(quantised.quantise(.blue))
    }

    func test_quantiseGreensFindsMidPoints() {
        let subject = Quantiser(maximumQuanta: 2, policy: RGBQuantiserPolicy())
        let quantised = subject.quantisation(of: (0...255).map { .green(UInt8($0)) })

        /// Map should just have mid reds
        XCTAssertEqual(quantised.statistics.count, 2)
        XCTAssertEqual(Set(quantised.statistics.values.map(\.average)), Set([.green(64), .green(192)]))

        /// Other colours should should not quantise.
        XCTAssertNil(quantised.quantise(.red))
        XCTAssertNil(quantised.quantise(.blue))
    }

    func test_quantiseBluesFindsMidPoints() {
        let subject = Quantiser(maximumQuanta: 2, policy: RGBQuantiserPolicy())
        let quantised = subject.quantisation(of: (0...255).map { .blue(UInt8($0)) })

        /// Map should just have mid reds
        XCTAssertEqual(quantised.statistics.count, 2)
        XCTAssertEqual(Set(quantised.statistics.values.map(\.average)), Set([.blue(64), .blue(192)]))

        /// Other colours should should not quantise.
        XCTAssertNil(quantised.quantise(.red))
        XCTAssertNil(quantised.quantise(.green))
    }
}

extension RGBQuantiserPolicy.RGB8 {
    static let red = Self.red(255)
    static let green = Self.green(255)
    static let blue = Self.blue(255)

    static let black = Self.grey(0)
    static let white = Self.grey(255)

    static func red(_ l: UInt8) -> Self { Self(r: l, g: 0, b: 0) }
    static func green(_ l: UInt8) -> Self { Self(r: 0, g: l, b: 0) }
    static func blue(_ l: UInt8) -> Self { Self(r: 0, g: 0, b: l) }
    static func grey(_ l: UInt8) -> Self { Self(r: l, g: l, b: l) }
}
