//
//  LBInstallation.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 4/30/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import Foundation

//
// LBInstallation represents the installation of a given app on the device. It
// connects the device token with application/user/timeZone/subscriptions for
// the server to find devices of interest for push notifications.
//
public class LBInstallation : LBModel {
    //
    // The app id received from LoopBack application signup.
    // It's usaully configurd in the Settings.plist file
    //
    var appId:String?
    
    //
    // The application version, default to "1.0.0"
    //
    var appVersion:String?
    
    //
    // The id for the signed in user for the installation
    //
    var userId:String?
    
    //
    // It's always @"ios"
    //
    var deviceType:String?
    
    //
    // The device token in hex string format
    //
    var deviceToken:String?
    
    //
    // The current badge
    //
    var badge:NSNumber?
    
    //
    // An array of topic names that the device subscribes to
    //
    var subscriptions:[String] = []
    
    //
    // The time zone for the server side to decide a good time for push
    //
    var timeZone:String?
    
    //
    // Status of the installation
    //
    var status:String?
    
    //
    // Convert the device token from NSData to NSString
    //
    // @param token The device token in NSData type
    // @return The device token in NSString type
    //
    public static func deviceToken(#data:NSData!) -> String {
        var array:[UInt32] = [UInt32](count: data.length, repeatedValue: 0)
        data.getBytes(&array, length:data.length)
        
        let hexToken = String(format : "%08x%08x%08x%08x%08x%08x%08x%08x",
            array[0].bigEndian,
            array[1].bigEndian,
            array[2].bigEndian,
            array[3].bigEndian,
            array[4].bigEndian,
            array[5].bigEndian,
            array[6].bigEndian,
            array[7].bigEndian
        )
        
        return hexToken
    }
    
    public static func registerDevice(device:LBInstallation,
        success:(value:LBInstallation) -> (),
        failure:(NSError!) -> ()) -> () {
        device.save({ () -> () in
            println("LBInstallation: Successfully saved \(device)")
            success(value: device)
        },
        failure:{ (error) -> () in
            println("LBInstallation: Failed to save \(device) with \(error)")
            failure(error)
        })
    }
    
    //
    // Register the device against LoopBack server
    // @param adapter The REST adapter
    // @param deviceToken The device token
    // @param registrationId The registration id
    // @param appId The application id
    // @param appVersion The application version
    // @param userId The user id
    // @param badge The badge
    // @param subscriptions An array of string values representing subscriptions to push events
    // @param success The success callback block for device registration
    // @param failure The failure callback block for device registration
    //
    public static func registerDevice(#adapter:LBRESTAdapter,
        deviceToken:NSData!,
        registrationId:String?,
        appId:String,
        appVersion:String,
        userId:String,
        badge:NSNumber!,
        subscriptions:[String],
        success:(value:LBInstallation) -> (),
        failure:( NSError! ) -> ()) {
            let hexToken = LBInstallation.deviceToken(data:deviceToken)
            let repository = adapter.repositoryWithClass(LBInstallationRepository.self)
            
            var model:LBInstallation
            
            if registrationId != nil {
                model = repository.modelWithDictionary(["id":registrationId!]) as! LBInstallation
            } else {
                model = repository.modelWithDictionary([:]) as! LBInstallation
            }
            
            model.appId = appId
            model.appVersion = appVersion
            model.userId = userId
            model.deviceType = "ios"
            model.deviceToken = hexToken
            model.status = "Active"
            model.badge = badge
            model.subscriptions = subscriptions
            model.timeZone = NSTimeZone.defaultTimeZone().name
            
            LBInstallation.registerDevice(model, success:success, failure:failure)
    }
}

public class LBInstallationRepository: LBModelRepository {
    static let singleton = LBInstallationRepository(className: "installations", modelClass: LBInstallation.self)
    
    override public class func repository() -> LBInstallationRepository {
        return singleton
    }
}

