// @module: MenuBarViewModel
// @created_by_cursor: yes
// @summary: MenuBarView的视图模型
// @depends_on: None

import SwiftUI
import Combine

class MenuBarViewModel: ObservableObject {
    @Published var isExpanded: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初始化空实现
    }
    
    // 创建预览用实例
    static func preview() -> MenuBarViewModel {
        let viewModel = MenuBarViewModel()
        return viewModel
    }
} 