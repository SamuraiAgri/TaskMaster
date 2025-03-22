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
    func addProject(_ project: TMProject)
    func updateProject(_ project: TMProject)
    func deleteProject(id: UUID)
    
    // タグ関連
    func fetchTags() -> [Tag]
    func getTag(by id: UUID) -> Tag?
    func addTag(_ tag: TMTag)
    func updateTag(_ tag: TMTag)
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
        let persistenceController = PersistenceController.shared
        viewContext = persistenceController.container.viewContext
        // サンプルデータ生成処理を削除
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
    
    func addProject(_ tmProject: TMProject) {
        let project = Project(context: viewContext)
        project.id = tmProject.id
        project.name = tmProject.name
        project.projectDescription = tmProject.description
        project.colorHex = tmProject.colorHex
        project.creationDate = tmProject.creationDate
        project.dueDate = tmProject.dueDate
        project.completionDate = tmProject.completionDate
        
        // 親プロジェクト関連付け（あれば）
        if let parentId = tmProject.parentProjectId,
           let parentProject = getProject(by: parentId) {
            project.parentProject = parentProject
        }
        
        saveContext()
    }
    
    func updateProject(_ tmProject: TMProject) {
        if let project = getProject(by: tmProject.id) {
            project.name = tmProject.name
            project.projectDescription = tmProject.description
            project.colorHex = tmProject.colorHex
            project.dueDate = tmProject.dueDate
            project.completionDate = tmProject.completionDate
            
            // 親プロジェクト関連付け（あれば）
            if let parentId = tmProject.parentProjectId,
               let parentProject = getProject(by: parentId) {
                project.parentProject = parentProject
            } else {
                project.parentProject = nil
            }
            
            saveContext()
        }
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
    
    func addTag(_ tmTag: TMTag) {
        let tag = Tag(context: viewContext)
        tag.id = tmTag.id
        tag.name = tmTag.name
        tag.colorHex = tmTag.colorHex
        tag.creationDate = tmTag.creationDate
        
        saveContext()
    }
    
    func updateTag(_ tmTag: TMTag) {
        if let tag = getTag(by: tmTag.id) {
            tag.name = tmTag.name
            tag.colorHex = tmTag.colorHex
            
            saveContext()
        }
    }
    
    func deleteTag(id: UUID) {
        if let tag = getTag(by: id) {
            viewContext.delete(tag)
            saveContext()
        }
    }
}
