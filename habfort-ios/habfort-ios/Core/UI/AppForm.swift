import SwiftUI

/// A Form dressed to match the card lists: white page, soft grey filled
/// sections instead of the grouped-grey background, larger sentence-case
/// section headers. Rows that set their own `listRowBackground` keep it.
struct AppForm<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            Group {
                content
            }
            .listRowBackground(Color.secondary.opacity(0.09))
            .headerProminence(.increased)
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
    }
}
