//
//  ParametersCardView.swift
//  RiveTestApp
//
//  Floating translucent card that renders one control per ParamSpec declared for the item.
//

import SwiftUI
import Foundation

struct ParametersCardView: View {
    let viewModel: AnimationDetailViewModel
    /// Bound so text fields here can drive the parent's keyboard-avoidance behavior.
    @FocusState.Binding var focusedField: String?
    @State private var selectedParameterID: String?

    private let parameterWidth: CGFloat = 92

    private var inputs: [ParamSpec] {
        viewModel.item.inputs.filter {
            if case .list = $0 { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            if let selectedInput {
                control(for: selectedInput)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            GeometryReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 8) {
                        ForEach(inputs) { input in
                            Button {
                                focusedField = nil
                                withAnimation(.snappy) {
                                    selectedParameterID = input.id
                                }
                            } label: {
                                VStack(spacing: 3) {
                                    Image(systemName: symbol(for: input))
                                        .font(.caption.weight(.semibold))
                                    Text(input.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .frame(width: parameterWidth, height: 44)
                                .foregroundStyle(selectedParameterID == input.id ? .primary : .secondary)
                                .background(
                                    selectedParameterID == input.id ? Color.white.opacity(0.18) : .clear,
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                            .id(input.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, max(0, (proxy.size.width - parameterWidth) / 2), for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedParameterID, anchor: .center)
            }
            .frame(height: 44)
        }
        .padding(6)
        .background(Color.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .onAppear {
            selectedParameterID = selectedParameterID ?? inputs.first?.id
        }
        .onChange(of: selectedParameterID) { _, _ in
            focusedField = nil
        }
        .sensoryFeedback(.selection, trigger: selectedParameterID)
    }

    private var selectedInput: ParamSpec? {
        guard let selectedParameterID else { return inputs.first }
        return inputs.first { $0.id == selectedParameterID }
    }

    @ViewBuilder
    private func control(for input: ParamSpec) -> some View {
        switch input {
        case .number(let name, let defaultValue, let range, let precision):
            if let range, range.lowerBound < range.upperBound {
                VStack(spacing: 3) {
                    Slider(
                        value: numberBinding(for: name, defaultValue: defaultValue),
                        in: range,
                        step: pow(10, Double(-precision))
                    )
                    .tint(.white)

                    HStack {
                        Text(formattedNumber(range.lowerBound, precision: precision))
                        Spacer()
                        Text(formattedNumber(value(for: name, defaultValue: defaultValue), precision: precision))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formattedNumber(range.upperBound, precision: precision))
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                .sensoryFeedback(.selection, trigger: value(for: name, defaultValue: defaultValue))
            } else {
                TextField("Value", value: numberBinding(for: name, defaultValue: defaultValue), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .focused($focusedField, equals: name)
            }

        case .boolean(let name, _):
            Toggle("Enabled", isOn: Binding(
                get: { viewModel.boolValues[name] ?? false },
                set: { viewModel.setBool(name, $0) }
            ))
            .toggleStyle(.switch)
            .tint(.white)

        case .string(let name, _):
            TextField("Text", text: Binding(
                get: { viewModel.stringValues[name] ?? "" },
                set: { viewModel.setString(name, $0) }
            ))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .focused($focusedField, equals: name)

        case .color(let name, _):
            ColorPicker("Color", selection: Binding(
                get: { viewModel.colorValues[name] ?? .randomVivid() },
                set: { viewModel.setColor(name, $0) }
            ))
            .tint(.white)

        case .image(let name, _):
            TextField("filename.png", text: Binding(
                get: { viewModel.imageNames[name] ?? "" },
                set: { viewModel.setImage(name, filename: $0) }
            ))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .focused($focusedField, equals: name)

        case .list:
            EmptyView()
        }
    }

    private func numberBinding(for name: String, defaultValue: Double?) -> Binding<Double> {
        Binding(
            get: { viewModel.numberValues[name] ?? defaultValue ?? 0 },
            set: { viewModel.setNumber(name, $0) }
        )
    }

    private func value(for name: String, defaultValue: Double?) -> Double {
        viewModel.numberValues[name] ?? defaultValue ?? 0
    }

    private func formattedNumber(_ value: Double, precision: Int) -> String {
        precision == 0
            ? String(Int(value.rounded()))
            : String(format: "%.*f", precision, value)
    }

    private func symbol(for input: ParamSpec) -> String {
        switch input {
        case .number: return "dial.medium"
        case .boolean: return "switch.2"
        case .string: return "textformat"
        case .color: return "paintpalette"
        case .image: return "photo"
        case .list: return "list.bullet"
        }
    }
}
