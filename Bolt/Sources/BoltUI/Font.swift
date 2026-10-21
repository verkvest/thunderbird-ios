// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension Font {
    public enum Style: String, CaseIterable, Identifiable, CustomStringConvertible {
        case titleLarge = "title large"
        case title1 = "title 1"
        case title2 = "title 2"
        case title3 = "title 3"
        case body
        case bodyLarge = "body large"
        case bodySmall = "body small"
        case headline
        case subhead
        case footnote
        case caption
        case callout

        public func dynamicSize(_ size: DynamicTypeSize) -> CGFloat {
            fixedSize + (fixedSize * (CGFloat(size.index) * 0.1)).rounded()
        }

        public var fixedSize: CGFloat {
            switch self {
            case .titleLarge: 31.0
            case .title1: 25.0
            case .title2: 19.0
            case .title3, .bodyLarge: 17.0
            case .body: 15.0
            case .bodySmall, .caption: 11.0
            case .headline: 14.0
            case .subhead, .footnote: 12.0
            case .callout: 13.0
            }
        }

        public var lineSpacing: CGFloat {
            switch self {
            case .titleLarge: 7.0
            case .title1: 6.0
            case .title2: 5.0
            case .title3, .bodyLarge: 5.0
            case .body: 5.0
            case .bodySmall, .caption: 2.0
            case .headline: 5.0
            case .subhead, .footnote: 4.0
            case .callout: 5.0
            }
        }

        public var kerning: CGFloat {
            switch self {
            case .body: -0.2
            case .bodyLarge: -0.4
            default: 0.0
            }
        }

        public var weight: Font.Weight {
            switch self {
            case .headline: .semibold
            default: .regular
            }
        }

        // MARK: CustomStringConvertible
        public var description: String { rawValue }

        // MARK: Identifiable
        public var id: String { rawValue }
    }

    public static func bolt(_ style: Style = .body, size: DynamicTypeSize = .default) -> Self {
        system(size: style.dynamicSize(size), weight: style.weight)
    }
}

extension DynamicTypeSize {
    public static let `default`: Self = .large

    var index: Int {
        switch self {
        case .xSmall: -3
        case .small: -2
        case .medium: -1
        case .xLarge: 1
        case .xxLarge: 2
        case .xxxLarge: 3
        case .accessibility1: 4
        case .accessibility2: 5
        case .accessibility3: 6
        case .accessibility4: 7
        case .accessibility5: 8
        default: 0
        }
    }
}

extension LocalizedStringKey {
    static var quickBrownFox: Self { "The quick brown fox jumps over the lazy dog" }
}

private struct FontPreview: View {
    let style: Font.Style

    // MARK: View
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(style.description)
                    .textStyle(.subhead)
                    .foregroundStyle(.secondary)
                Text(.quickBrownFox)
                    .textStyle(style)
            }
            Spacer()
        }
    }
}

#Preview("Font") {
    ScrollView {
        VStack {
            ForEach(Font.Style.allCases) { style in
                FontPreview(style: style)
                    .padding()
            }
        }
    }
    .containerRelativeFrame(.horizontal)
}
