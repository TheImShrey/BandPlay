//
//  MusicItemCell.swift
//  BandPlay
//
//  Created by Shreyash Shah on 03/03/24.
//

import UIKit
import SnapKit

class MusicItemCell: UICollectionViewCell, CollectionViewCellCustomizing {
    struct Theme {
        static let contentViewBackgroundColor: UIColor = .secondarySystemGroupedBackground
        static let previewThumbnailBackgroundColor: UIColor = .secondarySystemBackground
        static let fileNameTextColor: UIColor = .label
        static let progressTintColor: UIColor = .systemRed
        static let progressBackgroundTintColor: UIColor = .quaternarySystemFill
        static let fileSizeTextColor: UIColor = .secondaryLabel
        static let controlButtonTintColor: UIColor = .white
        static let seekBarTintColor: UIColor = .systemYellow
        static let seekBarBackgroundTintColor: UIColor = .tertiarySystemBackground
    }

    private let musicItemStateChangeObserverId = UUID()
    
    private var artworkLoadingTask: NetworkTaskable?
    private var artworkLoadingState: ArtworkImageLoadingState = .awaited
    private weak var viewModel: MusicItemViewModel?

    private let artworkThumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.image = ArtworkImageLoadingState.awaited.image
        imageView.backgroundColor = Theme.previewThumbnailBackgroundColor
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let midBodyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.isUserInteractionEnabled = true
        return stackView
    }()

    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.numberOfLines = 1
        label.text = "-"
        label.textColor = Theme.fileNameTextColor
        return label
    }()

    private let progressDiskView: DiskProgressView = {
        let progressView = DiskProgressView()
        progressView.diskWidth = 3.0
        progressView.progressTintColor = Theme.progressTintColor
        progressView.trackTintColor = Theme.progressBackgroundTintColor
        progressView.progress = 0
        progressView.isHidden = false
        progressView.isUserInteractionEnabled = true
        return progressView
    }()
    
    private let musicSeekBar: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.setThumbImage(AppIcons.seekBarThumb.image.withTintColor(Theme.seekBarTintColor), for: .normal)
        slider.tintColor = Theme.seekBarTintColor
        slider.minimumTrackTintColor = Theme.seekBarTintColor
        slider.maximumTrackTintColor = Theme.seekBarBackgroundTintColor
        slider.isContinuous = true
        slider.isHidden = true
        return slider
    }()

    private let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.numberOfLines = 1
        label.text = "-"
        label.textColor = Theme.fileSizeTextColor
        return label
    }()

    private let statusLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 5, left: 3, bottom: 5, right: 3)
        label.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        label.numberOfLines = 1
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 1
        label.clipsToBounds = true
        let status = MusicAsset.Status.pending
        label.text = status.labelText
        label.textColor = status.labelColor
        label.backgroundColor = status.labelColor.withAlphaComponent(0.4)
        label.layer.borderColor = status.labelColor.cgColor
        label.isUserInteractionEnabled = true
        return label
    }()

    private let controlButton: UIButton = {
        let button = UIButton()
        button.contentMode = .scaleAspectFit
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.clipsToBounds = true
        
        let actionType = MusicItemViewModel.ActionType.download
        button.setImage(actionType.image, for: .normal)
        button.tintColor = actionType.foregroundColor
        return button
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.backgroundColor = Theme.contentViewBackgroundColor
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        self.setupHierarchy()
        self.setupActions()
    }
    
    // MARK: - Hierarchy Setup
    private func setupHierarchy() {
        contentView.addSubview(artworkThumbnail)
        contentView.addSubview(midBodyStackView)
        midBodyStackView.addArrangedSubview(fileNameLabel)
        midBodyStackView.addArrangedSubview(fileSizeLabel)
        midBodyStackView.addArrangedSubview(statusLabel)
        contentView.addSubview(progressDiskView)
        contentView.addSubview(musicSeekBar)
        contentView.addSubview(controlButton)
        
        artworkThumbnail.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().inset(10)
            make.leading.equalToSuperview().offset(10)
            make.width.equalTo(artworkThumbnail.snp.height)
        }
        
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        midBodyStackView.snp.makeConstraints { make in
            make.leading.equalTo(artworkThumbnail.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(10)
            make.trailing.equalTo(controlButton.snp.leading).offset(-10)
        }
        
        controlButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.trailing.equalToSuperview().inset(10)
            make.height.equalTo(controlButton.snp.width)
            make.width.equalTo(30)
        }
        
        progressDiskView.snp.makeConstraints { make in
            make.center.equalTo(controlButton)
            make.size.equalTo(30)
        }
        
        musicSeekBar.snp.makeConstraints { make in
            make.leading.equalTo(artworkThumbnail.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(10)
            make.height.equalTo(20)
            make.top.greaterThanOrEqualTo(midBodyStackView.snp.bottom).offset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }
    }
    
    // MARK: - UI Actions
    private func setupActions() {
        controlButton.addAction { [weak self] in
            guard let viewModel = self?.viewModel else { return }
            let action = viewModel.music.status.nextAction
            viewModel.trigger(action: action)
        }
        
        musicSeekBar.addTarget(self, action: #selector(seekBarDidSeek), for: .valueChanged)
        
        let cancelDownloadTapGestureFromProgressView = UITapGestureRecognizer(target: self, action: #selector(triggerCancelDownload))
        progressDiskView.addGestureRecognizer(cancelDownloadTapGestureFromProgressView)
        
        let openMusicDetailsGestureFromArtwork = UITapGestureRecognizer(target: self, action: #selector(triggerMusicDetailsOpen))
        artworkThumbnail.addGestureRecognizer(openMusicDetailsGestureFromArtwork)
        
        let openMusicDetailsGestureFromMidBody = UITapGestureRecognizer(target: self, action: #selector(triggerMusicDetailsOpen))
        midBodyStackView.addGestureRecognizer(openMusicDetailsGestureFromMidBody)
        
        let statusLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(statusLabelTapped))
        statusLabel.addGestureRecognizer(statusLabelTapGesture)
    }
    
    func configure(using viewModel: MusicItemViewModel) {
        self.viewModel = viewModel
        self.updateUI()
    }
    
    func updateUI() {
        trackProgress()
        setPreviewThumbnail()
        setFileName()
        setFileSize()
        setProgressDiskView()
        setMusicSeekBar()
        setStatusLabel()
        setControlButton()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        updateUI()
    }
    
    private func setPreviewThumbnail() {
        
        /// Cancel any already loading task
        if let artworkLoadingTask {
            artworkLoadingTask.cancel()
        }
       
        if let viewModel {
            let musicId = viewModel.music.id
            self.artworkLoadingTask = viewModel.loadArtworkImage(in: .low) { [weak self, musicId] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard let viewModel = self.viewModel else { return }
                    guard viewModel.music.id == musicId else { return } /// - Note cases where cell was recycled for another task, ignore old image load
                    
                    switch result {
                    case .success(let image):
                        self.artworkLoadingState = .loaded(image: image)
                    case .failure(let error):
                        self.artworkLoadingState = .failed
                        debugPrint("Artwork loading failed for music: \(viewModel.music.name) reason: \(error)")
                    }
                    
                    self.artworkThumbnail.image = self.artworkLoadingState.image
                    self.artworkThumbnail.tintColor = self.artworkLoadingState.tintColor
                }
            }
        } else {
            self.artworkLoadingTask = nil
            self.artworkLoadingState = .awaited
            self.artworkThumbnail.image = artworkLoadingState.image
            self.artworkThumbnail.tintColor = artworkLoadingState.tintColor
        }
    }
    
    private func setFileSize() {
        if let viewModel, viewModel.music.status.isDownloaded {
            fileSizeLabel.text = "\(viewModel.music.duration.formattedDuration)"
        } else {
            fileSizeLabel.text = "-"
        }
    }
    
    private func setFileName() {
        if let viewModel {
            fileNameLabel.text = viewModel.music.name
        } else {
            fileNameLabel.text = "-"
        }
    }
    
    private func setProgressDiskView() {
        let musicStatus = viewModel?.music.status ?? .pending
        
        let isDownloading = musicStatus.isDownloading
        progressDiskView.progress = Float(musicStatus.downloadProgress)
        progressDiskView.isHidden = !isDownloading
    }
    
    
    private func setMusicSeekBar() {
        if let viewModel {
            let musicStatus = viewModel.music.status
            
            let isPlaying = musicStatus.isPlaying
            musicSeekBar.value = Float(musicStatus.elapsedTime / viewModel.music.duration)
            musicSeekBar.isHidden = !isPlaying
        } else {
            musicSeekBar.value = 0
            musicSeekBar.isHidden = true
        }
    }
    
    private func setControlButton() {
        let musicStatus = viewModel?.music.status ?? .pending
        let actionType = musicStatus.nextAction
        
        controlButton.setImage(actionType.image, for: .normal)
        controlButton.tintColor = actionType.foregroundColor

        if actionType == .cancel {
            controlButton.snp.updateConstraints { make in
                make.top.greaterThanOrEqualToSuperview().offset(17.5)
                make.trailing.equalToSuperview().inset(17.5)
                make.width.equalTo(15)
            }
        } else {
            controlButton.snp.updateConstraints { make in
                make.top.greaterThanOrEqualToSuperview().offset(10)
                make.trailing.equalToSuperview().inset(10)
                make.width.equalTo(30)
            }
        }
    }
    
    private func setStatusLabel() {
        let musicStatus = viewModel?.music.status ?? .pending
        statusLabel.text = musicStatus.labelText
        statusLabel.textColor = musicStatus.labelColor
        statusLabel.layer.borderColor = musicStatus.labelColor.cgColor
        statusLabel.backgroundColor = musicStatus.labelColor.withAlphaComponent(0.4)
    }
    
    @objc
    private func statusLabelTapped() {
        guard let viewModel else { return }
        
        if viewModel.music.status.isFailed {
            self.viewModel?.trigger(action: .failedErrorTap)
        } else {
            self.triggerMusicDetailsOpen()
        }
    }
    
    @objc
    private func seekBarDidSeek() {
        let fraction = Double(musicSeekBar.value)
        self.viewModel?.trigger(action: .musicSeek(fraction: fraction))
    }
    
    @objc
    private func triggerMusicDetailsOpen() {
        self.viewModel?.trigger(action: .openMusicDetails)
    }
    
    @objc
    private func triggerCancelDownload() {
        self.viewModel?.trigger(action: .cancel)
    }
    
    private func trackProgress() {
        self.viewModel?.onStateChangeBroadcaster.addObserver(with: musicItemStateChangeObserverId) { [weak self] stateChange in
            switch stateChange {
            case .statusChanged:
                DispatchQueue.main.async {
                    self?.setFileSize()
                    self?.setStatusLabel()
                    self?.setProgressDiskView()
                    self?.setMusicSeekBar()
                    self?.setControlButton()
                }
            }
        }
    }
    
    deinit {
        self.viewModel?.onStateChangeBroadcaster.removeObserver(with: musicItemStateChangeObserverId)
    }
}
