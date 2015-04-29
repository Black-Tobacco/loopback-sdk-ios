//
//  LBRESTAdapter.swift
//  LoopBack
//
//  Created by Sylvain Ageneau on 4/30/15.
//  Copyright (c) 2015 StrongLoop. All rights reserved.
//

import Foundation


public class LBRESTAdapter : SLRESTAdapter {
    let DEFAULTS_ACCESSTOKEN_KEY:String = "LBRESTAdapterAccessToken"
    
    override init() {
        super.init()
    }
    
    convenience public init(URL url: NSURL) {
        self.init(URL: url, allowsInvalidSSLCertificate:false)
    }
    
    override public init(URL url: NSURL, allowsInvalidSSLCertificate: Bool) {
        super.init(URL: url, allowsInvalidSSLCertificate: allowsInvalidSSLCertificate)
        accessToken = loadAccessToken()
    }
    
    override public var accessToken: String? {
        didSet {
            if accessToken != nil {
                saveAccessToken(accessToken!)
            }
        }
    }
    
    public func repositoryWithClass(type:LBModelRepository.Type) -> LBModelRepository {
        assert(type.respondsToSelector(Selector("repository")))
        let repository:LBModelRepository = type.repository()
        attachRepository(repository)
        return repository
    }
    
    public func repositoryWithModelName(name:String) -> LBModelRepository {
        let repository:LBModelRepository = LBModelRepository(className: name)
        attachRepository(repository)
        return repository
    }
    
    func attachRepository(repo:LBModelRepository) -> () {
        contract.addItemsFromContract(repo.contract())
        repo.adapter = self
    }
    
    func saveAccessToken(accessToken:String) -> () {
        let defaults = NSUserDefaults()
        defaults.setValue(accessToken, forKey: DEFAULTS_ACCESSTOKEN_KEY)
    }
    
    func loadAccessToken() -> (String?) {
        let defaults = NSUserDefaults()
        let accessToken = defaults.stringForKey(DEFAULTS_ACCESSTOKEN_KEY)
        return accessToken
    }
}