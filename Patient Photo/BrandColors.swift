//
//  BrandColors.swift
//  Patient Photo
//
//  Warm navy / gold / cream palette for Staff Portrait
//

import SwiftUI

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    static let brandNavyDeep = Color(hex: "0A1430")
    static let brandNavyMid = Color(hex: "1C2C5E")
    static let brandGold = Color(hex: "D4A64A")
    static let brandCream = Color(hex: "F4DFBE")

    static var brandNavy: Color { brandNavyMid }

    static var brandHeaderBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color.brandNavyDeep)
                : UIColor(Color.brandNavyMid)
        })
    }

    static var brandScreenBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color.brandNavyDeep)
                : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        })
    }

    static var brandSurface: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.white.withAlphaComponent(0.92)
        })
    }

    static var brandPrimaryText: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color.brandCream)
                : UIColor(Color.brandNavyDeep)
        })
    }

    static var brandSecondaryText: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color.brandCream).withAlphaComponent(0.72)
                : UIColor(Color.brandNavyMid).withAlphaComponent(0.78)
        })
    }

    static var brandHeaderText: Color { brandCream }

    static var brandHeaderSubtext: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color.brandCream).withAlphaComponent(0.78)
                : UIColor(Color.brandCream).withAlphaComponent(0.88)
        })
    }

    static var brandPrimaryButtonBackground: Color { brandGold }

    static var brandPrimaryButtonForeground: Color { brandNavyDeep }

    static var brandPrimaryButtonDisabledBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.gray.withAlphaComponent(0.35)
                : UIColor(Color.brandGold).withAlphaComponent(0.32)
        })
    }

    static var brandPrimaryButtonDisabledForeground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.45)
                : UIColor(Color.brandNavyDeep).withAlphaComponent(0.45)
        })
    }

    static var brandSecondaryButtonBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.10)
                : UIColor(Color.brandNavyMid).withAlphaComponent(0.10)
        })
    }

    static var brandSecondaryButtonForeground: Color { brandPrimaryText }

    static var brandSuccess: Color { brandGold }

    static var brandWarning: Color {
        Color(hex: "E8A54B")
    }

    static var brandCardShadow: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.35)
                : UIColor(Color.brandNavyDeep).withAlphaComponent(0.10)
        })
    }
}

struct BrandPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.medium))
            .frame(minWidth: 200)
            .frame(height: 56)
            .padding(.horizontal, 20)
            .background(isEnabled ? Color.brandPrimaryButtonBackground.opacity(configuration.isPressed ? 0.85 : 1.0) : Color.brandPrimaryButtonDisabledBackground)
            .foregroundColor(isEnabled ? Color.brandPrimaryButtonForeground : Color.brandPrimaryButtonDisabledForeground)
            .cornerRadius(16)
    }
}

struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.medium))
            .frame(minWidth: 200)
            .frame(height: 56)
            .padding(.horizontal, 20)
            .background(Color.brandSecondaryButtonBackground.opacity(configuration.isPressed ? 0.75 : 1.0))
            .foregroundColor(Color.brandSecondaryButtonForeground)
            .cornerRadius(16)
    }
}

struct BrandCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.brandSurface)
                    .shadow(color: Color.brandCardShadow, radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    func brandCard() -> some View {
        modifier(BrandCard())
    }
}
