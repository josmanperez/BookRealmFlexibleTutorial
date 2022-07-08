//
//  User.swift
//  BookTutorialFlexible
//
//  Created by Josman Pedro Pérez Expósito on 9/6/22.
//

import Foundation
import RealmSwift

class User: Object {
    
    @Persisted(primaryKey: true) var _id: String = ""
    @Persisted var favoriteBooks: List<ObjectId>
    @Persisted var favoriteRelatedBooks: List<ObjectId>
    @Persisted var providerType: ProviderType?
    @Persisted var registered: Bool = false
    @Persisted var userName: String?
    @Persisted var userPreferences: UserPreferences?
}

class ProviderType: EmbeddedObject {
    
    @Persisted var id: String?
    @Persisted var provider_type: ProviderTypeEnum?
}

class UserPreferences: EmbeddedObject {
    
    @Persisted var displayName: String?
}

enum ProviderTypeEnum: String, PersistableEnum {
    case anon = "anon-user"
    case userpass = "local-userpass"
}

