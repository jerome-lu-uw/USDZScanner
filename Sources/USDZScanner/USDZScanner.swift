import RealityKit
import SwiftUI
import os
import UIKit

@available(iOS 17.0, *)
/// The root of the SwiftUI view graph.
public struct USDZScanner: View {
    static let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                                category: "ContentView")
    
    let onCompletedCallback: (URL) -> Void
    public init(onCompletedCallback: @escaping (URL) -> Void) {
        self.onCompletedCallback = onCompletedCallback
    }

    @StateObject var appModel: AppDataModel = AppDataModel.instance
    
    @State private var showReconstructionView: Bool = false
    @State private var showErrorAlert: Bool = false
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }

    public var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            } else if showProgressView {
                CircularProgressView()
            }
        }
        .onChange(of: appModel.state) { _, newState in
            if newState == .failed {
                showErrorAlert = true
                showReconstructionView = false
            } else {
                showErrorAlert = false
                showReconstructionView = newState == .reconstructing || newState == .viewing
            }
        }
        .sheet(isPresented: $showReconstructionView) {
            if let folderManager = appModel.scanFolderManager {
                ReconstructionPrimaryView(outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"), onCompletedCallback: onCompletedCallback)
            }
        }
        .alert(
            "Failed:  " + (appModel.error != nil  ? "\(String(describing: appModel.error!))" : ""),
            isPresented: $showErrorAlert,
            actions: {
                Button("OK") {
                    USDZScanner.logger.log("Calling restart...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
        .environmentObject(appModel)
    }
}

private struct CircularProgressView: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .green))
                Spacer()
            }
            Spacer()
        }
        .background(HapticFeedbackHelper()) // Add the haptic feedback helper here
    }
}

struct HapticFeedbackHelper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#if DEBUG
@available(iOS 17.0, *)
struct USDZScanner_Previews: PreviewProvider {
    static var previews: some View {
        USDZScanner() { url in }
    }
}
#endif
