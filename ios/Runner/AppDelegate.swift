import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.sasang.app/timeline",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "encodeTimeline" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
          return
        }
        TimelineVideoExporter.encode(arguments: arguments) { exportResult in
          DispatchQueue.main.async {
            switch exportResult {
            case .success:
              result(true)
            case .failure(let error):
              result(
                FlutterError(
                  code: "timeline_encode_failed",
                  message: error.localizedDescription,
                  details: nil
                )
              )
            }
          }
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private enum TimelineVideoError: LocalizedError {
  case invalidArguments
  case cannotCreateWriter(String)
  case cannotStartWriter(String)
  case cannotDecodeFrame(String)
  case cannotCreatePixelBuffer
  case cannotAppendFrame(String)

  var errorDescription: String? {
    switch self {
    case .invalidArguments:
      return "Invalid timeline export arguments."
    case .cannotCreateWriter(let message):
      return "Cannot create video writer: \(message)"
    case .cannotStartWriter(let message):
      return "Cannot start video writer: \(message)"
    case .cannotDecodeFrame(let path):
      return "Cannot decode timeline frame: \(path)"
    case .cannotCreatePixelBuffer:
      return "Cannot create a timeline pixel buffer."
    case .cannotAppendFrame(let message):
      return "Cannot append timeline frame: \(message)"
    }
  }
}

private enum TimelineVideoExporter {
  static func encode(
    arguments: [String: Any],
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        guard
          let framePaths = arguments["framePaths"] as? [String],
          let repeats = arguments["repeats"] as? [Int],
          let outputPath = arguments["outputPath"] as? String,
          !framePaths.isEmpty,
          framePaths.count == repeats.count
        else {
          throw TimelineVideoError.invalidArguments
        }
        let width = arguments["width"] as? Int ?? 720
        let height = arguments["height"] as? Int ?? 1280
        let fps = arguments["fps"] as? Int ?? 12
        let bitrate = arguments["bitrate"] as? Int ?? 5_000_000
        let outputURL = URL(fileURLWithPath: outputPath)
        try? FileManager.default.removeItem(at: outputURL)
        try FileManager.default.createDirectory(
          at: outputURL.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )

        let writer: AVAssetWriter
        do {
          writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
          throw TimelineVideoError.cannotCreateWriter(error.localizedDescription)
        }
        let settings: [String: Any] = [
          AVVideoCodecKey: AVVideoCodecType.h264,
          AVVideoWidthKey: width,
          AVVideoHeightKey: height,
          AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: bitrate,
            AVVideoExpectedSourceFrameRateKey: fps,
            AVVideoMaxKeyFrameIntervalKey: fps,
          ],
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let attributes: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
          kCVPixelBufferWidthKey as String: width,
          kCVPixelBufferHeightKey as String: height,
          kCVPixelBufferCGImageCompatibilityKey as String: true,
          kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
          assetWriterInput: input,
          sourcePixelBufferAttributes: attributes
        )
        guard writer.canAdd(input) else {
          throw TimelineVideoError.cannotCreateWriter("Video input is unsupported.")
        }
        writer.add(input)
        guard writer.startWriting() else {
          throw TimelineVideoError.cannotStartWriter(
            writer.error?.localizedDescription ?? "Unknown error"
          )
        }
        writer.startSession(atSourceTime: .zero)

        var frameNumber: Int64 = 0
        for index in framePaths.indices {
          guard let image = UIImage(contentsOfFile: framePaths[index]) else {
            throw TimelineVideoError.cannotDecodeFrame(framePaths[index])
          }
          let repeatCount = max(1, repeats[index])
          for _ in 0..<repeatCount {
            while !input.isReadyForMoreMediaData {
              if writer.status == .failed {
                throw TimelineVideoError.cannotAppendFrame(
                  writer.error?.localizedDescription ?? "Writer failed."
                )
              }
              Thread.sleep(forTimeInterval: 0.002)
            }
            guard let buffer = makePixelBuffer(
              image: image,
              width: width,
              height: height,
              pool: adaptor.pixelBufferPool
            ) else {
              throw TimelineVideoError.cannotCreatePixelBuffer
            }
            let time = CMTime(value: frameNumber, timescale: CMTimeScale(fps))
            guard adaptor.append(buffer, withPresentationTime: time) else {
              throw TimelineVideoError.cannotAppendFrame(
                writer.error?.localizedDescription ?? "Unknown error"
              )
            }
            frameNumber += 1
          }
        }

        input.markAsFinished()
        writer.finishWriting {
          if writer.status == .completed {
            completion(.success(()))
          } else {
            completion(
              .failure(
                TimelineVideoError.cannotAppendFrame(
                  writer.error?.localizedDescription ?? "Video finalization failed."
                )
              )
            )
          }
        }
      } catch {
        completion(.failure(error))
      }
    }
  }

  private static func makePixelBuffer(
    image: UIImage,
    width: Int,
    height: Int,
    pool: CVPixelBufferPool?
  ) -> CVPixelBuffer? {
    var buffer: CVPixelBuffer?
    if let pool {
      CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
    } else {
      CVPixelBufferCreate(
        nil,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        [
          kCVPixelBufferCGImageCompatibilityKey: true,
          kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ] as CFDictionary,
        &buffer
      )
    }
    guard let pixelBuffer = buffer else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
    guard
      let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
      let context = CGContext(
        data: baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
          | CGBitmapInfo.byteOrder32Little.rawValue
      )
    else { return nil }
    context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    guard let cgImage = image.cgImage else { return nil }
    // The BGRA video buffer mirrors Core Graphics horizontally. Compensate on
    // that axis only; a UIKit-style vertical flip would turn the MP4 upside down.
    context.translateBy(x: CGFloat(width), y: 0)
    context.scaleBy(x: -1, y: 1)
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    return pixelBuffer
  }
}
