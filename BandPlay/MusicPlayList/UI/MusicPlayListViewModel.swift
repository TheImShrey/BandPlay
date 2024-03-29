//
//  MusicPlayListViewModel.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation
import AVFoundation
import SwiftData

class MusicPlayListViewModel {
    typealias StateChangeTrigger = ((StateChanges) -> Void)

    enum StateChanges {
        case openMusicDetails(MusicItemViewModel)
        case reloadItems([(index: Int, oldTaskId: String)])
        case reloadAll
        case showActionAlert(MusicItemViewModel.ActionType, MusicItemViewModel)
        case showGeneralError(String, Error)
    }
    
    private let artworkImageLoaderService: ArtworkImageLoaderServicible
    private let musicPlayListService: MusicPlayListServicible
    private var fetchMusicPlayListTask: (any NetworkTaskable)?
    private let musicPlayer: AVPlayer
    private var musicPlayerSeekObservation: Any?
    private var musicPlayerPauseObservation: Any?
    private weak var currentlyPlayedMusicItem: MusicItemViewModel?
    var onStateChange: StateChangeTrigger?
    let environment: Environment
    var musicItemViewModels: [MusicItemViewModel]
    
    @MainActor
    init(environment: Environment,
         musicPlayListService: MusicPlayListServicible,
         artworkImageLoaderService: ArtworkImageLoaderServicible) {
        self.artworkImageLoaderService = artworkImageLoaderService
        self.musicPlayListService = musicPlayListService
        self.musicItemViewModels = []
        self.environment = environment
        self.musicPlayer = AVPlayer()
        self.musicPlayerSeekObservation = musicPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 60),
                                                                              queue: .main,
                                                                              using: { [weak self] _ in
            self?.onMusicPlayBackTimeChanged()
        })
        
        self.musicPlayerPauseObservation = musicPlayer.observe(\.timeControlStatus) { [weak self] _, _  in
            guard self?.musicPlayer.timeControlStatus == .paused else { return }
            self?.onMusicPlayBackPaused()
        }
    
        self.initialMusicPlayListSetup()
    }
    
    private func createMusicItem(for music: MusicAsset) -> MusicItemViewModel {
        let newMusicId = music.id
        let onActionTrigger: MusicItemViewModel.UITriggerAction = { [weak self, newMusicId] action in
            guard let self,
                  let musicItem = self.musicItemViewModels.first(where: { $0.music.id == newMusicId })
            else { return }
            
            switch action {
            case .download, .cancel:
                /// Do nothing, already handled in the Music Item VM itself
                break
            case .play:
                self.playMusic(from: musicItem)
            case .pause:
                self.pauseMusic(for: musicItem)
            case .failedErrorTap:
                self.broadcast(stateChange: .showActionAlert(action, musicItem))
            case .musicSeek(let fraction):
                self.seekMusic(for: musicItem, to: fraction)
            case .openMusicDetails:
                self.broadcast(stateChange: .openMusicDetails(musicItem))
            }
        }
        
        /// Create a new ResourceDownloaderService for each music item so that their downloads can run in parallel
        /// In future here we can a logic to use pool of downloader services depending network strength, limiting max concurrent downloads, etc
        let resourceDownloaderService = ResourceDownloaderService(environment: self.environment)
        let musicItemViewModel = MusicItemViewModel(music: music,
                                                    resourceDownloaderService: resourceDownloaderService,
                                                    artworkImageLoaderService: self.artworkImageLoaderService,
                                                    fileManager: self.environment.fileManager,
                                                    onActionTrigger: onActionTrigger)
        
        return musicItemViewModel
    }
    
    private func resetPlaylist(with playList: MusicPlayList? = nil) {
        let musics = playList?.musics ?? []
        
        let musicAssets = musics.map { music in
            return MusicAsset(model: music)
        }
        
        self.resetPlaylist(with: musicAssets)
    }
    
    private func resetPlaylist(with musicItems: [MusicAsset]) {
        if let currentlyPlayedMusicItem {
            self.pauseMusic(for: currentlyPlayedMusicItem)
        }
        
        let oldMusicItems = self.musicItemViewModels
        self.musicItemViewModels = musicItems.map { musicAsset in
            if let existingMusicItem = oldMusicItems.first(where: { $0.music.model == musicAsset.model }) {
                return existingMusicItem
            } else {
                return self.createMusicItem(for: musicAsset)
            }
        }
        
        self.onStateChange?(.reloadAll)
    }
    
    @MainActor
    private func initialMusicPlayListSetup() {
        self.setupWithPersistedMusicItems()
        self.fetchMusicPlayList()
    }
    
    func fetchMusicPlayList() {
        self.fetchMusicPlayListTask?.cancel()
        self.fetchMusicPlayListTask = musicPlayListService.fetchMusicPlayList { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let playList):
                self.resetPlaylist(with: playList)
            case .failure(let error):
                self.onStateChange?(.showGeneralError("Error fetching music play list", error))
            }
            self.fetchMusicPlayListTask = nil
        }
    }
    
    func broadcast(stateChange: StateChanges) {
        self.onStateChange?(stateChange)
    }
    
    func playMusic(from musicItem: MusicItemViewModel) {
        guard musicItem.music.status == .ready else { return }
        guard let avMusicAsset = musicItem.avAsset else { return }

        if let currentlyPlayedMusicItem {
            self.pauseMusic(for: currentlyPlayedMusicItem)
        }
        
        self.currentlyPlayedMusicItem = musicItem
        let audioItem = AVPlayerItem(asset: avMusicAsset)
        musicPlayer.actionAtItemEnd = .pause
        musicPlayer.replaceCurrentItem(with: audioItem)
        musicPlayer.seek(to: .zero)
        musicPlayer.play()
    }
    
    func pauseMusic(for musicItem: MusicItemViewModel) {
        guard musicItem.music.status.isPlaying else { return }
        guard currentlyPlayedMusicItem?.music.id == musicItem.music.id else { return }
        
        musicPlayer.pause()
        self.currentlyPlayedMusicItem?.updateMusic(state: .ready)
        self.currentlyPlayedMusicItem = nil
    }
    
    func onMusicPlayBackTimeChanged() {
        self.currentlyPlayedMusicItem?.updateMusic(state: .playing(elapsedTime: musicPlayer.currentTime().seconds))
    }
    
    func onMusicPlayBackPaused() {
        self.currentlyPlayedMusicItem?.updateMusic(state: .ready)
    }
    
    func seekMusic(for musicItem: MusicItemViewModel, to fraction: Double) {
        guard musicItem.music.status.isPlaying else { return }
        guard currentlyPlayedMusicItem?.music.id == musicItem.music.id else { return }
        let seekTimeInSeconds = fraction * musicItem.music.duration
        musicPlayer.seek(to: CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: 1000))
    }
    
    @MainActor
    func onAppDidEnterBackground() {
        self.persistMusicItems()
    }
}


extension MusicPlayListViewModel {
    @MainActor
    private func setupWithPersistedMusicItems() {
        do {
            let persistanceContainer = self.environment.persistanceContainer
            guard let persistanceContainer else { return }
            
            let musicAssetsFetchDescriptor = FetchDescriptor<Persistables.MusicAsset>(sortBy: [SortDescriptor(\.id)])
            let persistedMusicAssets = try persistanceContainer.mainContext.fetch(musicAssetsFetchDescriptor)
            let musicAssets = persistedMusicAssets.map { persistedMusicAsset in
                return MusicAsset(from: persistedMusicAsset)
            }
            
            self.resetPlaylist(with: musicAssets)
        } catch {
            debugPrint("Error fetching music play list from persisted storage", error)
        }
    }
    
    @MainActor
    private func persistMusicItems() {
        guard let persistanceContainer = self.environment.persistanceContainer else { return }
        let musicItemViewModels = self.musicItemViewModels
        
        musicItemViewModels.forEach { musicItem in
            let persistableMusicModel = musicItem.music.buildPersistable()
            persistanceContainer.mainContext.insert(persistableMusicModel)
        }
    }
}
