import SwiftUI

extension String {
    /// Builds a `Text` view where URLs are replaced with a tappable link icon
    /// and the remaining text uses the given base color.
    func linkHighlighted(baseColor: Color) -> some View {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let detector else {
            return AnyView(Text(self).foregroundStyle(baseColor))
        }

        let nsString = self as NSString
        let matches = detector.matches(in: self, range: NSRange(location: 0, length: nsString.length))

        guard !matches.isEmpty else {
            return AnyView(Text(self).foregroundStyle(baseColor))
        }

        var parts: [(text: String, url: URL?)] = []
        var lastEnd = self.startIndex

        for match in matches {
            guard let url = match.url,
                  let range = Range(match.range, in: self) else { continue }
            if lastEnd < range.lowerBound {
                parts.append((String(self[lastEnd..<range.lowerBound]), nil))
            }
            parts.append(("", url))
            lastEnd = range.upperBound
        }
        if lastEnd < self.endIndex {
            parts.append((String(self[lastEnd...]), nil))
        }

        return AnyView(
            HStack(spacing: 2) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    if let url = part.url {
                        Link(destination: url) {
                            Image(systemName: "link")
                                .foregroundStyle(.blue)
                        }
                    } else if !part.text.isEmpty {
                        Text(part.text)
                            .foregroundStyle(baseColor)
                    }
                }
            }
        )
    }
}
