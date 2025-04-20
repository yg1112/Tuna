// @module: StatsStore
// @created_by_cursor: yes
// @summary: 应用统计数据存储和管理
// @depends_on: None

import Combine
import Foundation

/// 管理应用统计数据的存储
class StatsStore: ObservableObject {
    static let shared = StatsStore()

    @Published var consecutiveDays: Int = 0
    @Published var wordsFreed: Int = 0
    @Published var smartSwaps: Int = 0

    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.loadStats()
        self.setupObservers()
        self.checkAndUpdateDailyStreak()
    }

    /// 从UserDefaults加载统计数据
    private func loadStats() {
        self.consecutiveDays = self.userDefaults.integer(forKey: "stats_consecutiveDays")
        self.wordsFreed = self.userDefaults.integer(forKey: "stats_wordsFreed")
        self.smartSwaps = self.userDefaults.integer(forKey: "stats_smartSwaps")
    }

    /// 设置相关事件的观察者
    private func setupObservers() {
        // 监听Smart Swaps事件
        NotificationCenter.default.publisher(for: NSNotification.Name("smartSwapsStatusChanged"))
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let enabled = userInfo["enabled"] as? Bool,
                   enabled
                {
                    self?.incrementSmartSwaps()
                }
            }
            .store(in: &self.cancellables)

        // 监听文字转录完成事件
        NotificationCenter.default.publisher(for: NSNotification.Name("dictationFinished"))
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let wordCount = userInfo["wordCount"] as? Int
                {
                    self?.incrementWordsFreed(by: wordCount)
                }
            }
            .store(in: &self.cancellables)
    }

    /// 检查并更新每日连续使用统计
    private func checkAndUpdateDailyStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 获取上次使用日期
        if let lastUsedDateString = userDefaults.string(forKey: "stats_lastUsedDate"),
           let lastUsedDate = ISO8601DateFormatter().date(from: lastUsedDateString)
        {
            let lastUsedDay = calendar.startOfDay(for: lastUsedDate)

            // 如果是今天已经记录过，不增加天数
            if calendar.isDate(lastUsedDay, inSameDayAs: today) {
                return
            }

            // 如果是昨天使用的，增加连续天数
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastUsedDay, inSameDayAs: yesterday) {
                self.consecutiveDays += 1
                self.userDefaults.set(self.consecutiveDays, forKey: "stats_consecutiveDays")
            }
            // 如果超过一天没用，重置连续天数为1
            else if !calendar.isDate(lastUsedDay, inSameDayAs: today) {
                self.consecutiveDays = 1
                self.userDefaults.set(self.consecutiveDays, forKey: "stats_consecutiveDays")
            }
        } else {
            // 首次使用，设置为1天
            self.consecutiveDays = 1
            self.userDefaults.set(self.consecutiveDays, forKey: "stats_consecutiveDays")
        }

        // 更新最后使用日期为今天
        self.userDefaults.set(
            ISO8601DateFormatter().string(from: today),
            forKey: "stats_lastUsedDate"
        )
    }

    /// 增加Smart Swaps计数
    func incrementSmartSwaps() {
        self.smartSwaps += 1
        self.userDefaults.set(self.smartSwaps, forKey: "stats_smartSwaps")
    }

    /// 增加解放的单词数
    func incrementWordsFreed(by count: Int = 1) {
        self.wordsFreed += count
        self.userDefaults.set(self.wordsFreed, forKey: "stats_wordsFreed")
    }

    /// 创建一个预览实例
    static func preview() -> StatsStore {
        let store = StatsStore()
        store.consecutiveDays = 7
        store.wordsFreed = 1250
        store.smartSwaps = 42
        return store
    }
}
