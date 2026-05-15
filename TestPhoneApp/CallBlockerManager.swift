//
//  CallBlockerManager.swift
//  TestPhoneApp
//
//  Created by Илья on 15.05.2026.
//

import UIKit
import CallKit

final class CallBlockerManager {
    
    // MARK: - Public properties
    
    static let shared = CallBlockerManager()
    
    // MARK: - Private properties
    
    private static let appGroupID = CallBlockerConfiguration.appGroupID
    
    /// Репозиторий из SharedLogic — в будущем заменится на KMP
    private let repository = AppGroupBlockedNumbersRepository(appGroupID: appGroupID)
    
    private var extensionIdentifier: String {
        "\(Bundle.main.bundleIdentifier ?? "Ilya.TestPhoneApp").TestPhoneCallDirectory"
    }
    
    // MARK: - Public Methods
    
    /// Добавляет номер в список и перезагружает extension
    func addNumber(_ number: String) -> Bool {
        let added = repository.add(number)
        if added { reloadExtension() }
        return added
    }
    
    /// Удаляет номер из списка
    func removeNumber(_ number: String) {
        repository.remove(number)
        reloadExtension()
    }
    
    /// Возвращает все сохранённые номера
    func getAllNumbers() -> [String] {
        repository.getAll()
    }
    
    /// Удаляет все номера
    func clearNumbers() {
        repository.clear()
        reloadExtension()
    }
    
    /// Проверяет статус активации расширения
    func getExtensionStatus(completion: @escaping (CXCallDirectoryManager.EnabledStatus) -> Void) {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(
            withIdentifier: extensionIdentifier
        ) { status, error in
            if let error {
                print("[CallBlockerManager] Status error: \(error.localizedDescription)")
                completion(.unknown)
            } else {
                completion(status)
            }
        }
    }
    
    /// Открывает настройки Call Directory с fallback на общие настройки
    func openCallDirectorySettings() {
        CXCallDirectoryManager.sharedInstance.openSettings { error in
            if let error {
                print("[CallBlockerManager] openSettings error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:])
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func reloadExtension() {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            if let error {
                print("[CallBlockerManager] Reload error: \(error.localizedDescription)")
            } else {
                print("[CallBlockerManager] Extension перезагружена успешно")
            }
        }
    }
}