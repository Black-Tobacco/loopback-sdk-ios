//
//  LBModel.swift
//  LoopBack
//
//  Created by Jonathon Hibbard on 12/29/14.
//  Copyright (c) 2014 StrongLoop. All rights reserved.
//

import Foundation

// Source: http://stackoverflow.com/a/24045523/1244184
extension String {
    subscript ( r: Range<Int> ) -> String {
        get {
            let subStart = advance( self.startIndex, r.startIndex, self.endIndex )
            let subEnd = advance( subStart, r.endIndex - r.startIndex, self.endIndex )
            return self.substringWithRange( Range( start: subStart, end: subEnd ) )
        }
    }
    
    func substring( from: Int ) -> String {
        let end = countElements( self )
        return self[from..<end]
    }
    
    func substring( from: Int, length: Int ) -> String {
        let end = from + length
        return self[from..<end]
    }
}

class LBModel: SLObject, Printable {

    /** All Models have a numerical `id` field. */
    private( set ) var id:AnyObject?
    private( set ) var overflow = Dictionary<String, AnyObject>()

    subscript( Tk: String ) -> AnyObject! {
        get {
            return overflow[Tk]
        }

        set( Tv ) {
            overflow[Tk] = Tv
        }
    }
    
    override var description: String {
        let className = class_getName( object_getClass( self ) )
        let selfAsDict = toDictionary()
        
        return "<\( className ), \( selfAsDict )>"
    }

    override init!(repository: SLRepository!, parameters: Dictionary<NSObject,AnyObject>! ) {
        super.init()

        overflow = Dictionary()
    }

    func setId(  idValue:AnyObject ) {
        self.id = idValue
    }

    func toDictionary() -> NSDictionary {
        var dict = overflow

        var propertiesCount : CUnsignedInt = 0
        let propertiesInAClass = class_copyPropertyList( object_getClass( self ), &propertiesCount )

        var z = Int( propertiesCount )
        var i = 0

        for i = 0; i < z; i++ {
            var property = propertiesInAClass[i]
            let propertyName = NSString( CString: property_getName( property ), encoding: NSUTF8StringEncoding )

            if propertyName != nil {
                if propertyName == "id" {
                    continue
                }

                dict[propertyName!] = valueForKey( propertyName! )
            }
        }

        return dict
    }

    func save( success:() -> (), failure:( NSError! ) -> () ) {
        var methodToInvoke = id != nil ? "save": "create"

        invokeMethod( methodToInvoke, parameters: toDictionary(), success: { [unowned self]( value ) -> Void in
            self.id = value["id"]
            success()
        }, failure: failure )
    }

    func destroy( success:() -> (), failure:( NSError! ) -> () ) {
        invokeMethod( "remove", parameters: toDictionary(), success: { [unowned self]( value ) -> Void in
            success()
        }, failure: failure )
    }
}


class LBModelRepository : SLRepository {

    var modelClass:AnyClass?

    override init() {
        super.init()
    }

    override init!( className name: String! ) {
        super.init( className:name )

        var modelClassName:String = String.fromCString( class_getName( object_getClass( self ) ) )!
        let strlenOfRepository = 10

        modelClassName.substring( 0, length: countElements( modelClassName ) - strlenOfRepository )

        self.modelClass = NSClassFromString( modelClassName );
        if self.modelClass == nil {
            self.modelClass = object_getClass( LBModel )
        }
    }

    func contract() -> SLRESTContract {
        var contract = SLRESTContract()

        contract.addItem( SLRESTContractItem( pattern: "/\( className )", verb:"POST" ), forMethod: "\( className ).prototype.create" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/:id", verb:"PUT" ), forMethod: "\( className ).prototype.save" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/:id", verb:"DELETE" ), forMethod: "\( className ).prototype.remove" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )/:id", verb:"GET" ), forMethod: "\( className ).findById" )
        contract.addItem( SLRESTContractItem( pattern: "/\( className )", verb:"GET" ), forMethod: "\( className ).all" )

        return contract;
    }

    func modelWithDictionary( dictionary:NSDictionary ) -> LBModel {
        var model:LBModel = LBModel( repository:self, parameters:dictionary )

        var overflowDictionary:NSMutableDictionary! = ( model.overflow as NSDictionary ).mutableCopy() as NSMutableDictionary
        overflowDictionary.addEntriesFromDictionary( dictionary )

        let overflowReplacementDictionary = overflowDictionary as Dictionary
        model.overflow = overflowReplacementDictionary as Dictionary<String, AnyObject>


        dictionary.enumerateKeysAndObjectsUsingBlock { ( key, obj, stop ) -> Void in
            var setter:Selector = NSSelectorFromString( key as String )

            if model.respondsToSelector( setter ) {

                // SURELY there is a better way... ?.... :\ :| :~(
                var timer = NSTimer.scheduledTimerWithTimeInterval( 0.00001, target: model, selector:setter, userInfo: obj, repeats: false )
                let mainLoop = NSRunLoop.mainRunLoop()

                mainLoop.addTimer( timer, forMode: NSDefaultRunLoopMode )
            }
        }

        return model
    }

    func findById( id:AnyObject!, success:( LBModel ) -> (), failure: ( NSError! ) -> () ) {

        invokeStaticMethod( "findById", parameters: [ "id": id ], success: { [unowned self]( value ) -> Void in
            assert( value is NSDictionary, "Received non-Dictionary: \( value )" )
            success( self.modelWithDictionary( value as NSDictionary ) )

        }, failure:failure )
    }
}












