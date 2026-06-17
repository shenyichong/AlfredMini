enum FuzzySearch {
    static func score(haystack: String, needle: String) -> Int {
        if haystack == needle { return 1000 }
        if haystack.hasPrefix(needle) { return 500 }
        
        var score = 0, i = haystack.startIndex
        for c in needle {
            guard let found = haystack[i...].firstIndex(of: c) else { return 0 }
            score += max(1, 50 - haystack.distance(from: i, to: found))
            i = haystack.index(after: found)
        }
        return score
    }
}

