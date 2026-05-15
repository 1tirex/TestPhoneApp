//
//  CallDirectoryHandler.swift
//  TestPhoneCallDirectory
//
//  Created by Илья on 15.05.2026.
//

import CallKit

final class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        
        addBlockedNumbers(to: context)
        
        context.completeRequest()
    }
}

//MARK: - Private Methods

private extension CallDirectoryHandler {
    func addBlockedNumbers(to context: CXCallDirectoryExtensionContext) {
        var numbers = loadBlockedNumbers()
            .compactMap { PhoneNumberNormalizer.normalize($0) }
        
        numbers.sort()
        
        for phoneNumber in numbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
        
        print("[Extension] Заблокировано \(numbers.count) номеров")
    }
    
    func loadBlockedNumbers() -> [String] {
        let storage = UserDefaults(suiteName: CallBlockerConfiguration.appGroupID)
        return storage?.stringArray(forKey: "blockedPhoneNumbers") ?? []
    }
}

//MARK: - CXCallDirectoryExtensionContextDelegate

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("[Extension] Request failed: \(error.localizedDescription)")
    }
}
