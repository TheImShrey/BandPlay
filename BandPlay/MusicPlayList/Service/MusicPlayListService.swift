//
//  MusicPlayListService.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation
typealias MusicPlayListFetchResult = ((Result<MusicPlayList, Error>) -> Void)

protocol MusicPlayListServicible {
    func fetchMusicPlayList(onFetch: @escaping MusicPlayListFetchResult) -> NetworkTaskable
}

final class MusicPlayListService {
    private let environment: Environment
    
    init(environment: Environment) {
        self.environment = environment
    }
    
    enum Endpoints: String {
        case musicPlayList = "https://gist.githubusercontent.com/Lenhador/a0cf9ef19cd816332435316a2369bc00/raw/a1338834fc60f7513402a569af09ffa302a26b63/Songs.json"
    }
}

extension MusicPlayListService.Endpoints: Requestable {
    var url: URL {
        let url = URL(string: self.rawValue)
        guard let url else {
            assertionFailure("Invalid Endpoint URL, please check if the raw value is valid URL string")
            fatalError()
        }
        
        return url
    }
    
    var method: RequestableMethod {
        switch self {
        case .musicPlayList:
            return .get
        }
    }
}
    
extension MusicPlayListService: MusicPlayListServicible {
    func fetchMusicPlayList(onFetch: @escaping MusicPlayListFetchResult) -> NetworkTaskable {
        let request = Endpoints.musicPlayList.request
        
        let task = environment.sharedNetworkSession.dataTask(with: request) { (data, response, error) in
            if let error {
                onFetch(.failure(error))
            } else if let data {
                do {
                    let musicPlayList = try JSONDecoder().decode(MusicPlayList.self, from: data)
                    onFetch(.success(musicPlayList))
                } catch {
                    onFetch(.failure(error))
                }
            } else {
                onFetch(.failure(AppError.somethingWentWrong))
            }
        }
        
        task.resume()
        
        return task
    }
}
