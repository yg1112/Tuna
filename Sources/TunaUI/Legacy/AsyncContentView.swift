import SwiftUI

public struct AsyncContentView<T, Content: View>: View {
    let task: Task<T, Never>
    let content: (T) -> Content
    @State private var value: T?

    public init(task: Task<T, Never>, @ViewBuilder content: @escaping (T) -> Content) {
        self.task = task
        self.content = content
    }

    public var body: some View {
        Group {
            if let value {
                self.content(value)
            } else {
                ProgressView()
                    .task {
                        value = await self.task.value
                    }
            }
        }
    }
}
