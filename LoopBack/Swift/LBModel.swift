//
//  LBModel.swift
//  LoopBack
//
//  Created by Jonathon Hibbard on 12/29/14.
//  Copyright (c) 2014 StrongLoop. All rights reserved.
//

import Foundation

class LBModel: SLObject, Printable {

    override var description: String {
        let className = class_getName( object_getClass( self ) )
        let selfAsDict = toDictionary()

        return "<\( className ), \( selfAsDict )>"
    }

    var LBModelSaveSuccessBlock:() -> () = {
        () -> Void in
    }

    var LBModelDestroySuccessBlock:() -> () = {
        () -> Void in
    }

    var SLFailureBlock:( NSError! ) -> () = {
        ( NSError ) -> Void in
    }

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
}