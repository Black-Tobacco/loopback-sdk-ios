//
//  LBModel.swift
//  LoopBack
//
//  Created by Jonathon Hibbard on 12/29/14.
//  Copyright (c) 2014 StrongLoop. All rights reserved.
//

import Foundation


public class LBModel: SLObject, CustomStringConvertible {

    /** All Models have a numerical `id` field. */
    public private( set ) var id:AnyObject? = nil
    private( set ) var overflow = Dictionary<String, AnyObject>()

    public subscript( Tk: String ) -> AnyObject! {
        get {
            return overflow[Tk]
        }

        set( Tv ) {
            overflow[Tk] = Tv
        }
    }
    
    override public var description: String {
        let className = class_getName( object_getClass( self ) )
        let selfAsDict = toDictionary()
        
        return "<\( className ), \( selfAsDict )>"
    }
    
    required override public init!(repository: SLRepository!, parameters: Dictionary<NSObject,AnyObject>! ) {
        super.init(repository: repository, parameters: parameters)

        overflow = Dictionary()
    }

    override public func setValue(value: AnyObject?,
        forUndefinedKey key: String) {
            //println("WARNING: setValue called for non KVO compliant key: \(key)")
    }
    
    func setIdendifier(  idValue:AnyObject ) {
        self.id = idValue
    }

    func toDictionary() -> NSDictionary {
        var dict = overflow

        var propertiesCount : CUnsignedInt = 0
        let propertiesInAClass = class_copyPropertyList( object_getClass( self ), &propertiesCount )

        let z = Int( propertiesCount )
        var i = 0

        for i = 0; i < z; i++ {
            let property = propertiesInAClass[i]
            let propertyName = NSString( CString: property_getName( property ), encoding: NSUTF8StringEncoding )

            if propertyName != nil {
                if propertyName == "id" || propertyName == "description" || propertyName == "overflow" {
                    continue
                }

                dict[propertyName! as String] = valueForKey( propertyName! as String )
            }
        }

        return dict
    }

    public func save( success:() -> (), failure:( NSError! ) -> () ) {
        let methodToInvoke = id != nil ? "save": "create"
        let parameters = toDictionary() as [NSObject : AnyObject]

        invokeMethod( methodToInvoke, parameters: parameters, success: { ( value ) -> Void in
            self.id = value["id"]
            success()
        }, failure: failure )
    }

    public func destroy( success:() -> (), failure:( NSError! ) -> () ) {
        invokeMethod( "remove", parameters: toDictionary() as [NSObject : AnyObject], success: { [unowned self]( value ) -> Void in
            success()
        }, failure: failure )
    }
}


public class LBModelRepository : SLRepository {
    private var modelClass:LBModel.Type?

    override init() {
        super.init()
    }

    public override init(className name: String!) {
        super.init(className:name)
        if self.modelClass == nil {
            self.modelClass = LBModel.self
        }
    }
    
    public init( className name: String!, modelClass: LBModel.Type ) {
        super.init(className:name)
        self.modelClass = modelClass
    }
    
    public class func repository() -> LBModelRepository {
        return LBModelRepository()
    }

    func contract() -> SLRESTContract {
        let contract = SLRESTContract()

        contract.addItem( SLRESTContractItem( pattern: "/\( className )", verb:"POST" ), forMethod: "\( className ).prototype.create" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/:id", verb:"PUT" ), forMethod: "\( className ).prototype.save" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/:id", verb:"DELETE" ), forMethod: "\( className ).prototype.remove" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/:id", verb:"GET" ), forMethod: "\( className ).findById" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )", verb:"GET" ), forMethod: "\( className ).all" )

        return contract;
    }

    public func modelWithDictionary( dictionary:NSDictionary ) -> LBModel {
        let model:LBModel = self.modelClass!.init( repository:self, parameters:dictionary as Dictionary<NSObject, AnyObject> )

        let overflowDictionary:NSMutableDictionary! = ( model.overflow as NSDictionary ).mutableCopy() as! NSMutableDictionary
        overflowDictionary.addEntriesFromDictionary( dictionary as [NSObject : AnyObject] )

        let overflowReplacementDictionary = overflowDictionary as Dictionary
        model.overflow = overflowReplacementDictionary as! Dictionary<String, AnyObject>

        for (key, value) in dictionary {
            let keyName = key as! String

            //var attributeType = value.attributeType
            
           
            if let p : AnyObject? = overflowDictionary.objectForKey(keyName) {
                if !(value is NSNull) {
                    
                    model.setValue(value, forKey: keyName)
                }
            }
           
        }
        return model
    }
    
    public func findById( id:AnyObject!, success:( LBModel ) -> (), failure: ( NSError! ) -> () ) {
        invokeStaticMethod( "findById", parameters: [ "id": id ], success: { ( value ) -> Void in
            assert( value is NSDictionary, "Received non-Dictionary: \( value )" )
            success( self.modelWithDictionary( value as! NSDictionary ) )
            
            }, failure:failure )
    }
    
    public func findAll( success:( [LBModel] ) -> (), failure: ( NSError! ) -> () ) {
        invokeStaticMethod( "all", parameters: [:], success: { ( value ) -> Void in
            assert( value is [AnyObject], "Received non-Array: \( value )" )
            let tmp:[AnyObject] = value as! [AnyObject]
            let ret = tmp.map {
                ( val ) -> LBModel in
                return self.modelWithDictionary( val as! NSDictionary )
            }
            success(ret)
            
            }, failure:failure )
    }
    
    public func find(parameters:[String:AnyObject], success:( [LBModel] ) -> (), failure: ( NSError! ) -> () ) {
        invokeStaticMethod( "all", parameters: parameters, success: { ( value ) -> Void in
            assert( value is [AnyObject], "Received non-Array: \( value )" )
            let tmp:[AnyObject] = value as! [AnyObject]
            let ret = tmp.map {
                ( val ) -> LBModel in
                return self.modelWithDictionary( val as! NSDictionary )
            }
            success(ret)
            
            }, failure:failure )
    }
    
    public func findOne(parameters:[String:AnyObject], success:( LBModel ) -> (), failure: ( NSError! ) -> () ) {
        invokeStaticMethod( "all", parameters: parameters, success: { ( value ) -> Void in
            
            assert( value is [AnyObject], "Received non-Array: \( value )" )
            let tmp:[AnyObject] = value as! [AnyObject]
            var val : AnyObject?
            if value.count > 0 {
                success( self.modelWithDictionary( value[0] as! NSDictionary ) )
            } else {
                success( self.modelWithDictionary( NSDictionary() ) )
            }
            
            
            }, failure:failure )
    }
}












