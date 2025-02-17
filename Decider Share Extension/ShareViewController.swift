import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Social
import MobileCoreServices

// MARK: - State Object
class DeciderState: ObservableObject {
    @Published var items: [String] = []
    @Published var selectedItem: String?
    @Published var title: String?

    private func isCheckboxLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("[") && trimmed.count >= 3 &&
               (trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)] == "]")
    }

    private func processLine(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty lines
        guard !trimmed.isEmpty else { return nil }

        // Check for checkbox notation
        if trimmed.hasPrefix("[") && trimmed.count >= 3 {
            let checkboxContent = trimmed[trimmed.index(trimmed.startIndex, offsetBy: 1)]
            let restOfLine = String(trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces))

            // Skip checked items [x] or [X]
            if checkboxContent.lowercased() == "x" {
                return nil
            }

            // Remove the "[ ] " prefix from unchecked items
            return restOfLine
        }

        return nil // Ignore non-checkbox lines if we're in checkbox mode
    }

    func processText(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Check if any line has checkbox notation
        let hasCheckboxes = lines.contains { isCheckboxLine($0) }

        if hasCheckboxes {
            // If we have checkboxes, only process checkbox lines
            items = lines.compactMap(processLine)

            // Check for a title (single non-checkbox line at the start)
            if !lines.isEmpty && !isCheckboxLine(lines[0]) {
                let potentialTitle = lines[0]
                // Verify the next non-empty line is a checkbox
                if lines.dropFirst().first(where: { !$0.isEmpty }).map(isCheckboxLine) ?? false {
                    title = potentialTitle
                }
            } else {
                title = nil
            }
        } else {
            // If no checkboxes, process all non-empty lines
            items = lines
            title = nil
        }

        selectedItem = items.randomElement()
    }

    func pickAgain() {
        selectedItem = items.randomElement()
    }
}

class ShareViewController: UIViewController {
    private let state = DeciderState()

    override func viewDidLoad() {
        super.viewDidLoad()
        processSharedText()
    }

    private func processSharedText() {
        // Get the first text item from the extension context
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.showError()
            return
        }

        // Check if text is available
        if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
            itemProvider.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { [weak self] (item, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if let error = error {
                        print("Error loading text: \(error)")
                        self.showError()
                        return
                    }

                    var text: String?
                    if let textData = item as? Data {
                        text = String(data: textData, encoding: .utf8)
                    } else if let textString = item as? String {
                        text = textString
                    } else if let url = item as? URL {
                        text = try? String(contentsOf: url)
                    }

                    guard let finalText = text else {
                        self.showError()
                        return
                    }

                    // Process the text into items
                    self.state.processText(finalText)

                    if self.state.items.count < 2 {
                        self.showError(message: "Please provide at least 2 items to choose from")
                    } else {
                        // Show the result view
                        self.showResultView()
                    }
                }
            }
        } else {
            // Try alternative text type
            itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { [weak self] (item, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if let error = error {
                        print("Error loading text: \(error)")
                        self.showError()
                        return
                    }

                    var text: String?
                    if let textData = item as? Data {
                        text = String(data: textData, encoding: .utf8)
                    } else if let textString = item as? String {
                        text = textString
                    } else if let url = item as? URL {
                        text = try? String(contentsOf: url)
                    }

                    guard let finalText = text else {
                        self.showError()
                        return
                    }

                    // Process the text into items
                    self.state.processText(finalText)

                    if self.state.items.count < 2 {
                        self.showError(message: "Please provide at least 2 items to choose from")
                    } else {
                        // Show the result view
                        self.showResultView()
                    }
                }
            }
        }
    }

    private func showResultView() {
        let hostingController = UIHostingController(
            rootView: DeciderView(
                state: state,
                onDone: { [weak self] in
                    // Create a return item to signal completion
                    let returnProvider = NSItemProvider(item: self?.state.selectedItem as NSString?, typeIdentifier: kUTTypePlainText as String)
                    let returnItem = NSExtensionItem()
                    returnItem.attachments = [returnProvider]

                    self?.extensionContext?.completeRequest(returningItems: [returnItem])
                }
            )
        )

        // Add the SwiftUI view
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }

    private func showError(message: String = "Could not process the shared content") {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: { [weak self] _ in
                // Create an empty return item to signal completion
                let returnItem = NSExtensionItem()
                self?.extensionContext?.completeRequest(returningItems: [returnItem])
            }
        ))

        present(alert, animated: true)
    }
}

// MARK: - SwiftUI View
struct DeciderView: View {
    @ObservedObject var state: DeciderState
    let onDone: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let title = state.title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 5)
                }

                Text("\(state.items.count) items in list")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                AnimatedSelectionView(
                    items: state.items,
                    onComplete: { selected in
                        state.selectedItem = selected
                    }
                )
            }
            .padding()
            .navigationTitle("Decider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
        }
    }
}