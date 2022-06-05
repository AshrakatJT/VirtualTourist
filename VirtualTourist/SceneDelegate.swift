//
//  SceneDelegate.swift
//  VirtualTourist
//
//  Created by Ashrakat Sherif on 20/05/2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

var window: UIWindow?

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.dataController.load()
    let navigationController = window?.rootViewController as! UINavigationController
    let travelLocationsMapViewController = navigationController.topViewController as! TravelLocationsMapViewController
    travelLocationsMapViewController.dataController = appDelegate.dataController
    }

}
