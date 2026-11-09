import SwiftUI

// macOS 15 (Sequoia) compatibility layer.
//
// Olaz was written for macOS 26 (Liquid Glass). These wrappers use the macOS 26 API when the app runs on macOS 26 or later,
// and fall back to the closest Sequoia look (materials, bordered buttons, safe-area insets) on macOS 15.

// MARK: - Glass

/// Stand-in for SwiftUI's `Glass` (macOS 26 only): `.regular`, `.tint(_:)`, `.interactive()`.
struct OlazGlass {
    var tintColor: Color?
    var isInteractive = false

    static var regular: OlazGlass { OlazGlass() }

    func tint(_ color: Color?) -> OlazGlass {
        var copy = self
        copy.tintColor = color
        return copy
    }

    func interactive(_ isEnabled: Bool = true) -> OlazGlass {
        var copy = self
        copy.isInteractive = isEnabled
        return copy
    }

    @available(macOS 26.0, *)
    var glass: Glass {
        var g = Glass.regular
        if let tintColor { g = g.tint(tintColor) }
        if isInteractive { g = g.interactive() }
        return g
    }
}

extension View {
    /// `glassEffect(_:in:)` on macOS 26; a material background on macOS 15.
    @ViewBuilder
    func olazGlassEffect<S: Shape>(_ glass: OlazGlass = .regular, in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(glass.glass, in: shape)
        } else {
            background {
                ZStack {
                    shape.fill(.regularMaterial)
                    if let tint = glass.tintColor { shape.fill(tint) }
                    shape.stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                }
            }
        }
    }

    /// `glassEffectID(_:in:)` on macOS 26; nothing on macOS 15.
    @ViewBuilder
    func olazGlassEffectID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(macOS 26.0, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// `.buttonStyle(.glass)` on macOS 26; `.bordered` on macOS 15.
    @ViewBuilder
    func olazGlassButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    /// `.buttonStyle(.glassProminent)` on macOS 26; `.borderedProminent` on macOS 15.
    @ViewBuilder
    func olazGlassProminentButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}

/// `GlassEffectContainer` on macOS 26; a plain wrapper on macOS 15.
struct OlazGlassEffectContainer<Content: View>: View {
    let spacing: CGFloat?
    let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

// MARK: - Bars, scroll edges, toolbar

enum OlazScrollEdgeEffectStyle { case soft, hard }

extension View {
    /// `safeAreaBar(edge:…)` on macOS 26; `safeAreaInset(edge:…)` with a bar background on macOS 15.
    @ViewBuilder
    func olazSafeAreaBar<V: View>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil,
                                  @ViewBuilder content: () -> V) -> some View {
        let bar = content()
        if #available(macOS 26.0, *) {
            safeAreaBar(edge: edge, alignment: alignment, spacing: spacing) { bar }
        } else {
            safeAreaInset(edge: edge, alignment: alignment, spacing: spacing) { bar.background(.bar) }
        }
    }

    /// `scrollEdgeEffectStyle(_:for:)` on macOS 26; nothing on macOS 15.
    @ViewBuilder
    func olazScrollEdgeEffectStyle(_ style: OlazScrollEdgeEffectStyle, for edges: Edge.Set) -> some View {
        if #available(macOS 26.0, *) {
            scrollEdgeEffectStyle(style == .hard ? .hard : .soft, for: edges)
        } else {
            self
        }
    }

    /// `.toolbar { ToolbarSpacer(.flexible) }` on macOS 26; nothing on macOS 15.
    @ViewBuilder
    func olazFlexibleToolbarSpacer() -> some View {
        if #available(macOS 26.0, *) {
            toolbar { ToolbarSpacer(.flexible) }
        } else {
            self
        }
    }

    /// Chat toolbar: header, call buttons, info buttons. macOS 26 adds the spacers and hides the header's shared glass background.
    @ViewBuilder
    func olazChatToolbar<H: View, C: View, I: View>(@ViewBuilder header: () -> H, @ViewBuilder calls: () -> C,
                                                    @ViewBuilder info: () -> I) -> some View {
        let h = header(), c = calls(), i = info()
        if #available(macOS 26.0, *) {
            toolbar {
                ToolbarItem(placement: .primaryAction) { h }
                    .sharedBackgroundVisibility(.hidden)
                ToolbarSpacer(.flexible, placement: .primaryAction)
                ToolbarItemGroup(placement: .primaryAction) { c }
                ToolbarSpacer(.fixed, placement: .primaryAction)
                ToolbarItemGroup(placement: .primaryAction) { i }
            }
        } else {
            toolbar {
                ToolbarItem(placement: .primaryAction) { h }
                ToolbarItemGroup(placement: .primaryAction) { c }
                ToolbarItemGroup(placement: .primaryAction) { i }
            }
        }
    }
}
