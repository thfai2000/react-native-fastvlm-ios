import Foundation
import UIKit
import AVFoundation
import SwiftUI
import CoreImage
import Vision

// Shared camera manager for coordination between preview and analysis
class SharedCameraManager: ObservableObject {
  static let shared = SharedCameraManager()
  private let cameraController = CameraController()
  private var currentFrame: CMSampleBuffer?
  private let frameQueue = DispatchQueue(label: "frameProcessingQueue", qos: .userInitiated)
  
  private init() {
    setupFrameCapture()
  }
  
  private func setupFrameCapture() {
    Task {
      let frameStream = AsyncStream<CMSampleBuffer> { continuation in
        cameraController.attach(continuation: continuation)
      }
      
      for await frame in frameStream {
        frameQueue.sync {
          self.currentFrame = frame
        }
      }
    }
  }
  
  func startCamera() {
    cameraController.start()
  }
  
  func stopCamera() {
    cameraController.stop()
  }
  
  func getCurrentFrame() -> CMSampleBuffer? {
    return frameQueue.sync {
      return currentFrame
    }
  }
  
  func getCameraController() -> CameraController {
    return cameraController
  }
  
  // Convert CMSampleBuffer to UIImage for FastVLM processing
  func captureCurrentImage() -> UIImage? {
    guard let sampleBuffer = getCurrentFrame(),
          let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return nil
    }
    
    let ciImage = CIImage(cvImageBuffer: imageBuffer)
    let context = CIContext()
    
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
      return nil
    }
    
    return UIImage(cgImage: cgImage)
  }
}


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

  private var fastVLMModel: FastVLMModel?
  private let sharedCameraManager = SharedCameraManager.shared

  override init() {
    super.init()
    Task { @MainActor in
      self.fastVLMModel = FastVLMModel()
    }
  }

    @objc(analyzeCameraData:withResolver:withRejecter:)
  func analyzeCameraData(prompt: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    Task {
      do {
        guard let fastVLMModel = self.fastVLMModel else {
          reject("MODEL_ERROR", "FastVLM model not initialized", nil)
          return
        }
        
        // Capture current camera frame
        guard let currentImage = sharedCameraManager.captureCurrentImage() else {
          // If no camera frame available, proceed with text-only prompt
          let result = try await fastVLMModel.generateResponse(prompt: prompt)
          DispatchQueue.main.async {
            resolve(result)
          }
          return
        }
        
        // Create UserInput with both image and text prompt for FastVLM
        let ciImage = CIImage(cgImage: currentImage.cgImage!)
        let userInput = UserInput(prompt: .text(prompt), images: [.ciImage(ciImage)])
        let task = await fastVLMModel.generate(userInput)
        _ = await task.result
        
        let result = fastVLMModel.output
        DispatchQueue.main.async {
          resolve(result)
        }
      } catch {
        DispatchQueue.main.async {
          reject("ANALYSIS_ERROR", "Failed to analyze camera data: \\(error.localizedDescription)", error)
        }
      }
    }
  }
}

// CameraPreviewView: Wrap your camera preview logic here
class CameraPreviewView: UIView {
  private let statusLabel: UILabel = UILabel()
  private let sharedCameraManager = SharedCameraManager.shared
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
    // Setup camera preview using the shared camera manager
    let cameraController = sharedCameraManager.getCameraController()
    sharedCameraManager.startCamera()
    
    // Setup preview layer
    if let captureSession = cameraController.publicCaptureSession {
      previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      previewLayer?.videoGravity = .resizeAspectFill
      previewLayer?.frame = bounds
      
      if let previewLayer = previewLayer {
        layer.insertSublayer(previewLayer, at: 0)
      }
    }
  }

  // Expose a method to update status text from JS
  @objc func setStatusText(_ text: String) {
    statusLabel.text = text
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
  }
  
  deinit {
    sharedCameraManager.stopCamera()
  }
}