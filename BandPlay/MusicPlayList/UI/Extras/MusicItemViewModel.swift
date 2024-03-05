//
//  MusicItemViewModel.swift
//  BandPlay
//
//  Created by Shreyash Shah on 03/03/24.
//

import Foundation
import AVFoundation

class MusicItemViewModel {
    enum StateChange {
        case statusChanged
    }
    
    enum ActionType: Equatable {
        case download
        case cancel
        case play
        case pause
        case failedErrorTap
        case openMusicDetails
        case musicSeek(fraction: Double)
        
        static func == (lhs: ActionType, rhs: ActionType) -> Bool {
            switch (lhs, rhs) {
            case (.download, .download),
                (.cancel, .cancel),
                (.play, .play),
                (.pause, .pause),
                (.failedErrorTap, .failedErrorTap),
                (.openMusicDetails, .openMusicDetails),
                (.musicSeek, .musicSeek):
                return true
            default:
                return false
            }
        }
    }
    
    typealias UITriggerAction = ((ActionType) -> Void)
    
    let music: MusicAsset
    let actionTriggered: UITriggerAction
    var avAsset: AVAsset?
    var onStateChangeBroadcaster: Broadcaster<StateChange>
    
    private let resourceDownloaderService: ResourceDownloaderServicible
    private let artworkImageLoaderService: ArtworkImageLoaderServicible
    weak var fileManager: BandPlayFileManager?
    private var downloadTrackerHandle: ResourceDownloaderService.TrackerHandle?
    
    init(music: Music,
         resourceDownloaderService: ResourceDownloaderServicible,
                  artworkImageLoaderService: ArtworkImageLoaderServicible,
         fileManager: BandPlayFileManager,
         onActionTrigger: @escaping UITriggerAction) {
        self.artworkImageLoaderService = artworkImageLoaderService
        self.fileManager = fileManager
        self.actionTriggered = onActionTrigger
        self.music = MusicAsset(model: music)
        self.resourceDownloaderService = resourceDownloaderService
        self.onStateChangeBroadcaster = Broadcaster()
    }
    
    func trigger(action: ActionType) {
        switch action {
        case .download:
            self.startDownload()
            self.actionTriggered(.download)
        case .cancel:
            self.stopDownload()
            self.actionTriggered(.cancel)
        case .play:
            guard self.music.status == .ready else { break }
            self.actionTriggered(.play)
        case .pause:
            guard self.music.status.isPlaying else { break }
            self.actionTriggered(.pause)
        case .failedErrorTap:
            self.actionTriggered(.failedErrorTap)
        case .musicSeek(let fraction):
            self.actionTriggered(.musicSeek(fraction: fraction))
        case .openMusicDetails:
            self.actionTriggered(.openMusicDetails)
        }
    }
    
    func startDownload() {
        guard let downloadURL = URL(string: music.model.audioURL)
        else {
            self.updateMusic(state: .failed(error: AppError.somethingWentWrong))
            return
        }
        
        /// Cancel existing download if any
        if let downloadTrackerHandle {
            downloadTrackerHandle.task.cancel()
        }
        
        self.updateMusic(state: .downloading(progress: 0.0))
        downloadTrackerHandle = resourceDownloaderService.downloadResource(from: downloadURL,
                                                                           of: FileTypes.mp3.uniformTypeIdentifier,
                                                                           onDownload: { [weak self] progressStatus in
            guard let self else { return }
            
            switch progressStatus {
            case .inProgress(let progress):
                self.updateMusic(state: .downloading(progress: progress))

            case .ended(let result):
                switch result {
                case .success((let downloadedURL, let suggestedFileName)):
                    self.prepareDownloadedMusic(at: downloadedURL, with: suggestedFileName)
                    
                case .failure(let error):
                    self.updateMusic(state: .failed(error: error))
                }
            }
        })
    }
    
    func stopDownload() {
        downloadTrackerHandle?.task.cancel()
        downloadTrackerHandle = nil
        self.updateMusic(state: .pending)
    }
    
    func prepareDownloadedMusic(at localURL: URL, with suggestedFileName: String? = nil) {
        guard let fileManager
        else {
            self.updateMusic(state: .failed(error: AppError.somethingWentWrong))
            return
        }
        
        if music.status.isPlaying {
            self.trigger(action: .pause)
        }
        
        let destinationFileURL = fileManager.documentsDirectoryURL.appending(path: suggestedFileName ?? "\(music.name).mp3")
        do {
            try fileManager.copyFile(at: localURL, byCreatingIntermediateDirectoriesTo: destinationFileURL, shouldOverwrite: true)
            let musicAsset = AVAsset(url: destinationFileURL)
            
            guard musicAsset.tracks.first?.mediaType == .audio else {
                self.avAsset = nil
                self.updateMusic(state: .failed(error: AppError.invalidMusicFile))
                return
            }
            
            self.avAsset = musicAsset
            var duration = musicAsset.duration.seconds
            duration = duration.isNaN ? 0 : duration
            self.updateMusic(downloadedLocalFileURL: destinationFileURL, with: duration)
        } catch {
            self.updateMusic(state: .failed(error: error))
            return
        }
    }
    
    func updateMusic(state: MusicAsset.Status) {
        var state = state
        
        switch state {
        case .playing(let elapsedTime):
            guard elapsedTime == music.duration else { break }
            state = .ready
        default:
            break
        }
        
        self.music.set(status: state)
        self.onStateChangeBroadcaster.broadcast(.statusChanged)
    }
    
    func updateMusic(downloadedLocalFileURL: URL, with duration: Double) {
        self.music.setDownloaded(localFileURL: downloadedLocalFileURL, with: duration)
        self.onStateChangeBroadcaster.broadcast(.statusChanged)
    }
    
    func loadArtworkImage(in resolution: ArtworkImageResolution,
                          onLoaded: @escaping ArtworkImageLoadingResult) -> NetworkTaskable {
        let musicId = music.id
        return artworkImageLoaderService.loadArtworkImage(for: musicId, in: resolution, onLoaded: onLoaded)
    }
}
