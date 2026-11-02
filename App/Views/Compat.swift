import SwiftUI

// Building with Xcode 13 (Swift 5.6, macOS 12.3 SDK): the macOS 13 SwiftUI APIs Vikey uses aren't in the SDK,
// though they exist at runtime on macOS 13. These stand-ins keep the call sites unchanged; Xcode 14+ uses the real ones.
#if !compiler(>=5.7)

/// LabeledContent: the label on the left, the control on the right.
struct LabeledContent<Label: View, Content: View>: View {
    private let content: Content, label: Label
    init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.content = content()
        self.label = label()
    }
    var body: some View {
        HStack { label; Spacer(); content }
    }
}

/// Grid: rows of equal-width columns (no per-column measuring before macOS 13).
struct Grid<Content: View>: View {
    private let alignment: Alignment, horizontalSpacing: CGFloat?, verticalSpacing: CGFloat?, content: Content
    init(alignment: Alignment = .center, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content()
    }
    var body: some View {
        VStack(alignment: alignment.horizontal, spacing: verticalSpacing) { content }
            .environment(\.compatGridCell, CompatGridCell(alignment: alignment, spacing: horizontalSpacing))
    }
}

struct GridRow<Content: View>: View {
    @Environment(\.compatGridCell) private var cell
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        _VariadicView.Tree(CompatGridRowLayout(cell: cell)) { content }
    }
}

struct CompatGridCell { var alignment: Alignment = .center; var spacing: CGFloat? }
private struct CompatGridCellKey: EnvironmentKey { static let defaultValue = CompatGridCell() }
extension EnvironmentValues {
    var compatGridCell: CompatGridCell {
        get { self[CompatGridCellKey.self] }
        set { self[CompatGridCellKey.self] = newValue }
    }
}

private struct CompatGridRowLayout: _VariadicView_MultiViewRoot {
    let cell: CompatGridCell
    func body(children: _VariadicView.Children) -> some View {
        HStack(spacing: cell.spacing) {
            ForEach(children) { child in
                child.frame(maxWidth: .infinity, alignment: cell.alignment)
            }
        }
    }
}

enum CompatFormStyle { case grouped }

extension View {
    func gridColumnAlignment(_ alignment: HorizontalAlignment) -> some View { self }
    /// Grouped forms came with macOS 13; inset the plain form so it doesn't touch the window edges.
    func formStyle(_ style: CompatFormStyle) -> some View { padding(.horizontal, 20).padding(.top, 12) }
    func scrollDisabled(_ disabled: Bool) -> some View { self }
    func lineLimit(_ limit: Int, reservesSpace: Bool) -> some View { lineLimit(limit) }
}

extension MainActor {
    /// Only called from main-queue callbacks.
    static func assumeIsolated<T>(_ body: @MainActor () throws -> T) rethrows -> T {
        dispatchPrecondition(condition: .onQueue(.main))
        return try withoutActuallyEscaping(body) { body in
            try unsafeBitCast(body, to: (() throws -> T).self)()
        }
    }
}

#endif
