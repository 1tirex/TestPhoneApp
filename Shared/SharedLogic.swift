//
//  SharedLogic.swift
//  TestPhoneApp
//

import Foundation

// MARK: - App Group
struct CallBlockerConfiguration {
    static let appGroupID = "group.Ilya.TestPhoneApp.callblocker"
}

// MARK: - Phone Number Validator
struct PhoneNumberValidator {
    static let mask = "+X (XXX) XXX-XX-XX"
    
    private static let minDigitsCount = 11
    private static let maxDigitsCount = 12
    
    static func isValid(_ raw: String) -> Bool {
        let digits = extractDigits(from: raw)
        return digits.count >= minDigitsCount && digits.count <= maxDigitsCount
    }
    
    static func extractDigits(from raw: String) -> String {
        raw.filter(\.isNumber)
    }
}

// MARK: - Phone Number Normalizer
struct PhoneNumberNormalizer {
    typealias PhoneNumber = Int64
    
    static func normalize(_ raw: String) -> PhoneNumber? {
        let digits = PhoneNumberValidator.extractDigits(from: raw)
        guard digits.count >= 10 else { return nil }
        return PhoneNumber(String(digits.suffix(10)))
    }
}

// MARK: - Phone Number Formatter
struct PhoneNumberFormatter {
    
    /// Форматирование для отображения: +7 (926) 123-45-67
    static func format(_ raw: String) -> String {
        let digits = PhoneNumberValidator.extractDigits(from: raw)
        guard digits.count >= 10 else { return raw }
        
        let country = String(digits.prefix(digits.count - 10))
        let area = String(digits.dropFirst(country.count).prefix(3))
        let first = String(digits.suffix(7).prefix(3))
        let second = String(digits.suffix(4))
        
        if country.isEmpty {
            return "\(area) \(first)-\(second)"
        }
        return "+\(country) (\(area)) \(first)-\(second)"
    }
    
    /// Живое форматирование при вводе — +7 (926) 123-45-67 по мере набора
    static func liveFormat(_ raw: String, mask: String = "+X (XXX) XXX-XX-XX") -> String {
        let numbers = raw.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )

        var result = ""
        var index = numbers.startIndex

        for char in mask where index < numbers.endIndex {
            if char == "X" {
                result.append(numbers[index])
                index = numbers.index(after: index)
            } else {
                result.append(char)
            }
        }

        return result
    }
}

// MARK: - Blocked Numbers Repository
protocol BlockedNumbersRepositoryProtocol {
    func getAll() -> [String]
    func add(_ number: String) -> Bool
    func remove(_ number: String)
    func clear()
}

final class AppGroupBlockedNumbersRepository: BlockedNumbersRepositoryProtocol {
    private let storage: UserDefaults?
    private let key = "blockedPhoneNumbers"
    
    init(appGroupID: String) {
        self.storage = UserDefaults(suiteName: appGroupID)
    }
    
    func getAll() -> [String] {
        storage?.stringArray(forKey: key) ?? []
    }
    
    @discardableResult
    func add(_ number: String) -> Bool {
        guard let storage else { return false }
        var existing = storage.stringArray(forKey: key) ?? []
        if existing.contains(number) { return false }
        existing.append(number)
        storage.set(existing, forKey: key)
        return true
    }
    
    func remove(_ number: String) {
        guard let storage else { return }
        var existing = storage.stringArray(forKey: key) ?? []
        existing.removeAll { $0 == number }
        storage.set(existing, forKey: key)
    }
    
    func clear() {
        storage?.removeObject(forKey: key)
    }
}
