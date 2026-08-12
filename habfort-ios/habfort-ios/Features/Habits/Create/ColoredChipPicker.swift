import SwiftUI

struct ColoredChipPicker<Item: Identifiable & Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let icon: (Item) -> String
    let label: (Item) -> String
    let colors: (Item) -> (background: Color, foreground: Color)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                chip(for: item)
            }
        }
    }

    private func chip(for item: Item) -> some View {
        let isSelected = item == selection
        let palette = colors(item)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = item
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon(item))
                    .font(.subheadline.weight(.semibold))
                Text(label(item))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? palette.foreground : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? palette.background : Color.secondary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
