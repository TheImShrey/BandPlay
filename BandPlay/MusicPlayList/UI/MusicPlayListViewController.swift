//
//  MusicPlayListViewController.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

class MusicPlayListViewController: UIViewController, AlertPresentable {
    struct Theme {
        static let refreshIcon = AppIcons.refresh.image
        static let backgroundColor: UIColor = .systemBackground
        static let disabledUIControlColor: UIColor = .systemGray3
    }
    
    struct Metrics {
        static let refreshButtonHeight: CGFloat = 80
        static let standardPadding: CGFloat = 20
    }
    
    let viewModel: MusicPlayListViewModel
    
    let musicPlayListView: MusicPlayListCollectionView = {
        let collectionView = MusicPlayListCollectionView()
        return collectionView
    }()
    
    let emptyStateView: MusicPlayListZeroStateView = {
        return MusicPlayListZeroStateView()
    }()

    init(environment: Environment,
         musicPlayListService: MusicPlayListServicible,
                  artworkImageLoaderService: ArtworkImageLoaderServicible) {
        
        self.viewModel = MusicPlayListViewModel(environment: environment,
                                                musicPlayListService: musicPlayListService,
                                                         artworkImageLoaderService: artworkImageLoaderService)
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel.onStateChange = { [weak self] in self?.handle(stateChange: $0)}
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let flowLayout = musicPlayListView.collectionViewLayout as? UICollectionViewFlowLayout
        else {
            return
        }
        flowLayout.invalidateLayout()
    }


    func setupUI() {
        view.backgroundColor = Theme.backgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Theme.refreshIcon,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(refreshButtonTapped))
        navigationItem.title = "Band Play"
        setupConstraints()

        musicPlayListView.emptyStateView = emptyStateView
        
        let refreshGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(refreshButtonTapped))
        emptyStateView.addGestureRecognizer(refreshGestureRecognizer)

        self.musicPlayListView.dataSource = self
    }
    
    func setupConstraints() {
        view.addSubview(musicPlayListView)

        musicPlayListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func refreshButtonTapped() {
        self.setupEmptyStateViews(to: .loading)
        viewModel.fetchMusicPlayList()
    }
    
    func handle(stateChange: MusicPlayListViewModel.StateChanges) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            switch stateChange {
            case .openMusicDetails(let musicItem):
                self.openTaskDetailsScreen(for: musicItem)
                
            case .reloadAll:
                self.setupEmptyStateViews(to: self.viewModel.musicItemViewModels.isEmpty ? .empty : .loaded)
                self.musicPlayListView.reloadData()
                if !self.viewModel.musicItemViewModels.isEmpty {
                    self.musicPlayListView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
                
            case .reloadItems(let itemTuples):
                self.setupEmptyStateViews(to: .loaded)
                self.musicPlayListView.performBatchUpdates { [weak self] in
                    let indexPaths = itemTuples.map { IndexPath(item: $0.index, section: 0) }
                    self?.musicPlayListView.reloadItems(at: indexPaths)
                }
                
            case .showActionAlert(let actionType, let musicItem):
                switch actionType {
                case .failedErrorTap:
                    switch musicItem.music.status {
                    case .failed(let error):
                        self.presentAlert(title: "Music Playback Failed", message: "\(error)")
                    default:
                        break
                    }
                default:
                    break
                }
                
            case .showGeneralError(let title, let error):
                self.setupEmptyStateViews(to: .empty)
                self.presentAlert(title: title, message: "Error: \(error)")
            }
        }
    }
    
    func openTaskDetailsScreen(for musicItem: MusicItemViewModel) {
        let musicDetailsVC = MusicDetailsViewController(musicItem: musicItem)
        let navigationController = UINavigationController(rootViewController: musicDetailsVC)
        self.navigationController?.present(navigationController, animated: true)
    }
    
    func setupEmptyStateViews(to state: MusicPlayListZeroStateView.State) {
        self.emptyStateView.set(state: state)
        self.navigationItem.rightBarButtonItem?.tintColor = state == .loading ? Theme.disabledUIControlColor : nil
    }
}

extension MusicPlayListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        lazy var defaultItemsCount = 0
        
        switch collectionView {
        case self.musicPlayListView:
            return viewModel.musicItemViewModels.count
        default:
            return defaultItemsCount
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        lazy var emptyCell = UICollectionViewCell()
        
        switch collectionView {
        case self.musicPlayListView:
            guard let musicItemViewModel = viewModel.musicItemViewModels.item(at: indexPath.row),
                  let musicCell = musicPlayListView.dequeueReusableCell(of: MusicItemCell.self, for: indexPath)
            else {
                return emptyCell
            }
            
            musicCell.configure(using: musicItemViewModel)
            return musicCell
        default:
            return emptyCell
        }
    }
}
