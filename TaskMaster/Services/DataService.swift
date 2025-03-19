import Foundation
import Combine

// MARK: - データサービスのプロトコル
protocol DataServiceProtocol {
    // タスク関連
    func fetchTasks() -> [Task]
    func getTask(by id: UUID) -> Task?
    func saveTasks(_ tasks: [Task])
    func addTask(_ task: Task)
    func updateTask(_ task: Task)
    func deleteTask(id: UUID)
    
    // プロジェクト関連
    func fetchProjects() -> [Project]
    func getProject(by id: UUID) -> Project?
    func saveProjects(_ projects: [Project])
    func addProject(_ project: Project)
    func updateProject(_ project: Project)
    func deleteProject(id: UUID)
    
    // タグ関連
    func fetchTags() -> [Tag]
    func getTag(by id: UUID) -> Tag?
    func saveTags(_ tags: [Tag])
    func addTag(_ tag: Tag)
    func updateTag(_ tag: Tag)
    func deleteTag(id: UUID)
}

// MARK: - データサービスの実装
class DataService: DataServiceProtocol {
    // シングルトンインスタンス
    static let shared = DataService()
    
    // UserDefaultsのキー
    private enum Keys {
        static let tasks = "tasks"
        static let projects = "projects"
        static let tags = "tags"
    }
    
    // イベント通知用のパブリッシャー
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    // 内部データ
    private var cachedTasks: [Task] = []
    private var cachedProjects: [Project] = []
    private var cachedTags: [Tag] = []
    
    // 初期化
    private init() {
        loadFromUserDefaults()
        
        // サンプルデータがなければ追加
        if cachedTasks.isEmpty {
            cachedTasks = Task.samples
        }
        
        if cachedProjects.isEmpty {
            cachedProjects = Project.samples
        }
        
        if cachedTags.isEmpty {
            cachedTags = Tag.samples
        }
    }
    
    // UserDefaultsからデータを読み込む
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: Keys.tasks) {
            do {
                cachedTasks = try JSONDecoder().decode([Task].self, from: data)
            } catch {
                print("タスクのデコードに失敗: \(error)")
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: Keys.projects) {
            do {
                cachedProjects = try JSONDecoder().decode([Project].self, from: data)
            } catch {
                print("プロジェクトのデコードに失敗: \(error)")
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: Keys.tags) {
            do {
                cachedTags = try JSONDecoder().decode([Tag].self, from: data)
            } catch {
                print("タグのデコードに失敗: \(error)")
            }
        }
    }
    
    // UserDefaultsにデータを保存する
    private func saveToUserDefaults() {
        do {
            let tasksData = try JSONEncoder().encode(cachedTasks)
            UserDefaults.standard.set(tasksData, forKey: Keys.tasks)
            
            let projectsData = try JSONEncoder().encode(cachedProjects)
            UserDefaults.standard.set(projectsData, forKey: Keys.projects)
            
            let tagsData = try JSONEncoder().encode(cachedTags)
            UserDefaults.standard.set(tagsData, forKey: Keys.tags)
        } catch {
            print("データのエンコードに失敗: \(error)")
        }
    }
    
    // 変更を通知する
    private func notifyChange() {
        objectWillChange.send()
    }
    
    // MARK: - タスクのCRUD
    func fetchTasks() -> [Task] {
        return cachedTasks
    }
    
    func getTask(by id: UUID) -> Task? {
        return cachedTasks.first { $0.id == id }
    }
    
    func saveTasks(_ tasks: [Task]) {
        cachedTasks = tasks
        saveToUserDefaults()
        notifyChange()
    }
    
    func addTask(_ task: Task) {
        cachedTasks.append(task)
        
        // プロジェクトに関連付ける場合
        if let projectId = task.projectId,
           let index = cachedProjects.firstIndex(where: { $0.id == projectId }) {
            cachedProjects[index].taskIds.append(task.id)
        }
        
        // タグに関連付ける
        for tagId in task.tagIds {
            if let index = cachedTags.firstIndex(where: { $0.id == tagId }) {
                cachedTags[index].taskIds.append(task.id)
            }
        }
        
        saveToUserDefaults()
        notifyChange()
    }
    
    func updateTask(_ task: Task) {
        if let index = cachedTasks.firstIndex(where: { $0.id == task.id }) {
            // 古いタスクを取得
            let oldTask = cachedTasks[index]
            
            // プロジェクトの関連付けが変更された場合
            if oldTask.projectId != task.projectId {
                // 古いプロジェクトからタスクIDを削除
                if let oldProjectId = oldTask.projectId,
                   let projectIndex = cachedProjects.firstIndex(where: { $0.id == oldProjectId }) {
                    cachedProjects[projectIndex].taskIds.removeAll(where: { $0 == task.id })
                }
                
                // 新しいプロジェクトにタスクIDを追加
                if let newProjectId = task.projectId,
                   let projectIndex = cachedProjects.firstIndex(where: { $0.id == newProjectId }) {
                    cachedProjects[projectIndex].taskIds.append(task.id)
                }
            }
            
            // タグの関連付けが変更された場合
            let oldTagIds = Set(oldTask.tagIds)
            let newTagIds = Set(task.tagIds)
            
            // 削除されたタグからタスクIDを削除
            let removedTags = oldTagIds.subtracting(newTagIds)
            for tagId in removedTags {
                if let tagIndex = cachedTags.firstIndex(where: { $0.id == tagId }) {
                    cachedTags[tagIndex].taskIds.removeAll(where: { $0 == task.id })
                }
            }
            
            // 追加されたタグにタスクIDを追加
            let addedTags = newTagIds.subtracting(oldTagIds)
            for tagId in addedTags {
                if let tagIndex = cachedTags.firstIndex(where: { $0.id == tagId }) {
                    cachedTags[tagIndex].taskIds.append(task.id)
                }
            }
            
            // タスクを更新
            cachedTasks[index] = task
            
            saveToUserDefaults()
            notifyChange()
        }
    }
    
    func deleteTask(id: UUID) {
        if let index = cachedTasks.firstIndex(where: { $0.id == id }) {
            let task = cachedTasks[index]
            
            // プロジェクトからタスクIDを削除
            if let projectId = task.projectId,
               let projectIndex = cachedProjects.firstIndex(where: { $0.id == projectId }) {
                cachedProjects[projectIndex].taskIds.removeAll(where: { $0 == id })
            }
            
            // タグからタスクIDを削除
            for tagId in task.tagIds {
                if let tagIndex = cachedTags.firstIndex(where: { $0.id == tagId }) {
                    cachedTags[tagIndex].taskIds.removeAll(where: { $0 == id })
                }
            }
            
            // タスクを削除
            cachedTasks.remove(at: index)
            
            saveToUserDefaults()
            notifyChange()
        }
    }
    
    // MARK: - プロジェクトのCRUD
    func fetchProjects() -> [Project] {
        return cachedProjects
    }
    
    func getProject(by id: UUID) -> Project? {
        return cachedProjects.first { $0.id == id }
    }
    
    func saveProjects(_ projects: [Project]) {
        cachedProjects = projects
        saveToUserDefaults()
        notifyChange()
    }
    
    func addProject(_ project: Project) {
        cachedProjects.append(project)
        saveToUserDefaults()
        notifyChange()
    }
    
    func updateProject(_ project: Project) {
        if let index = cachedProjects.firstIndex(where: { $0.id == project.id }) {
            cachedProjects[index] = project
            saveToUserDefaults()
            notifyChange()
        }
    }
    
    func deleteProject(id: UUID) {
        if let index = cachedProjects.firstIndex(where: { $0.id == id }) {
            let project = cachedProjects[index]
            
            // 関連するタスクを更新（プロジェクトの関連付けを解除）
            for taskId in project.taskIds {
                if let taskIndex = cachedTasks.firstIndex(where: { $0.id == taskId }) {
                    var updatedTask = cachedTasks[taskIndex]
                    updatedTask.projectId = nil
                    cachedTasks[taskIndex] = updatedTask
                }
            }
            
            // プロジェクトを削除
            cachedProjects.remove(at: index)
            
            saveToUserDefaults()
            notifyChange()
        }
    }
    
    // MARK: - タグのCRUD
    func fetchTags() -> [Tag] {
        return cachedTags
    }
    
    func getTag(by id: UUID) -> Tag? {
        return cachedTags.first { $0.id == id }
    }
    
    func saveTags(_ tags: [Tag]) {
        cachedTags = tags
        saveToUserDefaults()
        notifyChange()
    }
    
    func addTag(_ tag: Tag) {
        cachedTags.append(tag)
        saveToUserDefaults()
        notifyChange()
    }
    
    func updateTag(_ tag: Tag) {
        if let index = cachedTags.firstIndex(where: { $0.id == tag.id }) {
            cachedTags[index] = tag
            saveToUserDefaults()
            notifyChange()
        }
    }
    
    func deleteTag(id: UUID) {
        if let index = cachedTags.firstIndex(where: { $0.id == id }) {
            let tag = cachedTags[index]
            
            // 関連するタスクを更新（タグの関連付けを解除）
            for taskId in tag.taskIds {
                if let taskIndex = cachedTasks.firstIndex(where: { $0.id == taskId }) {
                    var updatedTask = cachedTasks[taskIndex]
                    updatedTask.tagIds.removeAll(where: { $0 == id })
                    cachedTasks[taskIndex] = updatedTask
                }
            }
            
            // タグを削除
            cachedTags.remove(at: index)
            
            saveToUserDefaults()
            notifyChange()
        }
    }
}
