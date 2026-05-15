//
//  PhoneTextField.swift
//  TestPhoneApp
//
//  Created by Илья on 15.05.2026.
//

import SwiftUI

struct PhoneTextField: View {
    @Binding var digits: String
    
    @State private var formattedText = ""
    
    var body: some View {
        TextField("+8 (800) 555-35-35", text: $formattedText)
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
            .font(.body.monospacedDigit())
            .onAppear {
                formattedText = PhoneNumberFormatter.liveFormat(digits, mask: PhoneNumberValidator.mask)
            }
            .onChange(of: formattedText) { _, newValue in
                let numbers = PhoneNumberValidator.extractDigits(from: newValue)
                
                let maxDigits = PhoneNumberValidator.mask.filter { $0 == "X" }.count
                let limitedDigits = String(numbers.prefix(maxDigits))
                
                let newFormatted = PhoneNumberFormatter.liveFormat(limitedDigits, mask: PhoneNumberValidator.mask)
                
                if formattedText != newFormatted {
                    formattedText = newFormatted
                }
                
                if digits != limitedDigits {
                    digits = limitedDigits
                }
            }
    }
}
