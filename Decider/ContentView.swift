import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "dice")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("Decider")
                .font(.largeTitle)
                .bold()
            
            Text("This utility works best as an App Clip!")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "square.and.arrow.up",
                          text: "Share any list to quickly pick a random item")
                
                FeatureRow(icon: "bolt",
                          text: "Access instantly without installation")
                
                FeatureRow(icon: "arrow.up.heart",
                          text: "Perfect for quick decisions")
            }
            .padding(.vertical)
            
            Text("To use Decider, simply share text from any app and select Decider from the share sheet.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(text)
        }
    }
}


#Preview {
    ContentView()
}
