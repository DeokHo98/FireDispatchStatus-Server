//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/18/24.
//

import Foundation

// 원본 응답을 위한 구조체
struct OriginalResponse: Codable {
    let defail: [OriginalDetail]
}

struct OriginalDetail: Codable {
    let cntrNm: String
    let overDate: String
    let progressStat: String
    let addr: String
    let dethNum: Int
    let injuNum: Int
}


