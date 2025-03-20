import Foundation
import Combine
import SwiftUI

class ProjectViewModel: ObservableObject {
    // 公開プロパティ
    @Published var projects: [TMProject] = []
    @Published var filteredProjects: [TMProject] = []
    @Published var searchText: String = ""
    @Published var selectedSortOption: ProjectSortOption = .name
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
            $projects,
            $searchText,
            $selectedSortOption
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] (projects, searchText, sortOption) in
            self?.filterAndSortProjects()
        }
        .store(in: &cancellables)
        
        // 昇順・降順の変更を監視
        $isAscending
            .sink { [weak self] _ in
                self?.filterAndSortProjects()
            }
            .store(in: &cancellables)
        
        // データサービスの変更通知を購読
        dataService.objectWillChange
            .sink { [weak self] _ in
                self?.loadProjects()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    // プロジェクトの読み込み
    func loadProjects() {
        let coreDataProjects = dataService.fetchProjects()
        projects = coreDataProjects.map { TMProject.fromCoreData($0) }
        filterAndSortProjects()
    }
    
    // プロジェクトの追加
    func addProject(_ project: TMProject) {
        dataService.addProject(project)
        loadProjects()
    }
    
    // プロジェクトの更新
    func updateProject(_ project: TMProject) {
        dataService.updateProject(project)
        loadProjects()
    }
    
    // プロジェクトの削除
    func deleteProject(at indexSet: IndexSet) {
        for index in indexSet {
            let project = filteredProjects[index]
            dataService.deleteProject(id: project.id)
        }
        loadProjects()
    }
    
    // プロジェクトの削除（ID指定）
    func deleteProject(id: UUID) {
        dataService.deleteProject(id: id)
        loadProjects()
    }
    
    // プロジェクトの取得（ID指定）
    func getProject(by id: UUID) -> TMProject? {
        if let coreDataProject = dataService.getProject(by: id) {
            return TMProject.fromCoreData(coreDataProject)
        }
        return nil
    }
    
    // プロジェクトの完了ステータス切り替え
    func toggleProjectCompletion(_ project: TMProject) {
        var updatedProject = project
        
        if project.isCompleted {
            updatedProject.completionDate = nil
        } else {
            updatedProject.completionDate = Date()
        }
        
        updateProject(updatedProject)
    }
    
    // プロジェクトの進捗状況を計算
    func calculateProgress(for project: TMProject, tasks: [TMTask]) -> Double {
        let projectTasks = tasks.filter { task in
            return project.taskIds.contains(task.id)
        }
        
        if projectTasks.isEmpty {
            return 0.0
        }
        
        let completedTasks = projectTasks.filter { $0.isCompleted }
        return Double(completedTasks.count) / Double(projectTasks.count)
    }
    
    // ランダムな色を取得
    func randomColor() -> String {
        let colors = [
            "#4A90E2", // 青
            "#50C356", // 緑
            "#E2A64A", // オレンジ
            "#E24A6E", // 赤
            "#9B59B6", // 紫
            "#3498DB", // 水色
            "#1ABC9C", // ティール
            "#F39C12", // 黄色
            "#E74C3C", // 赤
            "#34495E"  // 紺
        ]
        
        return colors.randomElement() ?? "#4A90E2"
    }
    
    // MARK: - プライベートメソッド
    
    // フィルタリングとソート処理
    private func filterAndSortProjects() {
        var result = projects
        
        // 検索テキストによるフィルタリング
        if !searchText.isEmpty {
            result = result.filter { project in
                project.name.lowercased().contains(searchText.lowercased()) ||
                project.description?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
        
        // ソート
        switch selectedSortOption {
        case .name:
            result.sort { project1, project2 in
                isAscending ? project1.name < project2.name : project1.name > project2.name
            }
        case .dueDate:
            result.sort { project1, project2 in
                // 期限なしのプロジェクトは最後に
                if project1.dueDate == nil && project2.dueDate == nil {
                    return project1.name < project2.name
                } else if project1.dueDate == nil {
                    return false
                } else if project2.dueDate == nil {
                    return true
                } else {
                    return isAscending ? project1.dueDate! < project2.dueDate! : project1.dueDate! > project2.dueDate!
                }
            }
        case .creationDate:
            result.sort { project1, project2 in
                isAscending ? project1.creationDate < project2.creationDate : project1.creationDate > project2.creationDate
            }
        case .taskCount:
            result.sort { project1, project2 in
                isAscending ? project1.taskIds.count < project2.taskIds.count : project1.taskIds.count > project2.taskIds.count
            }
        }
        
        filteredProjects = result
    }
}

// プロジェクトのソート種類
enum ProjectSortOption {
    case name
    case dueDate
    case creationDate
    case taskCount
    
    var title: String {
        switch self {
        case .name: return "名前"
        case .dueDate: return "期限日"
        case .creationDate: return "作成日"
        case .taskCount: return "タスク数"
        }
    }
}
