//
//  LBAccessToken.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 4/30/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import Foundation

public class LBAccessToken: LBModel {
    var userId:AnyObject?
}

public class LBAccessTokenRepository: LBModelRepository {
    override public class func repository() -> LBAccessTokenRepository {
        let repo = LBAccessTokenRepository(className: "accessToken", modelClass: LBAccessToken.self)
        return repo
    }
}