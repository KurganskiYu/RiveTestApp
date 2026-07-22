//
//  ParametersCardView.swift
//  RiveTestApp
//
//  Floating translucent card that renders one control per ParamSpec declared for the item.
//

import SwiftUI

struct ParametersCardView: View {
    let viewModel: AnimationDetailViewModel
    /// Bound so text fields here can drive the parent's keyboard-avoidance behavior.
    @FocusState.Binding var focusedField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            ForEach(viewModel.item.inputs) { input in
                row(for: input)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func row(for input: ParamSpec) -> some View {
        switch input {
        case .number(let name, _):
            HStack {
                Text(name)
                Spacer()
                TextField("Value", value: Binding(
                    get: { viewModel.numberValues[name] ?? 0 },
                    set: { viewModel.setNumber(name, $0) }
                ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .padding(8)
                .background(Color.black.opacity(0.45))
                .cornerRadius(12)
                .foregroundColor(.white)
                .focused($focusedField, equals: name)
            }

        case .boolean(let name, _):
            Toggle(name, isOn: Binding(
                get: { viewModel.boolValues[name] ?? false },
                set: { viewModel.setBool(name, $0) }
            ))

        case .string(let name, _):
            HStack {
                Text(name)
                Spacer()
                TextField("Text", text: Binding(
                    get: { viewModel.stringValues[name] ?? "" },
                    set: { viewModel.setString(name, $0) }
                ))
                .multilineTextAlignment(.trailing)
                .padding(8)
                .background(Color.black.opacity(0.45))
                .cornerRadius(12)
                .foregroundColor(.white)
                .focused($focusedField, equals: name)
            }

        case .color(let name, _):
            ColorPicker(name, selection: Binding(
                get: { viewModel.colorValues[name] ?? .randomVivid() },
                set: { viewModel.setColor(name, $0) }
            ))

        case .image(let name, _):
            HStack {
                Text(name)
                Spacer()
                TextField("filename.png", text: Binding(
                    get: { viewModel.imageNames[name] ?? "" },
                    set: { viewModel.setImage(name, filename: $0) }
                ))
                .multilineTextAlignment(.trailing)
                .padding(8)
                .background(Color.black.opacity(0.45))
                .cornerRadius(12)
                .foregroundColor(.white)
                .focused($focusedField, equals: name)
            }

        case .list:
            EmptyView()
        }
    }
}
