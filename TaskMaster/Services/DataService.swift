import Foundation
import Combine
import CoreData
import UIKit

// MARK: - データサービスのプロトコル
protocol DataServiceProtocol {
    // CoreData
    var viewContext: NSManagedObjectContext { get }
    func saveContext()
    
    // 変更通知のためのパブリッシャー
    var objectWillChange: ObservableObjectPublisher { get }
    
    // タスク関連
    func fetchTasks() -> [Task]
    func getTask(by id: UUID) -> Task?
    func saveTask(_ task: Task)
    func deleteTask(id: UUID)
    
    // プロジェクト関連
    func fetchProjects() -> [Project]
    func getProject(by id: UUID) -> Project?
    func saveProject(_ project: Project)
    func deleteProject(id: UUID)
    
    // タグ関連
    func fetchTags() -> [Tag]
    func getTag(by id: UUID) -> Tag?
    func saveTag(_ tag: Tag)
    func deleteTag(id: UUID)
}

// MARK: - データサービスの実装
class DataService: DataServiceProtocol {
    // シングルトンインスタンス
    static let shared = DataService()
    
    // CoreDataコンテキスト
    let viewContext: NSManagedObjectContext
    
    // イベント通知用のパブリッシャー
    let objectWillChange = ObservableObjectPublisher()
    
    // 初期化
    private init() {
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        viewContext = container.viewContext
        
        // サンプルデータがなければ追加
        checkAndCreateSampleData()
    }
    
    // コンテキストの保存
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                objectWillChange.send()
            } catch {
                print("コンテキストの保存に失敗: \(error)")
            }
        }
    }
    
    // サンプルデータの確認と作成
    private func checkAndCreateSampleData() {
        let taskFetch = NSFetchRequest<Task>(entityName: "Task")
        let projectFetch = NSFetchRequest<Project>(entityName: "Project")
        let tagFetch = NSFetchRequest<Tag>(entityName: "Tag")
        
        do {
            let taskCount = try viewContext.count(for: taskFetch)
            let projectCount = try viewContext.count(for: projectFetch)
            let tagCount = try viewContext.count(for: tagFetch)
            
            if taskCount == 0 && projectCount == 0 && tagCount == 0 {
                createSampleData()
            }
        } catch {
            print("サンプルデータの確認に失敗: \(error)")
        }
    }
    
    // サンプルデータの作成
    private func createSampleData() {
        // サンプルタグの作成
        let tags = [
            createTag(name: "仕事", colorHex: "#5AC8FA"),
            createTag(name: "個人", colorHex: "#FF9500"),
            createTag(name: "緊急", colorHex: "#FF3B30"),
            createTag(name: "会議", colorHex: "#34C759"),
            createTag(name: "アイデア", colorHex: "#007AFF")
        ]
        
        // サンプルプロジェクトの作成
        let projects = [
            createProject(
                name: "アプリ開発",
                description: "新規iOSアプリのリリース準備",
                colorHex: "#4A90E2"
            ),
            createProject(
                name: "マーケティングキャンペーン",
                description: "第2四半期の販促キャンペーン計画と実行",
                colorHex: "#50C356",
                dueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
            ),
            createProject(
                name: "ウェブサイトリニューアル",
                description: "企業ウェブサイトのデザイン刷新とコンテンツ更新",
                colorHex: "#E2A64A"
            )
        ]
        
        // サンプルタスクの作成
        let _ = [
            createTask(
                title: "プロジェクト提案書の作成",
                description: "クライアントXYZ向けの新規プロジェクト提案書を作成する",
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                priority: 3,
                status: "進行中",
                project: projects[0],
                tags: [tags[0], tags[2]]
            ),
            createTask(
                title: "週次ミーティングの準備",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                priority: 2,
                status: "未着手",
                isRepeating: true,
                repeatType: "毎週",
                project: projects[0],
                tags: [tags[0], tags[3]]
            ),
            createTask(
                title: "メールの返信",
                description: "取引先からの問い合わせに返信する",
                dueDate: Date(),
                priority: 1,
                status: "未着手",
                project: nil,
                tags: [tags[0]]
            ),
            createTask(
                title: "アプリのバグ修正",
                description: "ログイン画面のクラッシュ問題を修正",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                priority: 3,
                status: "完了",
                completionDate: Date(),
                project: projects[0],
                tags: [tags[0], tags[2]]
            ),
            createTask(
                title: "買い物リスト作成",
                priority: 1,
                status: "未着手",
                project: nil,
                tags: [tags[1]]
            )
        ]
        
        saveContext()
    }
    
    // タグの新規作成
    private func createTag(name: String, colorHex: String) -> Tag {
        let tag = Tag(context: viewContext)
        tag.id = UUID()
        tag.name = name
        tag.colorHex = colorHex
        tag.creationDate = Date()
        return tag
    }
    
    // プロジェクトの新規作成
    private func createProject(name: String, description: String? = nil, colorHex: String, dueDate: Date? = nil) -> Project {
        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = name
        project.projectDescription = description
        project.colorHex = colorHex
        project.creationDate = Date()
        project.dueDate = dueDate
        return project
    }
    
    // タスクの新規作成
    private func createTask(
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: Int16 = 2,
        status: String = "未着手",
        completionDate: Date? = nil,
        isRepeating: Bool = false,
        repeatType: String = "なし",
        project: Project? = nil,
        tags: [Tag] = []
    ) -> Task {
        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.creationDate = Date()
        task.dueDate = dueDate
        task.priority = priority
        task.status = status
        task.completionDate = completionDate
        task.isRepeating = isRepeating
        task.repeatType = repeatType
        
        // プロジェクト関連付け
        if let project = project {
            task.project = project
        }
        
        // タグ関連付け
        for tag in tags {
            task.addToTags(tag)
        }
        
        return task
    }
    
    // MARK: - タスクのCRUD
    func fetchTasks() -> [Task] {
        let request = NSFetchRequest<Task>(entityName: "Task")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.creationDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }
    
    func getTask(by id: UUID) -> Task? {
        let request = NSFetchRequest<Task>(entityName: "Task")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let tasks = try viewContext.fetch(request)
            return tasks.first
        } catch {
            print("タスクの取得に失敗: \(error)")
            return nil
        }
    }
    
    func saveTask(_ task: Task) {
        saveContext()
    }
    
    func deleteTask(id: UUID) {
        if let task = getTask(by: id) {
            viewContext.delete(task)
            saveContext()
        }
    }
    
    // MARK: - プロジェクトのCRUD
    func fetchProjects() -> [Project] {
        let request = NSFetchRequest<Project>(entityName: "Project")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("プロジェクトの取得に失敗: \(error)")
            return []
        }
    }
    
    func getProject(by id: UUID) -> Project? {
        let request = NSFetchRequest<Project>(entityName: "Project")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let projects = try viewContext.fetch(request)
            return projects.first
        } catch {
            print("プロジェクトの取得に失敗: \(error)")
            return nil
        }
    }
    
    func saveProject(_ project: Project) {
        saveContext()
    }
    
    func deleteProject(id: UUID) {
        if let project = getProject(by: id) {
            viewContext.delete(project)
            saveContext()
        }
    }
    
    // MARK: - タグのCRUD
    func fetchTags() -> [Tag] {
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("タグの取得に失敗: \(error)")
            return []
        }
    }
    
    func getTag(by id: UUID) -> Tag? {
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let tags = try viewContext.fetch(request)
            return tags.first
        } catch {
            print("タグの取得に失敗: \(error)")
            return nil
        }
    }
    
    func saveTag(_ tag: Tag) {
        saveContext()
    }
    
    func deleteTag(id: UUID) {
        if let tag = getTag(by: id) {
            viewContext.delete(tag)
            saveContext()
        }
    }
}
