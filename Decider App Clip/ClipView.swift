import SwiftUI
import UIKit

struct ClipView: View {
    @State private var items: [String] = []
    @State private var selectedItem: String?
    @State private var isProcessingShare = true
    
    var body: some View {
        VStack(spacing: 20) {
            if isProcessingShare {
                ProgressView("Processing your list...")
                    .scaleEffect(1.5)
            } else {
                if !items.isEmpty {
                    VStack(spacing: 16) {
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
                                selectedItem = items.randomElement()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView(
                        "Share a List to Begin",
                        systemImage: "square.and.arrow.up",
                        description: Text("Share text from any app to pick a random item")
                    )
                }
            }
        }
        .padding()
        .onAppear {
            checkForSharedText()
        }
    }
    
    private func checkForSharedText() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            isProcessingShare = false
            return
        }
        
        if let context = root.extensionContext,
           let item = context.inputItems.first as? NSExtensionItem,
           let provider = item.attachments?.first {
            
            provider.loadItem(forTypeIdentifier: "public.plain-text") { (data, error) in
                DispatchQueue.main.async {
                    if let text = data as? String {
                        self.items = text.components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        self.selectedItem = self.items.randomElement()
                    }
                    self.isProcessingShare = false
                }
            }
        } else {
            isProcessingShare = false
        }
    }
}

#Preview {
    ClipView()
}
