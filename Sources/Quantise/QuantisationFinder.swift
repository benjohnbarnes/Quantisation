// Copyright © 2024 Splendid Things. All rights reserved.

protocol QuantiserPolicy {
    associatedtype Element: Hashable
    func quantise(_ element: Element, at quantizationLevel: Int) -> Element

    associatedtype Statistics
    func statistics(for element: Element) -> Statistics
    func combineStatistics(_ l: Statistics, _ r: Statistics) -> Statistics
}

// MARK: -

struct QuantisationFinder<Policy: QuantiserPolicy> {
    /// How many slots should the quantisation map hold?
    let maximumQuanta: Int

    /// The policy to use during quantisation.
    let policy: Policy

    /// Find a quantisation of input elements.
    ///
    /// The result tuple has:
    /// * `map` – Dictionary that assign each map slot integer in `0 ..< mapSize` a shared
    /// quantised value.
    /// * `quantiser` – function taking an un-quantised value and looking up a map slot to
    /// use for it.
    func findMap(for elements: some Sequence<Policy.Element>) -> (
        statistics: [Int: Policy.Statistics],
        quantiser: (Policy.Element) -> Int?
    ) {
        /// Begin assuming it won't be necessary to quantise the elements at all.
        var quantisationLevel = 1

        /// The unique quantised elements we have discovered so far.
        var quantaStatistics = [Policy.Element: Policy.Statistics]()

        /// Look through the elements we've been given.
        for element in elements {
            /// Find the quanta for this element at the current quantisation level.
            let quanta = policy.quantise(element, at: quantisationLevel)

            /// Add statistics for this element.
            let elementStatistics = policy.statistics(for: element)
            if let existingStatistics = quantaStatistics[quanta] {
                quantaStatistics[quanta] = policy.combineStatistics(existingStatistics, elementStatistics)
            }
            else {
                quantaStatistics[quanta] = policy.statistics(for: element)
            }

            /// If the map has become larger than the target size, we need to re-quantise at a
            /// courser scale. We keep on doing this until the map is at or under the target size.
            /// A single pass may well be sufficient, but this is not guaranteed.
            ///
            /// For `n` bit colour and an `m` bit colour table, this will run at most `(n - m) / 3`
            /// times.
            ///
            while quantaStatistics.count > maximumQuanta {
                /// Double the quantisation level. We could be more clever here and do something with
                /// a small set of factors like 2, 3 and 5.
                quantisationLevel *= 2

                /// Re-bin the statistics gathered so far to the new quantisation level.
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

        /// Give each bin a slot number.
        let slotAssignments = quantaStatistics.enumerated()

        /// Build a dictionary from slot number to statistics about that slot. This is effectively our
        /// "colour map".
        let slotToStatistics = Dictionary(uniqueKeysWithValues: slotAssignments.map { slot, binStatistics in
            (slot, binStatistics.value)
        })

        /// Build a dictionary from **quanta** elements to their slot number. Once an element is quantised
        /// to a quanta it can be looked up in this dictionary.
        let quantaToSlot = Dictionary(uniqueKeysWithValues: slotAssignments.map { slot, binStatistics in
            (binStatistics.key, slot)
        })

        return (
            statistics: slotToStatistics,
            quantiser: { element in quantaToSlot[policy.quantise(element, at: quantisationLevel)] }
        )
    }
}
