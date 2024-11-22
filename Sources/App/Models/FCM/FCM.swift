//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/22/24.
//

import Vapor
import Fluent

final class FCM: Model, Content {
    static let schema = "fcm_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "center_name")
    var centerName: String
    
    @Field(key: "device_id")
    var deviceId: String
    
    init() { }
    
    init(id: UUID? = nil, token: String, centerName: String, deviceId: String) {
        self.id = id
        self.token = token
        self.centerName = centerName
        self.deviceId = deviceId
    }
}
