//
//  MusicDetailsViewController.swift
//  BandPlay
//
//  Created by Shreyash Shah on 03/03/24.
//

import UIKit
import SnapKit

class MusicDetailsViewController: UIViewController, AlertPresentable {
    struct Theme {
        static let backgroundColor: UIColor = .systemBackground
        static let previewThumbnailBackgroundColor: UIColor = .secondarySystemBackground
        static let fileNameTextColor: UIColor = .label
        static let progressTintColor: UIColor = .systemRed
        static let progressBackgroundTintColor: UIColor = .quaternarySystemFill
        static let fileSizeTextColor: UIColor = .secondaryLabel
        static let seekBarTintColor: UIColor = .systemYellow
        static let seekBarBackgroundTintColor: UIColor = .tertiarySystemBackground
    }
    
    struct Metrics {
        static let smallPadding: CGFloat = 10
        static let standardPadding: CGFloat = 20
        static let extraPadding: CGFloat = 40
        static let statusBorderWidth: CGFloat = 2
        static let statusLabelHeight: CGFloat = 18
        static let controlAndProgressViewHeight: CGFloat = 50
        static let fileSizeLabelHeight: CGFloat = 16
        static let progressBarHeight: CGFloat = 30
        static let standardCornerRadius: CGFloat = 10
        static let smallCornerRadius: CGFloat = 5
    }

    private let artworkThumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Metrics.standardCornerRadius
        imageView.clipsToBounds = true
        imageView.backgroundColor = Theme.previewThumbnailBackgroundColor
        return imageView
    }()

    private let progressDiskView: DiskProgressView = {
        let progressView = DiskProgressView()
        progressView.diskWidth = 3.0
        progressView.progressTintColor = Theme.progressTintColor
        progressView.trackTintColor = Theme.progressBackgroundTintColor
        progressView.progress = 0
        progressView.isHidden = false
        progressView.isUserInteractionEnabled = false
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
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 1
        label.text = "Duration: N/A"
        label.textColor = Theme.fileSizeTextColor
        return label
    }()

    private let statusLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6)
        label.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 1
        label.layer.cornerRadius = Metrics.standardCornerRadius
        label.layer.borderWidth = Metrics.statusBorderWidth
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
        button.isUserInteractionEnabled = false
        
        let actionType = MusicItemViewModel.ActionType.download
        button.setImage(actionType.image, for: .normal)
        button.tintColor = actionType.foregroundColor
        return button
    }()
    
    private let controlAndProgressContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()

    /// - Note We follow single source of truth principle, so we don't update the music Item here.
    let musicItem: MusicItemViewModel
    var currentControlActionType: MusicItemViewModel.ActionType?
    private let musicItemStateChangeObserverId: UUID
    
    init(musicItem: MusicItemViewModel) {
        self.musicItem = musicItem
        self.musicItemStateChangeObserverId = UUID()
        self.currentControlActionType = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        self.musicItem.onStateChangeBroadcaster.removeObserver(with: self.musicItemStateChangeObserverId)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    func setupUI() {
        view.backgroundColor = Theme.backgroundColor
        self.setupHierarchy()
        self.setupActions()
        self.configure()
        
        self.musicItem.onStateChangeBroadcaster.addObserver(with: self.musicItemStateChangeObserverId) { [weak self] stateChange in
            self?.handle(stateChange: stateChange)
        }
    }
    
    // MARK: - Hierarchy Setup
    func setupHierarchy() {
        view.addSubview(artworkThumbnail)
        view.addSubview(fileSizeLabel)
        view.addSubview(statusLabel)
        view.addSubview(musicSeekBar)
        view.addSubview(controlAndProgressContainer)

        artworkThumbnail.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-Metrics.extraPadding)
            make.leading.equalToSuperview().offset(Metrics.extraPadding)
            make.trailing.equalToSuperview().inset(Metrics.extraPadding)
            make.width.equalTo(artworkThumbnail.snp.height)
        }
        
        fileSizeLabel.snp.makeConstraints { make in
            make.bottom.equalTo(artworkThumbnail.snp.top).offset(-Metrics.smallPadding)
            make.centerX.equalTo(artworkThumbnail.snp.centerX)
            make.height.greaterThanOrEqualTo(Metrics.fileSizeLabelHeight)
        }
        
        fileSizeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        fileSizeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkThumbnail.snp.bottom).offset(Metrics.smallPadding)
            make.centerX.equalTo(artworkThumbnail.snp.centerX)
            make.height.greaterThanOrEqualTo(Metrics.statusLabelHeight)
        }

        musicSeekBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Metrics.extraPadding)
            make.trailing.equalToSuperview().inset(Metrics.extraPadding)
            make.height.greaterThanOrEqualTo(Metrics.progressBarHeight)
            make.bottom.equalToSuperview().inset(Metrics.extraPadding)
        }
        
        controlAndProgressContainer.snp.makeConstraints { make in
            make.bottom.equalTo(musicSeekBar.snp.top).offset(-Metrics.standardPadding)
            make.centerX.equalTo(musicSeekBar.snp.centerX)
            make.width.equalTo(controlAndProgressContainer.snp.height)
            make.height.equalTo(Metrics.controlAndProgressViewHeight)
        }
        
        controlAndProgressContainer.addSubview(controlButton)
        
        controlAndProgressContainer.addSubview(progressDiskView)
        progressDiskView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(progressDiskView.snp.height)
            make.height.equalToSuperview()
        }
        
    }
    
    // MARK: - UI Actions
    private func setupActions() {
        musicSeekBar.addTarget(self, action: #selector(seekBarDidSeek), for: .valueChanged)

        let statusLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(statusLabelTapped))
        statusLabel.addGestureRecognizer(statusLabelTapGesture)
        
        let controlAndProgressViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(controlAndProgressViewTapped))
        controlAndProgressContainer.addGestureRecognizer(controlAndProgressViewTapGesture)
    }
    
    private func configure() {
        self.setPreviewThumbnail()
        self.setFileName()
        self.setFileSize()
        self.setControlButton()
        self.setProgressDiskView()
        self.setMusicSeekBar()
        self.setStatusLabel()
    }
        
    private func setPreviewThumbnail() {
        // TODO: Implement image loader
    }
   
    private func setFileName() {
        navigationItem.title = musicItem.music.name
    }
    
    private func setFileSize() {
        if musicItem.music.status.isDownloaded {
            fileSizeLabel.text = "Duration: \(musicItem.music.duration.formattedDuration)"
        } else {
            fileSizeLabel.text = "Duration: N/A"
        }
    }
    
    private func setControlButton() {
        let musicStatus = musicItem.music.status

        let actionType = musicStatus.nextAction
        
        guard self.currentControlActionType != actionType else { return }
        self.currentControlActionType = actionType

        controlButton.setImage(actionType.image, for: .normal)
        controlButton.tintColor = actionType.foregroundColor
        
        controlButton.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(controlButton.snp.height)
            make.height.equalToSuperview().multipliedBy(actionType == .cancel ? 0.5 : 1.0)
        }
    }
    
    private func setProgressDiskView() {
        let musicStatus = musicItem.music.status
        
        let isDownloading = musicStatus.isDownloading
        progressDiskView.progress = Float(musicStatus.downloadProgress)
        progressDiskView.isHidden = !isDownloading
    }
    
    private func setStatusLabel() {
        let musicStatus = musicItem.music.status
        statusLabel.text = musicStatus.shortText
        statusLabel.textColor = musicStatus.labelColor
        statusLabel.layer.borderColor = musicStatus.labelColor.cgColor
        statusLabel.backgroundColor = musicStatus.labelColor.withAlphaComponent(0.4)
    }
    
    private func setMusicSeekBar() {
        let musicStatus = musicItem.music.status
        
        let isPlaying = musicStatus.isPlaying
        musicSeekBar.value = Float(musicStatus.elapsedTime / musicItem.music.duration)
        musicSeekBar.isHidden = !isPlaying
    }
    
    private func onRefresh() {
        self.setFileSize()
        self.setStatusLabel()
        self.setProgressDiskView()
        self.setMusicSeekBar()
        self.setControlButton()
    }
    
    @objc
    func controlAndProgressViewTapped() {
        let controlAction = musicItem.music.status.nextAction
        musicItem.trigger(action: controlAction)
    }
    
    @objc
    func statusLabelTapped() {
        guard musicItem.music.status.isFailed else { return }

        switch musicItem.music.status {
        case .failed(let error):
            self.presentAlert(title: "Music Playback Failed", message: "\(error)")
        default:
            break
        }
    }
    
    @objc
    private func seekBarDidSeek() {
        let fraction = Double(musicSeekBar.value)
        self.musicItem.trigger(action: .musicSeek(fraction: fraction))
    }
    
    func handle(stateChange: MusicItemViewModel.StateChange) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch stateChange {
            case .statusChanged:
                self.onRefresh()
            }
        }
    }
}
