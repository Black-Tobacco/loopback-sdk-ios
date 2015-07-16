//
//  LBPushNotification.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 4/30/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import UIKit
import Foundation

/**
* Wrapper class to handle received push notifications
* @experimental(Provide helper methods for iOS clients to handle push notifications)
*/

public class LBPushNotification {
    public enum LBPushNotificationType : Int {
        /** App was on Foreground */
        case Foreground = 1
        /** App was on Background */
        case Background = 2
        /** App was terminated and launched again through Push notification */
        case Terminated = 3
    }
    
    public init(type:LBPushNotificationType, userInfo:[NSObject: AnyObject]?) {
        self.type = type
        self.userInfo = userInfo
    }
    
    /**
    * The notification type
    */
    var type:LBPushNotificationType
    
    /**
    * The notification payload
    */
    var userInfo:[NSObject: AnyObject]?
    
    /**
    * This method should be called within UIApplicationDelegate's application method.
    * - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    * @param application The application
    * @param launchOptions The launch options from the application hook
    * @return The offline notification
    */
    class func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> LBPushNotification? {
        if (application.respondsToSelector(Selector("registerUserNotificationSettings:"))) {
            // iOS 8 or later
            let types = UIUserNotificationType.Badge | UIUserNotificationType.Sound | UIUserNotificationType.Alert
            let settings = UIUserNotificationSettings(forTypes:types, categories:nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types = UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound | UIRemoteNotificationType.Alert
            application.registerForRemoteNotificationTypes(types)
        }
        
        // Handle APN on Terminated state, app launched because of APN
        if let payload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject: AnyObject] {
            return LBPushNotification(type:.Terminated, userInfo:payload)
        } else {
            return nil
        }
    }
    
    /**
    * Handle received notification
    * @param application The application instance
    * @param userInfo The payload
    * @return The received notification
    */
    class func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject: AnyObject]?) -> LBPushNotification? {
        // Detect if APN is received on Background or Foreground state
        if (application.applicationState == UIApplicationState.Inactive) {
            return LBPushNotification(type:.Background, userInfo:userInfo)
        }
        else if (application.applicationState == UIApplicationState.Active) {
            return LBPushNotification(type:.Foreground, userInfo:userInfo)
        }
        return nil;
    }
    
    /**
    * Handle the device token
    * @param application The application instance
    * @param deviceToken The device token
    * @param adapter The REST adapter
    * @param userId The user id
    * @param subscriptions The list of subscribed topics
    * @param success The success callback block
    * @param failure The failure callback block
    */
    class func application(application: UIApplication, didRegisterForRemoteNotifications deviceToken:NSData!, adapter: LBRESTAdapter, userId: String, subscriptions: [String], success:(value:AnyObject) -> (), failure:( NSError! )->()) -> () {
        println("My token is: \(deviceToken)")
        
        let path = NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Settings.plist")
        let settings:[String: AnyObject] = NSDictionary(contentsOfFile:path) as! [String: AnyObject]
        let badge = application.applicationIconBadgeNumber
        
        LBInstallation.registerDevice(adapter: adapter,
            deviceToken: deviceToken,
            registrationId: "",
            appId: settings["AppId"] as! String,
            appVersion: settings["AppVersion"] as! String,
            userId: userId,
            badge: badge,
            subscriptions: subscriptions,
            success: success,
            failure: failure)
    }
    
    /**
    * Handle failure to receive device token
    */
    func application(application: UIApplication, didFailToRegisterForRemoteNotifications error:NSError) {
        println("Failed to get token, error: \(error)")
    }
    
    /**
    * Reset badge
    * @param badge The new badge value
    * @return The old badge
    */
    static func resetBadge(badge:NSInteger) -> NSInteger {
        let app = UIApplication.sharedApplication()
        let current = app.applicationIconBadgeNumber
        if(badge < 0) {
            app.applicationIconBadgeNumber = 0
        } else {
            app.applicationIconBadgeNumber = badge
        }
        return current
    }
    
    /**
    * Get the current badge value
    * @return The badge value
    */
    static func getBadge() -> NSInteger {
        return UIApplication.sharedApplication().applicationIconBadgeNumber
    }
}