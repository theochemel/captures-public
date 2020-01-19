//
//  ExportVideo.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 12/30/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import AVKit
import BrightFutures

func exportVideo(fromURL url: URL, startTime: Double, endTime: Double) -> Future<URL, BackendError> {
    
    let promise = Promise<URL, BackendError>()
    
    let fileManager = FileManager.default
    
    let asset = AVAsset(url: url)
    
    guard let outputURL = URL(string: url.deletingPathExtension().absoluteString + "CLIP-OUTPUT.mp4") else {
        promise.failure(BackendError.error(message: "Couldn't make output url"))
        return promise.future
    }
    
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
        fatalError("Couldn't make export session")
    }
    
    try? fileManager.removeItem(at: outputURL)
    
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    
    let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: CMTimeScale(1.0)), end: CMTime(seconds: endTime, preferredTimescale: CMTimeScale(1.0)))
    
    exportSession.timeRange = timeRange
    exportSession.exportAsynchronously {
        switch exportSession.status {
        case .completed:
            promise.success(outputURL)
        case .failed:
            promise.failure(BackendError.error(message: "Export failed"))
        case .cancelled:
            promise.failure(BackendError.error(message: "Export cancelled"))
        default:
            promise.failure(BackendError.error(message: "Unknown error"))
        }
    }
    
    return promise.future
}
