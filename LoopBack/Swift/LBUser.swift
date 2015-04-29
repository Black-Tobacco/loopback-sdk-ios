//
//  LBUser.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 4/30/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import Foundation

public class LBUser: LBModel {
    var email:String?
    var password:String?
    var realm:String?
    var emailVerified:NSNumber?
    var status:String?
}

public class LBUserRepository: LBModelRepository {
    var currentUserId:AnyObject?
    var accessTokenRepository:LBAccessTokenRepository?
    var isCurrentUserIdLoaded:Bool = false
    var cachedCurrentUser:LBUser?
    
    override public class func repository() -> LBUserRepository {
        let repo = LBUserRepository(className: "users", modelClass: LBUser.self)
        return repo
    }
    
    override func contract() -> SLRESTContract {
        let contract = super.contract()
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/login?include=user", verb:"POST" ), forMethod: "\( className ).login" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/logout", verb:"POST" ), forMethod: "\( className ).logout" )
        
        return contract
    }
    
    public func createUser(#email:String, password: String, dictionary: Dictionary<NSObject, AnyObject>) -> LBUser {
        let user = LBUser(repository: self, parameters: dictionary)
        user.email = email
        user.password = password
        return user
    }
    
    public func createUser(#email:String, password: String) -> LBUser {
        let user = LBUser(repository: self, parameters: nil)
        user.email = email
        user.password = password
        return user
    }
    
    func login(#email:String , password: String, success: (LBAccessToken) -> (), failure: ( NSError! ) -> () ) {
        invokeStaticMethod( "login", parameters: [ "email": email, "password": password ], success: { [unowned self]( value ) -> Void in
            assert( value is NSDictionary, "Received non-Dictionary: \( value )" )
            let adapter = self.adapter as! LBRESTAdapter
            if(self.accessTokenRepository == nil) {
                self.accessTokenRepository = adapter.repositoryWithClass(LBAccessTokenRepository.self) as? LBAccessTokenRepository
            }
            let accessToken:LBAccessToken = self.accessTokenRepository!.modelWithDictionary(value as! NSDictionary) as! LBAccessToken
            
            adapter.accessToken = accessToken.id as? String
            self.currentUserId = accessToken.userId
            success(accessToken)
            
            }, failure:failure )
    }
    
    public func userByLogin(#email:String, password: String, success: (LBUser) -> (), failure: ( NSError! ) -> () ) {
        login(email: email, password: password, success: { (token) -> () in
            self.findById(token.userId, success: { (user) -> () in
                self.cachedCurrentUser = user as? LBUser
                success(user as! LBUser)
            }, failure: { (error) -> () in
                failure(error)
            })
        }) { (error) -> () in
            failure(error)
        }
    }
}