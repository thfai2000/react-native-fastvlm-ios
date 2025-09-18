import Foundation
import UIKit
import AVFoundation
import SwiftUI

@objc(FastVLMCameraViewManager)
class FastVLMCameraViewManager: RCTViewManager {
  override func view() -> UIView! {
    let cameraView = CameraPreviewView()
    return cameraView
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

@objc(FastVLMCameraModule)
class FastVLMCameraModule: NSObject, RCTBridgeModule {
  static func moduleName() -> String! {
    return "FastVLMCameraModule"
  }

  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  private let fastVLMModel = FastVLMModel()

  @objc(analyzeCameraData:withPrompt:withResolver:withRejecter:)
  func analyzeCameraData(cameraData: String, prompt: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    Task {
      do {
        // Use the FastVLM model to analyze the data
        let result = try await fastVLMModel.generateResponse(prompt: prompt)
        DispatchQueue.main.async {
          resolve(result)
        }
      } catch {
        DispatchQueue.main.async {
          reject("ANALYSIS_ERROR", "Failed to analyze camera data: \(error.localizedDescription)", error)
        }
      }
    }
  }
}

// CameraPreviewView: Wrap your camera preview logic here
class CameraPreviewView: UIView {
  private let statusLabel: UILabel = UILabel()
  private let cameraController = CameraController()
  private var previewLayer: AVCaptureVideoPreviewLayer?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
    setupCamera()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
    setupCamera()
  }

  private func setupView() {
    statusLabel.text = "generating"
    statusLabel.textAlignment = .center
    statusLabel.textColor = .white
    statusLabel.backgroundColor = .black.withAlphaComponent(0.5)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(statusLabel)
    NSLayoutConstraint.activate([
      statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
      statusLabel.widthAnchor.constraint(equalTo: widthAnchor),
      statusLabel.heightAnchor.constraint(equalToConstant: 40)
    ])
  }

  private func setupCamera() {
    // Setup camera preview using the CameraController
    cameraController.start()
  }

  // Expose a method to update status text from JS
  @objc func setStatusText(_ text: String) {
    statusLabel.text = text
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
  }
}