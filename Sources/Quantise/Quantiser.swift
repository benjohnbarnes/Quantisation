// Copyright © 2024 Splendid Things. All rights reserved.

/// A ``QuantiserPolicy`` describes to ``Quantiser`` the kind of data that it is working with.
///
/// The implementation ``RGBQuantisationPolicy`` provides an example for quantising RGB8 colours.
///
public protocol QuantiserPolicy {
    /// The type of input data to quantise.
    associatedtype Element: Hashable

    /// Quantise an ``element`` to some ``quantizationLevel``.
    ///
    /// ``quantizationLevel`` indicates no quantisation, or an identity on element.
    ///
    func quantise(_ element: Element, at quantizationLevel: Int) -> Element

    /// Statistics about ``Element`` that have been grouped together to a single
    /// quantised value.
    associatedtype Statistics
    func statistics(for element: Element) -> Statistics
    func combineStatistics(_ l: Statistics, _ r: Statistics) -> Statistics
}

// MARK: -

/// ``Quantiser`` provides quantisation for elements as described by a ``QuantiserPolicy``
public struct Quantiser<Policy: QuantiserPolicy> {
    /// How many slots should the quantisation map hold?
    public let maximumQuanta: Int

    /// The policy to use for quantisation.
    public let policy: Policy

    public init(maximumQuanta: Int, policy: Policy) {
        self.maximumQuanta = maximumQuanta
        self.policy = policy
    }
}

public extension Quantiser {
    typealias Statistics = Policy.Statistics
    typealias Element = Policy.Element

    /// Result type for a quantisation operation.
    struct Quantisation {
        /// Statistics about the quanta found. Each quanta has a ``Slot`` and the
        /// statistics known about it.
        public let statistics: [Statistics]

        /// Find the slot that contains a given ``Element``. This can fail for
        /// an unseen element that is not included in any quanta.
        public let quantise: (Element) -> Int?
    }

    /// Find a quantisation of input elements.
    func quantisation(of elements: some Sequence<Policy.Element>) -> Quantisation {
        /// Initially assume it won't be necessary to quantise the elements at all.
        var quantisationLevel = 1

        /// Statistics so far obtained about each ``quanta``
        var quantaStatistics = [Policy.Element: Policy.Statistics]()

        /// Look through the elements we've been given.
        for element in elements {
            /// Find the ``quanta`` for this element at the current quantisation level.
            let quanta = policy.quantise(element, at: quantisationLevel)

            /// Add statistics for this element.
            let elementStatistics = policy.statistics(for: element)

            /// If we've have statistics for this quanta already…
            if let existingStatistics = quantaStatistics[quanta] {
                /// … add this element to the statistics.
                quantaStatistics[quanta] = policy.combineStatistics(existingStatistics, elementStatistics)
            }
            else {
                /// … otherwise create a new entry in the map for this element.
                quantaStatistics[quanta] = policy.statistics(for: element)

                /// If the map is now larger than the target size, re-quantise it at a
                /// courser scale. Continue doing this until the map is at or under the
                /// target size.
                ///
                /// A single pass **may** be sufficient, but this is not guaranteed.
                ///
                /// For `n` bit colour and an `m` bit colour table, this will run at most `(n - m) / 3`
                /// times.
                ///
                while quantaStatistics.count > maximumQuanta {
                    /// Double the quantisation level. We could be more clever here and do something with
                    /// a small set of factors like 2, 3 and 5.
                    quantisationLevel *= 2

                    /// Re-quantise the quanta gathered so far to the new ``quantisationLevel``.
                    quantaStatistics = Dictionary(grouping: quantaStatistics) { keyValue in
                        policy.quantise(keyValue.key, at: quantisationLevel)
                    }.mapValues { keyValues -> Policy.Statistics in
                        /// Force unwrap here should be safe because no group should ever be empty.
                        let first = keyValues.first!.value
                        let rest = keyValues.suffix(from: 1).map(\.value)
                        return rest.reduce(first, policy.combineStatistics(_:_:))
                    }
                }
            }
        }

        /// Give each bin a slot number.
        let slotAssignments = quantaStatistics.enumerated()

        /// Build a dictionary from **quanta** elements to their slot number. Once an element is quantised
        /// to a quanta it can be looked up in this dictionary.
        let quantaToSlot = Dictionary(uniqueKeysWithValues: slotAssignments.map { slot, binStatistics in
            (binStatistics.key, slot)
        })

        return Quantisation(
            statistics: quantaStatistics.map(\.value),
            quantise: { element in
                quantaToSlot[policy.quantise(element, at: quantisationLevel)]
            }
        )
    }
}
