//
//  AppDelegate.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import UIKit

protocol AppManager {
    var environment: Environment { get }
    var servicesAssembly: ServicesAssembly { get }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppManager {
    static var current: AppDelegate {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {
            assertionFailure("Something is not right, are you sure app's lifecycle is not malformed?")
            fatalError()
        }
        
        return appDelegate
    }
    
    let environment: Environment
    let servicesAssembly: ServicesAssembly
    
    override init() {
        #if DEBUG
            let environmentType = EnvType.debug
        #elseif RELEASE
            let environmentType = EnvType.release
        #endif

        let environment = Environment(with: environmentType)
        let musicPlayListService = MusicPlayListService(environment: environment)
        let resourceDownloaderService = ResourceDownloaderService(environment: environment)
        
        /// - Note Since API does not provide artwork image URL, we are loading random images from `Picsum` mapped to each music id
        let artworkImageLoaderService = MockArtworkImageLoaderService(environment: environment)
        
        /// - Note This way you dependency inject services to entire app, and can easily mock them for testing, or have different services for different environments like `QA`, `DEBUG`, `RELEASE` etc
        self.servicesAssembly = ServicesAssembly(musicPlayListService: musicPlayListService,
                                                 artworkImageLoaderService: artworkImageLoaderService,
                                                 sharedResourceDownloaderService: resourceDownloaderService)
        self.environment = environment
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

