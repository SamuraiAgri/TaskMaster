import Foundation
import Combine
import SwiftUI

class TagViewModel: ObservableObject {
    // 公開プロパティ
    @Published var tags: [Tag] = []
    @Published var filteredTags: [Tag] = []
    @Published var searchText: String = ""
    @Published var selectedSortOption: TagSortOption = .name
    @Published var isAscending: Bool = true
    
    // データサービス
    private let dataService: DataServiceProtocol
    
    // キャンセル可能な購読
    private var cancellables = Set<AnyCancellable>()
    
    // 初期化
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        
        // 検索テキスト、ソートオプションの変更を監視して自動で再フィルタリング
        Publishers.CombineLatest3(
            $tags,
            $searchText,
            $selectedSortOption
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] (tags, searchText, sortOption) in
            self?.filterAndSortTags()
        }
        .store(in: &cancellables)
        
        // 昇順・降順の変更を監視
        $isAscending
            .sink { [weak self] _ in
                self?.filterAndSortTags()
            }
            .store(in: &cancellables)
        
        // データサービスの変更通知を購読
        dataService.objectWillChange
            .sink { [weak self] _ in
                self?.loadTags()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    // タグの読み込み
    func loadTags() {
        tags = dataService.fetchTags()
        filterAndSortTags()
    }
    
    // タグの追加
    func addTag(_ tag: Tag) {
        dataService.addTag(tag)
        loadTags()
    }
    
    // タグの更新
    func updateTag(_ tag: Tag) {
        dataService.updateTag(tag)
        loadTags()
    }
    
    // タグの削除
    func deleteTag(at indexSet: IndexSet) {
        for index in indexSet {
            let tag = filteredTags[index]
            dataService.deleteTag(id: tag.id)
        }
        loadTags()
    }
    
    // タグの削除（ID指定）
    func deleteTag(id: UUID) {
        dataService.deleteTag(id: id)
        loadTags()
    }
    
    // タグの取得（ID指定）
    func getTag(by id: UUID) -> Tag? {
        return dataService.getTag(by: id)
    }
    
    // 複数タグの取得（ID指定）
    func getTags(by ids: [UUID]) -> [Tag] {
        return ids.compactMap { id in
            return dataService.getTag(by: id)
        }
    }
    
    // ランダムな色を取得
    func randomColor() -> String {
        let colors = [
            "#5AC8FA", // 水色
            "#FF9500", // オレンジ
            "#FF3B30", // 赤
            "#34C759", // 緑
            "#007AFF", // 青
            "#FF2D55", // ピンク
            "#5856D6", // 紫
            "#FFCC00", // 黄色
            "#8E8E93", // グレー
            "#32ADE6", // 青緑
            "#AF52DE", // 紫ピンク
            "#FF9500"  // 金色
        ]
        
        return colors.randomElement() ?? "#8E8E93"
    }
    
    // MARK: - プライベートメソッド
    
    // フィルタリングとソート処理
    private func filterAndSortTags() {
        var result = tags
        
        // 検索テキストによるフィルタリング
        if !searchText.isEmpty {
            result = result.filter { tag in
                tag.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        // ソート
        switch selectedSortOption {
        case .name:
            result.sort { tag1, tag2 in
                isAscending ? tag1.name < tag2.name : tag1.name > tag2.name
            }
        case .taskCount:
            result.sort { tag1, tag2 in
                isAscending ? tag1.taskIds.count < tag2.taskIds.count : tag1.taskIds.count > tag2.taskIds.count
            }
        }
        
        filteredTags = result
    }
}

// タグのソート種類
enum TagSortOption {
    case name
    case taskCount
    
    var title: String {
        switch self {
        case .name: return "名前"
        case .taskCount: return "タスク数"
        }
    }
}
