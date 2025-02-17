import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Social

class ShareViewController: UIViewController {
    private var items: [String] = []
    private var selectedItem: String?

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

        // Load the text content
        itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] (data, error) in
            DispatchQueue.main.async {
                guard let self = self,
                      let text = data as? String else {
                    self?.showError()
                    return
                }

                // Process the text into items
                self.items = text.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                if self.items.isEmpty {
                    self.showError(message: "No items found in the shared text")
                } else {
                    // Pick a random item and show the result view
                    self.selectedItem = self.items.randomElement()
                    self.showResultView()
                }
            }
        }
    }

    private func showResultView() {
        let hostingController = UIHostingController(
            rootView: DeciderView(
                items: items,
                selectedItem: selectedItem,
                onPickAgain: { [weak self] in
                    self?.selectedItem = self?.items.randomElement()
                },
                onDone: { [weak self] in
                    self?.extensionContext?.completeRequest(returningItems: nil)
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
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        ))

        present(alert, animated: true)
    }
}

// MARK: - SwiftUI View
struct DeciderView: View {
    let items: [String]
    let selectedItem: String?
    let onPickAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dice")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)

                Text("\(items.count) items in list")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if let selected = selectedItem {
                    Text(selected)
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }

                Button("Pick Again") {
                    withAnimation {
                        onPickAgain()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Random Pick")
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