import Foundation

enum FuzzySearch {
    // Simple subsequence-based scoring with prefix/exact boosts.
    static func score(haystack: String, needle: String) -> Int {
        if haystack == needle { return 1000 }
        if haystack.hasPrefix(needle) { return 500 }
        // subsequence score
        var score = 0
        var i = haystack.startIndex
        for c in needle {
            if let found = haystack[i...].firstIndex(of: c) {
                // earlier match higher score
                let distance = haystack.distance(from: i, to: found)
                score += max(1, 50 - distance)
                i = haystack.index(after: found)
            } else {
                return 0
            }
        }
        return score
    }
}


