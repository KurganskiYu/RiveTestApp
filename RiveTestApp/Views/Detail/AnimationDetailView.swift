//
//  AnimationDetailView.swift
//  RiveTestApp
//
//  Interactive animation screen: main/preview toggle, parameters overlay card, trigger button.
//

import SwiftUI
import RiveRuntime

struct AnimationDetailView: View {
    let item: CatalogItem

    @State private var viewModel: AnimationDetailViewModel
    @State private var showParameters = false
    @State private var showCodeSheet = false
    @FocusState private var focusedField: String?

    init(item: CatalogItem) {
        self.item = item
        _viewModel = State(initialValue: AnimationDetailViewModel(item: item))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { proxy in
            ZStack {
                RiveBackgroundView(mode: viewModel.backgroundMode)
                    .ignoresSafeArea()

                VStack {
                    Spacer(minLength: 0)
                    animationView
                        .scaleEffect(focusedField != nil ? 0.55 : 1, anchor: .center)
                        .offset(y: focusedField != nil ? -proxy.size.height * 0.18 : 0)
                        .animation(.easeInOut(duration: 0.25), value: focusedField != nil)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showParameters {
                    VStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = nil
                                withAnimation { showParameters = false }
                            }
                            .accessibilityLabel("Close parameters")
                            .accessibilityAddTraits(.isButton)

                        Color.clear.frame(height: 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .bottomLeading) {
                BackgroundSwitcherView(mode: $viewModel.backgroundMode)
                    .padding(.leading, 12)
                    .padding(.bottom, 6)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if showParameters {
                    ParametersCardView(
                        viewModel: viewModel,
                        focusedField: $focusedField
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    bottomBar(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.snappy, value: showParameters)
                .padding(.horizontal, showParameters ? 0 : 16)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.25))
        }
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .environment(\.colorScheme, .dark)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCodeSheet = true
                } label: {
                    Label("Get Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
        .sheet(isPresented: $showCodeSheet) {
            CodeSnippetView(item: item)
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var animationView: some View {
        if let rive = viewModel.currentRive {
            RiveUIViewRepresentable(rive: rive)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.33), lineWidth: 0.33)
                )
        } else if let error = viewModel.loadError {
            ContentUnavailableView(
                "Couldn't load animation",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else {
            ProgressView()
        }
    }

    private var aspectRatio: CGFloat {
        let size = (viewModel.mode == .preview) ? (item.previewSize ?? item.size) : item.size
        guard size.width > 0, size.height > 0 else { return 1 }
        return size.width / size.height
    }

    @ViewBuilder
    private func bottomBar(viewModel: AnimationDetailViewModel) -> some View {
        @Bindable var viewModel = viewModel

        HStack(spacing: 20) {
            if viewModel.hasPreview {
                Picker("Mode", selection: $viewModel.mode) {
                    Text("Main").tag(DetailDisplayMode.main)
                    Text("Preview").tag(DetailDisplayMode.preview)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
            }

            Spacer()

            if !item.inputs.isEmpty {
                Button {
                    focusedField = nil
                    withAnimation { showParameters.toggle() }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .tint(showParameters ? .white : .secondary)
                .accessibilityLabel("Parameters")
                .help("Parameters")
            }

            if item.trigger != nil {
                Button {
                    viewModel.fireTrigger()
                } label: {
                    Image(systemName: "bolt.fill")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .tint(.secondary)
                .accessibilityLabel("Trigger")
                .help("Trigger")
            }
        }
        .font(.body)
    }
}
