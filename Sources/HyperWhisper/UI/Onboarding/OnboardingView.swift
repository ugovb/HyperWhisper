import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @State private var currentStep = 0
    var onClose: (() -> Void)? = nil
    
    // Remove @Environment(\.dismiss) as we manage window manually

    
    var body: some View {
        VStack {
            // Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: index == currentStep ? 24 : 8, height: 4)
                        .animation(.spring, value: currentStep)
                }
            }
            .padding(.top, 32)
            
            // Steps Container
            ZStack {
                switch currentStep {
                case 0:
                    WelcomeSlide(onNext: nextStep)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 1:
                    PermissionsSlide(onNext: nextStep)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 2:
                    LanguageSlide(onNext: nextStep)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 3:
                    TutorialSlide(onFinish: finishOnboarding)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: currentStep)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 600, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func nextStep() {
        if currentStep < 3 {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    private func finishOnboarding() {
        SettingsManager.shared.hasCompletedOnboarding = true
        // Use explicit callback if provided
        onClose?()

    }
}

// MARK: - Slides (Unchanged logic, just ensure types match)

// MARK: - Slide 1: Welcome
struct WelcomeSlide: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.hyperAccentGradient)
            
            VStack(spacing: 8) {
                Text("Welcome to HyperWhisper")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your voice, perfected by AI.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Get Started") { onNext() }
                .buttonStyle(OnboardingButtonStyle())
        }
        .padding(48)
    }
}

// MARK: - Slide 2: Permissions
// MARK: - Slide 2: Permissions & Setup
struct PermissionsSlide: View {
    var onNext: () -> Void
    
    @StateObject private var permissions = PermissionManager.shared
    @StateObject private var downloader = ModelDownloader()
    
    @State private var micGranted = false
    @State private var accessibilityGranted = false
    @State private var selectedModel: ModelDownloader.ModelType = .parakeet
    
    // Check if model exists
    var isModelDownloaded: Bool {
        return downloader.isModelAvailable(type: selectedModel)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Grant permissions and download the speech model to get started...")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // Accessibility
                OnboardingRow(
                    title: "Accessibility",
                    subtitle: "Required for global hotkey detection",
                    actionView: {
                        if accessibilityGranted {
                            Text("Granted")
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        } else {
                            Button("Grant") {
                                permissions.requestAccessibility()
                                checkPermissions()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                )
                
                Divider()
                
                // Microphone
                OnboardingRow(
                    title: "Microphone",
                    subtitle: "Required for voice recording",
                    actionView: {
                        if micGranted {
                            Text("Granted")
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        } else {
                            Button("Grant") {
                                permissions.requestMicrophone()
                                checkPermissions()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                )
                
                Divider()
                
                // Speech Model
                OnboardingRow(
                    title: "Speech Model",
                    subtitle: isModelDownloaded ? "Installed locally" : "~140MB download, runs locally",
                    actionView: {
                        HStack {
                            if !isModelDownloaded && !downloader.isDownloading {
                                Picker("Model", selection: $selectedModel) {
                                    ForEach(ModelDownloader.ModelType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                            
                            if isModelDownloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if downloader.isDownloading {
                                ProgressView(value: downloader.downloadProgress)
                                    .frame(width: 60)
                            } else {
                                Button("Download") {
                                    Task { await downloader.downloadModel(type: selectedModel) }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                )
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            
            if let error = downloader.lastError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            Button("Continue") { onNext() }
                .buttonStyle(OnboardingButtonStyle())
                .disabled(!micGranted || !accessibilityGranted || !isModelDownloaded)
        }
        .padding(32)
        .onAppear(perform: checkPermissions)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        permissions.checkPermissions()
        micGranted = permissions.microphoneGranted
        accessibilityGranted = permissions.accessibilityGranted
    }
}

struct OnboardingRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let actionView: () -> Content
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            actionView()
        }
        .padding(16)
    }
}


struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
                .foregroundStyle(isGranted ? .green : .blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else {
                Button("Allow", action: action)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .opacity(isGranted ? 0.6 : 1.0)
    }
}

// MARK: - Slide 3: Language
struct LanguageSlide: View {
    var onNext: () -> Void
    
    @State private var selectedLanguage = "en"
    
    let languages = [
        ("English", "en"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de"),
        ("Italian", "it"),
        ("Portuguese", "pt")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Primary Language")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select your primary dictation language.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Picker("Language", selection: $selectedLanguage) {
                ForEach(languages, id: \.1) { language in
                    Text(language.0).tag(language.1)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .frame(maxHeight: 200)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
            
            Button("Continue") {
                print("Selected Language: \(selectedLanguage)")
                onNext()
            }
            .buttonStyle(OnboardingButtonStyle())
        }
        .padding(48)
    }
}

// MARK: - Slide 4: Tutorial & Test
struct TutorialSlide: View {
    var onFinish: () -> Void
    
    @EnvironmentObject var appState: AppState
    @State private var hasRecorded = false
    @State private var isModelLoading = true
    @State private var modelError: String?
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Test Your Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Record a short clip to verify everything works.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Interaction Area
            VStack(spacing: 24) {
                if isModelLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Preparing AI model...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("This may take a few seconds on first launch")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(height: 100)
                } else if let error = modelError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text("Model loading failed")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            loadModel()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(height: 100)
                } else if appState.isRecording {
                    VStack {
                        // Real Visualizer
                        AudioVisualizerView(amplitude: appState.audioLevel, barCount: 30, barSpacing: 4)
                            .frame(height: 60)
                            .padding()
                        
                        Text("Recording...")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                    .frame(height: 100)
                } else if hasRecorded || !appState.currentTranscript.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        Text("Transcription Verified!")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(appState.currentTranscript.isEmpty ? "Recording complete" : "Detected \(Set(appState.currentTranscript.map(\.speakerID)).count) speaker(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 100)
                } else {
                    HStack(spacing: 8) {
                        KeyCap("Right Option (Hold)")
                    }
                    .frame(height: 100)
                }
                
                Button(appState.isRecording ? "Stop Recording" : "Start Test Recording") {
                    appState.toggleRecording()
                }
                .buttonStyle(.bordered)
                .disabled(isModelLoading || modelError != nil)
            }
            
            Spacer()
            
            // Auto-close handles completion, button removed to prevent manual conflict/crash issues
            Text(hasRecorded ? "Setup will complete automatically..." : "")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(48)
        .onAppear {
            loadModel()
        }
        .onChange(of: appState.isRecording) { isRecording in
            if !isRecording && !hasRecorded && !isModelLoading {
                withAnimation {
                    hasRecorded = true
                }
                // Auto-close onboarding after a short delay for visual feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onFinish()
                }
            }
        }
    }
    
    private func loadModel() {
        isModelLoading = true
        modelError = nil
        
        Task {
            do {
                try await appState.parakeetEngine.initialize()
                await MainActor.run {
                    isModelLoading = false
                }
            } catch {
                await MainActor.run {
                    isModelLoading = false
                    modelError = error.localizedDescription
                }
            }
        }
    }
}

struct KeyCap: View {
    let symbol: String
    
    init(_ symbol: String) {
        self.symbol = symbol
    }
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 2)
            )
            .cornerRadius(8)
    }
}

// MARK: - Shared Styles
struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 48)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
