import SwiftUI

extension String {
    /// Returns an `AttributedString` where URLs are styled as blue tappable links
    /// and the remaining text uses the given base color.
    func linkHighlighted(baseColor: Color) -> AttributedString {
        var result = AttributedString(self)
        result.foregroundColor = baseColor

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return result
        }

        let nsString = self as NSString
        let matches = detector.matches(in: self, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            guard let url = match.url,
                  let range = Range(match.range, in: self),
                  let attrRange = result.range(of: self[range]) else { continue }
            result[attrRange].link = url
            result[attrRange].foregroundColor = .blue
        }

        return result
    }
}
