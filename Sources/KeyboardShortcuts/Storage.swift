import Foundation

public protocol StorageProvider {
    func get(forKey defaultName: String) -> String?
    mutating func set(_ value: String?, forKey defaultName: String)
    mutating func disable(forKey defaultName: String)
    mutating func remove(forKey defaultName: String)
    func contains(forKey defaultName: String) -> Bool
}
