//
//  GenerateThumbnails.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 12/30/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import AVKit
import BrightFutures


func generateThumbnails(forClip clip: URL, numberOfThumbnails: Int) -> Future<[UIImage?], BackendError> {
    let promise = Promise<[UIImage?], BackendError>()
    
    var thumbnails = [UIImage?](repeating: nil, count: numberOfThumbnails)
    
    let dispatchGroup = DispatchGroup()
    
    let clipAsset = AVAsset(url: clip)
    let clipLength = clipAsset.duration.seconds
    
    let generator = AVAssetImageGenerator(asset: clipAsset)
    
    let thumbnailTimeSpacing = clipLength / Double(numberOfThumbnails)
    
    for x in 0 ..< numberOfThumbnails {
        dispatchGroup.enter()
        generator.generateCGImagesAsynchronously(forTimes: [(thumbnailTimeSpacing * Double(x)) as NSValue]) { (requestedTime, generatedImage, actualTime, result, error) in
            
            guard result == AVAssetImageGenerator.Result.succeeded, let image = generatedImage else {
                fatalError("Thumbnail generation failed")
                //                TODO: Make this less horrible
            }
            thumbnails[x] = UIImage(cgImage: image)
            dispatchGroup.leave()
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        promise.success(thumbnails)
    }
    
    return promise.future
}
