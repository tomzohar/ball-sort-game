import SwiftUI
import BallSortCore

/// Placeholder root view — proves the App ↔ BallSortCore wiring and the
/// BallColor → SwiftUI Color mapping. Real game screens land in E4/E5.
struct RootView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Ball Sort")
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                ForEach(BallColor.allCases, id: \.self) { color in
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 3, y: 2)
                }
            }

            Text("\(BallColor.allCases.count) colors wired from BallSortCore")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
