import SwiftUI

// Nord palette — single source of truth, mirrors shared/nord/palette.ini.
// Reference: https://www.nordtheme.com/docs/colors-and-palettes
enum Nord {
    // Polar Night — dark bases
    static let nord0 = Color(hex: 0x2E3440)  // primary bg
    static let nord1 = Color(hex: 0x3B4252)  // secondary bg
    static let nord2 = Color(hex: 0x434C5E)  // tertiary bg / hover
    static let nord3 = Color(hex: 0x4C566A)  // raised surface / muted text

    // Snow Storm — light text on dark
    static let nord4 = Color(hex: 0xD8DEE9)  // secondary text
    static let nord5 = Color(hex: 0xE5E9F0)
    static let nord6 = Color(hex: 0xECEFF4)  // primary text

    // Frost — primary accents (blues)
    static let frost7  = Color(hex: 0x8FBCBB)
    static let frost8  = Color(hex: 0x88C0D0)  // hover accent
    static let frost9  = Color(hex: 0x81A1C1)  // link / secondary
    static let frost10 = Color(hex: 0x5E81AC)  // primary accent

    // Aurora — semantic
    static let aurora11 = Color(hex: 0xBF616A)  // error / busy
    static let aurora12 = Color(hex: 0xD08770)  // warning
    static let aurora13 = Color(hex: 0xEBCB8B)  // away
    static let aurora14 = Color(hex: 0xA3BE8C)  // success / online
    static let aurora15 = Color(hex: 0xB48EAD)  // info

    // Semantic role aliases — use these in views, not raw nord/frost names.
    static let bgPrimary      = nord0
    static let bgSecondary    = nord1
    static let bgTertiary     = nord2
    static let surfaceRaised  = nord3
    static let textPrimary    = nord6
    static let textSecondary  = nord4
    static let textMuted      = nord3
    static let accentPrimary  = frost8
    static let accentHover    = frost7
    static let accentActive   = frost10
    static let link           = frost9
    static let statusOnline   = aurora14
    static let statusBusy     = aurora11
    static let statusAway     = aurora13
    static let statusOffline  = nord3
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
