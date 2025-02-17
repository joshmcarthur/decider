import SwiftUI
import VisionKit
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
#endif

class DecisionHistory: ObservableObject {
    struct Decision: Identifiable, Codable {
        let id = UUID()
        let timestamp: Date
        let selectedItem: String
        let totalItems: Int
        let title: String?
    }

    @Published var decisions: [Decision] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: "decisionHistory"),
           let decoded = try? JSONDecoder().decode([Decision].self, from: data) {
            decisions = decoded
        }
    }

    func addDecision(selected: String, from total: Int, title: String? = nil) {
        let decision = Decision(timestamp: Date(), selectedItem: selected, totalItems: total, title: title)
        decisions.insert(decision, at: 0)

        // Keep only last 50 decisions
        if decisions.count > 50 {
            decisions = Array(decisions.prefix(50))
        }

        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(decisions) {
            UserDefaults.standard.set(encoded, forKey: "decisionHistory")
        }
    }

    func clearHistory() {
        decisions.removeAll()
        save()
    }
}

@MainActor
class QuickInputState: ObservableObject {
    @Published var showingScanner = false
    @Published var showingResult = false
    @Published var selectedItem: String?
    @Published var items: [String] = []
    @Published var title: String?
    @Published var errorMessage: String?

    var isScanning: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }

    var hasClipboardString: Bool {
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string) != nil
        #else
        return UIPasteboard.general.hasStrings
        #endif
    }

    func getClipboardString() -> String? {
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #else
        return UIPasteboard.general.string
        #endif
    }

    func processText(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Check if any line has checkbox notation
        let hasCheckboxes = lines.contains { line in
            line.hasPrefix("[") && line.count >= 3 && line[line.index(line.startIndex, offsetBy: 2)] == "]"
        }

        if hasCheckboxes {
            // Process as checkbox list
            items = lines.compactMap { line in
                guard line.hasPrefix("[") && line.count >= 3 else { return nil }
                let checkboxContent = line[line.index(line.startIndex, offsetBy: 1)]
                if checkboxContent.lowercased() == "x" { return nil }
                return String(line.dropFirst(3).trimmingCharacters(in: .whitespaces))
            }

            // Check for title
            if !lines.isEmpty && !lines[0].hasPrefix("[") {
                title = lines[0]
            }
        } else {
            items = lines
            title = nil
        }

        if items.isEmpty {
            errorMessage = "No items found in the text"
            return
        }

        if items.count == 1 {
            errorMessage = "Add one more item to make a decision"
            return
        }

        errorMessage = nil
        selectedItem = items.randomElement()
        showingResult = true
    }
}

struct ContentView: View {
    @StateObject private var history = DecisionHistory()
    @StateObject private var quickInput = QuickInputState()
    @State private var showingInfo = false

    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    Button {
                        Task {
                            if let string = quickInput.getClipboardString() {
                                await MainActor.run {
                                    quickInput.processText(string)
                                }
                            }
                        }
                    } label: {
                        Label("Use from Clipboard", systemImage: "doc.on.clipboard")
                    }
                    .disabled(!quickInput.hasClipboardString)

                    if quickInput.isScanning {
                        Button {
                            quickInput.showingScanner = true
                        } label: {
                            Label("Scan Text", systemImage: "text.viewfinder")
                        }
                    }
                } header: {
                    Text("Quick Input")
                }

                Section {
                    InstructionRow(
                        number: 1,
                        title: "Select Text",
                        description: "In any app, select the text containing your list items",
                        icon: "text.cursor"
                    )

                    InstructionRow(
                        number: 2,
                        title: "Share",
                        description: "Tap the Share button and select 'Decider'",
                        icon: "square.and.arrow.up"
                    )

                    InstructionRow(
                        number: 3,
                        title: "Get Result",
                        description: "A random item will be selected from your list",
                        icon: "checkmark.circle"
                    )
                } header: {
                    Text("How to Use")
                }

                if !history.decisions.isEmpty {
                    Section {
                        ForEach(history.decisions) { decision in
                            DecisionRow(decision: decision)
                        }
                    } header: {
                        HStack {
                            Text("Recent Decisions")
                            Spacer()
                            Button("Clear") {
                                history.clearHistory()
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        TipsView()
                    } label: {
                        Label("Tips & Examples", systemImage: "lightbulb")
                    }

                    NavigationLink {
                        StatsView(history: history)
                    } label: {
                        Label("Statistics", systemImage: "chart.bar")
                    }
                } header: {
                    Text("More")
                }
            }
            .navigationTitle("Decider")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        } detail: {
            WelcomeView()
        }
        .sheet(isPresented: $showingInfo) {
            AboutView()
        }
        .sheet(isPresented: $quickInput.showingScanner) {
            ScannerView(quickInput: quickInput)
        }
        .sheet(isPresented: $quickInput.showingResult) {
            if quickInput.showingResult {
                QuickResultView(
                    quickInput: quickInput,
                    history: history
                )
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dice.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
                .padding()

            Text("Welcome to Decider!")
                .font(.title)
                .fontWeight(.bold)

            Text("Select an option from the sidebar to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("You can paste a list, scan text, or share from another app")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct DecisionRow: View {
    let decision: DecisionHistory.Decision

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = decision.title {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(decision.selectedItem)
                .font(.headline)

            HStack {
                Text(decision.timestamp, style: .relative)
                Text("•")
                Text("from \(decision.totalItems) items")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TipsView: View {
    var body: some View {
        List {
            Section {
                TipRow(
                    title: "Checkbox Lists",
                    description: "Use [ ] for options and [x] for completed items. Only unchecked items will be included.",
                    example: """
                    Shopping List
                    [x] Milk
                    [ ] Bread
                    [ ] Eggs
                    """
                )

                TipRow(
                    title: "Simple Lists",
                    description: "Just share any text with items on separate lines.",
                    example: """
                    Pizza
                    Sushi
                    Burgers
                    """
                )

                TipRow(
                    title: "With Titles",
                    description: "Start with a title line, then your items.",
                    example: """
                    Movie Night
                    [ ] The Matrix
                    [ ] Inception
                    [x] Avatar
                    """
                )
            }
        }
        .navigationTitle("Tips & Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TipRow: View {
    let title: String
    let description: String
    let example: String
    @StateObject private var quickInput = QuickInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(example)
                .font(.system(.subheadline, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button {
                quickInput.processText(example)
            } label: {
                Label("Try this example", systemImage: "play.circle.fill")
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $quickInput.showingResult) {
            QuickResultView(
                quickInput: quickInput,
                history: DecisionHistory()
            )
        }
    }
}

struct StatsView: View {
    @ObservedObject var history: DecisionHistory

    var totalDecisions: Int {
        history.decisions.count
    }

    var averageListSize: Double {
        guard !history.decisions.isEmpty else { return 0 }
        let total = history.decisions.reduce(0) { $0 + $1.totalItems }
        return Double(total) / Double(history.decisions.count)
    }

    var body: some View {
        List {
            StatRow(title: "Total Decisions", value: "\(totalDecisions)")
            StatRow(title: "Average List Size", value: String(format: "%.1f items", averageListSize))

            if let lastDecision = history.decisions.first {
                StatRow(
                    title: "Last Decision",
                    value: lastDecision.selectedItem,
                    detail: "from \(lastDecision.totalItems) items"
                )
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Decider helps you make quick decisions by randomly selecting an item from any list you share.")
                        .font(.subheadline)
                }

                Section {
                    Label("Works with any text app", systemImage: "app")
                    Label("Supports checkbox lists", systemImage: "checkmark.square")
                    Label("Quick and lightweight", systemImage: "bolt")
                    Label("No sign-up required", systemImage: "person.crop.circle.badge.checkmark")
                }

                Section {
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(number)")
                        .font(.callout)
                        .bold()
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)

                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ScannerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var quickInput: QuickInputState

    var body: some View {
        NavigationView {
            DataScannerView(
                processResult: { text in
                    quickInput.processText(text)
                    dismiss()
                }
            )
            .navigationTitle("Scan Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DataScannerView: UIViewControllerRepresentable {
    let processResult: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(processResult: processResult)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let processResult: (String) -> Void

        init(processResult: @escaping (String) -> Void) {
            self.processResult = processResult
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                processResult(text.transcript)
            default:
                break
            }
        }
    }
}

struct QuickResultView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var quickInput: QuickInputState
    @ObservedObject var history: DecisionHistory

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let title = quickInput.title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                AnimatedSelectionView(
                    items: quickInput.items,
                    onComplete: { selected in
                        quickInput.selectedItem = selected
                    }
                )

                List {
                    ForEach(quickInput.items, id: \.self) { item in
                        Text(item)
                    }
                }
            }
            .padding()
            .navigationTitle("Decider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let selected = quickInput.selectedItem {
                            history.addDecision(
                                selected: selected,
                                from: quickInput.items.count,
                                title: quickInput.title
                            )
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
