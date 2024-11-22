//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/18/24.
//
import Fluent
import Vapor

final class FireDispatch: Model, Content {
    static let schema = "fire_dispatches"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "center_name")
    var centerName: String
    
    @Field(key: "date")
    var date: String
    
    @Field(key: "state")
    var state: String
    
    @Field(key: "address")
    var address: String
    
    @Field(key: "dead_num")
    var deadNum: Int
    
    @Field(key: "injury_num")
    var injuryNum: Int
    
    @Field(key: "side_over_num")
    var sidoOvrNum: String
    
    init() {}
    
    init(id: UUID? = nil, centerName: String, date: String, state: String, address: String, deadNum: Int, injuryNum: Int, sidoOvrNum: String) {
        self.id = id
        self.centerName = centerName
        self.date = date
        self.state = state
        self.address = address
        self.deadNum = deadNum
        self.injuryNum = injuryNum
        self.sidoOvrNum = sidoOvrNum
    }
}

struct FireDispatchResponse: Content {
    let centerName: String
    let date: String
    let state: String
    let address: String
    let deadNum: Int
    let injuryNum: Int
    let sidoOvrNum: String

    
    init(from dispatch: FireDispatch) {
        self.centerName = dispatch.centerName
        self.date = dispatch.date
        self.state = dispatch.state
        self.address = dispatch.address
        self.deadNum = dispatch.deadNum
        self.injuryNum = dispatch.injuryNum
        self.sidoOvrNum = dispatch.sidoOvrNum
    }
}

extension Array where Element == FireDispatch {
    func toResponseDTO() -> [FireDispatchResponse] {
        return self.map { FireDispatchResponse(from: $0) }
    }
}
