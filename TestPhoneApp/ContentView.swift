//
//  ContentView.swift
//  TestPhoneApp
//
//  Created by Илья on 15.05.2026.
//

import SwiftUI
import CallKit

struct ContentView: View {
    
    //MARK: - Private properties
    
    @State private var phoneNumber = "88005553535"
    @State private var savedNumbers: [String] = []
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var extensionStatus: CXCallDirectoryManager.EnabledStatus = .unknown
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let manager = CallBlockerManager.shared
    
    private var canAddNumber: Bool {
        PhoneNumberValidator.isValid(phoneNumber)
    }
    
    private var extensionStatusIcon: String {
        switch extensionStatus {
        case .enabled:
            return "checkmark.circle.fill"
        case .disabled:
            return "exclamationmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var extensionStatusColor: Color {
        switch extensionStatus {
        case .enabled:
            return .green
        case .disabled:
            return .orange
        default:
            return .gray
        }
    }
    
    private var extensionStatusText: String {
        switch extensionStatus {
        case .enabled:
            return "Защита активна"
        case .disabled:
            return "Не активировано — нажмите «Настроить»"
        default:
            return "Статус неизвестен — нажмите для проверки"
        }
    }
    
    //MARK: - UI
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    extensionStatusCard
                    addNumberCard
                    if !savedNumbers.isEmpty {
                        blockedNumbersList
                    }
                    if extensionStatus != .enabled {
                        instructionsSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Определитель номера")
            .onAppear {
                loadSavedNumbers()
                refreshExtensionStatus()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshExtensionStatus()
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onTapGesture { hideKeyboard() }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple, .pink.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .blue.opacity(0.3), radius: 20, y: 8)
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            
            Text("Блокировка звонков")
                .font(.title2.weight(.semibold))
            
            Text(savedNumbers.isEmpty
                 ? "Нет номеров для блокировки"
                 : "\(savedNumbers.count) номер\(savedNumbers.count == 1 ? "" : "а") в списке")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Extension Status
    
    private var extensionStatusCard: some View {
        HStack {
            Image(systemName: extensionStatusIcon)
                .font(.title3)
                .foregroundStyle(extensionStatusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Расширение Call Directory")
                    .font(.body.weight(.medium))
                Text(extensionStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if extensionStatus != .enabled {
                Button {
                    manager.openCallDirectorySettings()
                    hideKeyboard()
                } label: {
                    Text("Настроить")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .onTapGesture {
            refreshExtensionStatus()
        }
    }
    
    // MARK: - Add Number Card
    
    private var addNumberCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "phone.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.red, in: RoundedRectangle(cornerRadius: 7))
                
                Text("Добавить номер для блокировки")
                    .font(.body.weight(.medium))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                PhoneTextField(digits: $phoneNumber)
                
                if !phoneNumber.isEmpty {
                    Button {
                        phoneNumber = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            
            Divider()
                .padding(.horizontal)
            
            Button {
                addPhoneNumber()
                hideKeyboard()
            } label: {
                HStack {
                    Spacer()
                    Label("Добавить в список", systemImage: "plus.shield.fill")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 14)
                .foregroundStyle(canAddNumber ? .white : .white.opacity(0.4))
                .background(
                    LinearGradient(
                        colors: canAddNumber
                        ? [.blue, .purple]
                        : [.blue.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .padding()
            }
            .disabled(!canAddNumber)
            .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
    
    // MARK: - Blocked Numbers List
    
    private var blockedNumbersList: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "nosign")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.red, in: RoundedRectangle(cornerRadius: 7))
                
                Text("Заблокированные номера")
                    .font(.body.weight(.medium))
                
                Spacer()
                
                Text("\(savedNumbers.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            ForEach(savedNumbers, id: \.self) { number in
                Divider()
                    .padding(.leading, 16)
                
                HStack {
                    Image(systemName: "nosign")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(PhoneNumberFormatter.format(number))
                            .font(.body.monospacedDigit())
                        Text(number)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        removeNumber(number)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            if savedNumbers.count > 1 {
                Divider()
                    .padding(.horizontal)
                
                Button(role: .destructive) {
                    manager.clearNumbers()
                    loadSavedNumbers()
                    showAlert(
                        title: "Список очищен",
                        message: "Все номера удалены. Extension перезагружается..."
                    )
                } label: {
                    HStack {
                        Spacer()
                        Label("Очистить все", systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
    
    // MARK: - Instructions
    
    private var instructionsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 7))
                
                Text("Инструкция")
                    .font(.body.weight(.medium))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal)
            
            InstructionRow(step: 1, color: .blue, text: "Добавьте номера телефонов выше")
            InstructionRow(step: 2, color: .purple, text: "Нажмите «Перейти в настройки» ниже")
            InstructionRow(step: 3, color: .pink, text: "Включите «Блокировка вызовов и идентификация»")
            InstructionRow(step: 4, color: .orange, text: "Активируйте TestPhoneCallDirectory", isLast: true)
            
            Divider()
                .padding(.horizontal)
            
            Button {
                manager.openCallDirectorySettings()
                hideKeyboard()
            } label: {
                HStack {
                    Spacer()
                    Label("Перейти в настройки", systemImage: "gear")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .padding()
            }
            .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Private Methods

extension ContentView {
    func addPhoneNumber() {
        guard canAddNumber else { return }
        
        if savedNumbers.contains(phoneNumber) {
            showAlert(
                title: "Номер уже добавлен",
                message: "\(PhoneNumberFormatter.format(phoneNumber)) уже есть в списке."
            )
            phoneNumber = ""
            return
        }
        
        let added = manager.addNumber(phoneNumber)
        
        if !added {
            showAlert(title: "Ошибка", message: "Не удалось сохранить номер.")
            return
        }
        
        phoneNumber = ""
        loadSavedNumbers()
        
        showAlert(
            title: "Номер добавлен",
            message: "Номер будет блокироваться.\nНе забудьте активировать расширение в настройках."
        )
    }
    
    func removeNumber(_ number: String) {
        manager.removeNumber(number)
        loadSavedNumbers()
    }
    
    func loadSavedNumbers() {
        savedNumbers = manager.getAllNumbers()
    }
    
    func refreshExtensionStatus() {
        manager.getExtensionStatus { [self] status in
            DispatchQueue.main.async {
                extensionStatus = status
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let step: Int
    let color: Color
    let text: String
    var isLast = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(step)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        
        if !isLast {
            Divider()
                .padding(.leading, 60)
        }
    }
}

#Preview {
    ContentView()
}
