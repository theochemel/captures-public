//
//  BackendIntegration.swift
//  clipthat MessagesExtension
//
//  Created by Theo Chemel on 8/7/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import BrightFutures
import SwiftyJSON
import DateToolsSwift
import Kingfisher

enum BackendError: Error {
    case error(message: String?)
}

class User: Codable {
    var xuid: String!
    var gamerTag: String!
    var thumbnailURL: URL!
}

class Capture {
    var thumbnailURL: URL!
    var mediaURL: URL!
    var localMediaURL: URL!
    var dateRecorded: Date!
    var isVideo: Bool!
    var index: Int!
    
    var isComplete: Bool {
        get {
            return thumbnailURL != nil && mediaURL != nil && dateRecorded != nil && isVideo != nil
        }
    }
}

let baseURL = URL(string: "https://xboxapi.com/v2")!
let xboxAPIKey = "nice try"

func getXUID(ofUser user: User) -> Future<User, BackendError> {
    let promise = Promise<User, BackendError>()
    
    guard user.gamerTag != nil else {
        promise.failure(BackendError.error(message: "No gamertag"))
        return promise.future
    }
    
    let url = baseURL.appendingPathComponent("xuid/\(user.gamerTag!)")
    
    var request = URLRequest(url: url)

    request.setValue(xboxAPIKey, forHTTPHeaderField: "X-AUTH")
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        if let data = data {
            
            let json = try? JSON(data: data)
            
            guard json == nil else {
                promise.failure(BackendError.error(message: "serverError: " + json!["error_message"].stringValue))
                return
            }
            
            guard let xuid = String(bytes: data, encoding: .utf8) else {
                promise.failure(BackendError.error(message: "serializationError: Improper XUID"))
                return
            }
            guard xuid.count == 16 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: xuid)) else {
                promise.failure(BackendError.error(message: "serializationError: Improper XUID"))
                return
            }
            
            let signedInUser = user
            signedInUser.xuid = xuid
            promise.success(signedInUser)
            
        }
        
        if let error = error {
            promise.failure(BackendError.error(message: "requestError: " + error.localizedDescription))
        }
    }
    
    task.resume()
    
    return promise.future
}

func getUserThumbnail(ofUser user: User) -> Future<User, BackendError> {
    let promise = Promise<User, BackendError>()
    
    guard let xuid = user.xuid else {
        promise.failure(BackendError.error(message: "No xuid"))
        return promise.future
    }
    
    let url = baseURL.appendingPathComponent("\(xuid)/profile")
    
    var request = URLRequest(url: url)
    
    request.setValue(xboxAPIKey, forHTTPHeaderField: "X-AUTH")
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        if let data = data {
            
            let json = try? JSON(data: data)
            
            guard json != nil else {
                promise.failure(BackendError.error(message: "JSON serialization failed"))
                return
            }
            
            guard json!["code"].string == nil, json!["errorCode"].string == nil, json!["error"].bool == nil else {
                promise.failure(BackendError.error(message: "Server Error"))
                return
            }
            
            if let thumbnailURL = json!["AppDisplayPicRaw"].url {
                user.thumbnailURL = thumbnailURL
                promise.success(user)
            } else {
                promise.failure(BackendError.error(message: "No thumbnail"))
            }
            
        }
        
        if let error = error {
            promise.failure(BackendError.error(message: "requestError: " + error.localizedDescription))
        }
    }
    
    task.resume()
    
    return promise.future
}

func getFriends(ofUser user: User) -> Future<[User], BackendError> {
    let promise = Promise<[User], BackendError>()
    
    guard user.xuid != nil else {
        promise.failure(BackendError.error(message: "No XUID"))
        return promise.future
    }
    
    let url = baseURL.appendingPathComponent("\(user.xuid!)/friends")
    
    var request = URLRequest(url: url)
    
    request.setValue(xboxAPIKey, forHTTPHeaderField: "X-AUTH")
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        if let data = data {
            do {
                let json = try JSON(data: data)
                
                var results: [User] = []
                
                guard json["error"].bool == nil && json["error_code"].string == nil else {
                    promise.failure(BackendError.error(message: "Unknown Error"))
                    return
                }
                
                for (_, subJson):(String, JSON) in json {
                    let user = User()
                    user.gamerTag = subJson["Gamertag"].stringValue
                    guard user.gamerTag.count > 0 else { continue }
                    user.xuid = subJson["id"].stringValue
                    user.thumbnailURL = URL(string: subJson["AppDisplayPicRaw"].stringValue)
                    results.append(user)
                }
                
                guard results.count > 0 else {
                    promise.failure(BackendError.error(message: "No friends"))
                    return
                }
                
                promise.success(results)
            } catch {
                promise.failure(BackendError.error(message: "Error deserializing response"))
            }
        }
        
        else if let error = error {
            promise.failure(BackendError.error(message: error.localizedDescription))
            return
        }
    }
    
    task.resume()
    
    return promise.future
}

func cacheThumbnails(ofCaptures captures: [Capture]) -> Future<[ImageResource], BackendError> {
    let promise = Promise<[ImageResource], BackendError>()
    
    let dispatchGroup = DispatchGroup()
    
    var cachedImageResources: [ImageResource] = []
    
    for capture in captures {
        dispatchGroup.enter()
        
        ImageDownloader.default.downloadImage(with: capture.thumbnailURL) { (image, error, url, data) in
            if let image = image, let url = url {
                ImageCache.default.store(image, forKey: url.absoluteString)
                cachedImageResources.append(ImageResource(downloadURL: url))
            }
            
            dispatchGroup.leave()
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        promise.success(cachedImageResources)
    }
    
    return promise.future
}


func getCaptures(user: User) -> Future<[Capture], BackendError> {
    let promise = Promise<[Capture], BackendError>()

    var results: [Capture] = []
    var errorOccured = false

    let dispatchGroup = DispatchGroup()
    
    guard user.xuid != nil else {
        promise.failure(BackendError.error(message: "No XUID"))
        return promise.future
    }

    let clipsURL = baseURL.appendingPathComponent("\(user.xuid!)/game-clips")
    
    var clipsRequest = URLRequest(url: clipsURL)
    
    clipsRequest.setValue(xboxAPIKey, forHTTPHeaderField: "X-Auth")

    dispatchGroup.enter()
    let clipsTask = URLSession.shared.dataTask(with: clipsRequest) { (data, response, error) in

        if let data = data {
            do {

                let json = try JSON(data: data)
                
                guard json["error"].bool == nil, json["error_code"].string == nil else {
                    throw BackendError.error(message: "Unknown Error")
                }

                for (_,subJson):(String, JSON) in json {
                    let capture = Capture()

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
                    capture.dateRecorded = dateFormatter.date(from: subJson["dateRecorded"].stringValue)

                    capture.thumbnailURL = URL(string: subJson["thumbnails"][0]["uri"].stringValue)
                    capture.mediaURL = URL(string: subJson["gameClipUris"][0]["uri"].stringValue)
                    capture.isVideo = true
                    
                    guard capture.isComplete else { continue }
                    results.append(capture)
                }
            }  catch _ as NSError {
                errorOccured = true
            }
        } else if error != nil {
            errorOccured = true
        }
        dispatchGroup.leave()
    }

    clipsTask.resume()

    dispatchGroup.enter()
    
    let screenshotsURL = baseURL.appendingPathComponent("\(user.xuid!)/screenshots")
    
    var screenshotsRequest = URLRequest(url: screenshotsURL)
    
    screenshotsRequest.setValue(xboxAPIKey, forHTTPHeaderField: "X-AUTH")

    let screenshotsTask = URLSession.shared.dataTask(with: screenshotsRequest) { (data, response, error) in

        if let data = data {
            do {
                let json = try JSON(data: data)
                
                guard json["error"].bool == nil, json["error_code"].string == nil else {
                    throw BackendError.error(message: "Unknown Error")
                }

                for (_,subJson):(String, JSON) in json {
                    let capture = Capture()

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
                    capture.dateRecorded = dateFormatter.date(from: subJson["dateTaken"].stringValue)

                    capture.thumbnailURL = URL(string: subJson["thumbnails"][0]["uri"].stringValue)
                    capture.mediaURL = URL(string: subJson["screenshotUris"][0]["uri"].stringValue)
                    capture.isVideo = false
                    
                    guard capture.isComplete else { continue }
                    results.append(capture)
                }


            }  catch _ as NSError {
                errorOccured = true
            }
        } else if error != nil {
            errorOccured = true
        }
        dispatchGroup.leave()
    }

    screenshotsTask.resume()

    dispatchGroup.notify(queue: .main) {
        if errorOccured == true {
            promise.failure(BackendError.error(message: "Unknown Error"))
        } else {
            results = results.sorted(by: { (first, second) -> Bool in
                if first.dateRecorded.timeIntervalSinceNow > second.dateRecorded.timeIntervalSinceNow {
                    return true
                } else {
                    return false
                }
            })
            
            for (index, capture) in results.enumerated() {
                capture.index = index
            }
            
            promise.success(results)
        }
    }


    return promise.future
}
