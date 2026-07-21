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
            }
            .overlay(alignment: .bottom) {
                if showParameters {
                    ParametersCardView(viewModel: viewModel, focusedField: $focusedField)
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                BackgroundSwitcherView(mode: $viewModel.backgroundMode)
                bottomBar(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
        }
        .navigationTitle(item.src)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .environment(\.colorScheme, .dark)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var animationView: some View {
        if let rive = viewModel.currentRive {
            RiveUIViewRepresentable(rive: rive)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .padding(8)
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
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
            }

            if item.trigger != nil {
                Button {
                    viewModel.fireTrigger()
                } label: {
                    Label("Trigger", systemImage: "bolt.fill")
                }
            }
        }
        .font(.title3)
    }
}
