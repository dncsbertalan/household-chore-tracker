//
//  Theme.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

enum Theme {
    enum Spacing {
        /// 0pt – No spacing
        static let none: CGFloat = 0

        /// 2pt – Very small adjustments, fine-tuning alignment
        static let xxs: CGFloat = 2

        /// 4pt – Icon-to-label gaps, tightly related elements
        static let xs: CGFloat = 4

        /// 8pt – Related elements, compact stacks, small gaps
        static let sm: CGFloat = 8

        /// 12pt – Compact component padding, form element spacing
        static let md: CGFloat = 12

        /// 16pt – Standard padding, buttons, cards, stack spacing
        static let lg: CGFloat = 16

        /// 20pt – Screen horizontal margins, spacious card padding
        static let xl: CGFloat = 20

        /// 24pt – Section spacing, larger component separation
        static let xxl: CGFloat = 24

        /// 32pt – Major section separation, grouped content
        static let xxxl: CGFloat = 32

        /// 48pt – Large layout separation, hero sections
        static let huge: CGFloat = 48
    }

    enum CornerRadius {
        /// 0pt – Sharp corners, no rounding
        static let none: CGFloat = 0

        /// 4pt – Small badges, subtle rounding
        static let xs: CGFloat = 4

        /// 8pt – Compact controls, small buttons
        static let sm: CGFloat = 8

        /// 12pt – Standard buttons, text fields
        static let md: CGFloat = 12

        /// 16pt – Cards, grouped containers
        static let lg: CGFloat = 16

        /// 20pt – Large cards, prominent containers
        static let xl: CGFloat = 20

        /// 24pt – Modal content, large panels
        static let xxl: CGFloat = 24

        /// 32pt – Large decorative containers, hero cards
        static let xxxl: CGFloat = 32

        /// 9999pt – Fully rounded shapes, pill buttons
        static let full: CGFloat = 9999
    }
}
