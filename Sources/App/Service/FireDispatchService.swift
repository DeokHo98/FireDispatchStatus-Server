//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/18/24.
//

import Vapor
import Fluent

struct FireDispatchService {
    // API 데이터 가져오기
    func fetchCurrentData(app: Application) async throws -> [FireDispatch] {
        let url = "https://nfds.go.kr/dashboard/monitorData.do"
        var headers = HTTPHeaders()
        headers.add(name: .userAgent, value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36")
        
        let apiResponse = try await app.client.get(URI(string: url), headers: headers)
        
        guard let body = apiResponse.body,
              let responseString = body.getString(at: body.readerIndex, length: body.readableBytes),
              let responseData = responseString.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "응답 데이터를 처리할 수 없습니다.")
        }
        
        let originalResponse = try JSONDecoder().decode(OriginalResponse.self, from: responseData)
        
        return originalResponse.defail.map { original in
            return FireDispatch(
                centerName: original.cntrNm ?? "-",
                date: original.overDate ?? "-",
                state: original.progressNm ?? "-",
                address: original.addr ?? "-",
                deadNum: original.dethNum ?? 0,
                injuryNum: original.injuNum ?? 0,
                sidoOvrNum: original.sidoOvrNum ?? "-"
            )
        }
    }
    
    // 업데이트 확인 및 로깅
    func checkForUpdates(newList: [FireDispatch], previousList: [FireDispatch]) -> Bool {
        let newResponses = findNewResponses(newList: newList, previousList: previousList)
        for response in newResponses {
            print("🚒🚒 \(response.centerName) 새로운 출동 발생")
            print("위치: \(response.address) 시간: \(response.date)")
        }
        
        let stateChanges = findStateChanges(newList: newList, previousList: previousList)
        for change in stateChanges {
            print("🔄🔄 \(change.centerName) \(change.newState)")
            print("위치: \(change.address) 시간: \(change.date)")
        }
        return !newResponses.isEmpty || !stateChanges.isEmpty
    }
    
    private func findNewResponses(newList: [FireDispatch], previousList: [FireDispatch]) -> [FireDispatch] {
        return newList.filter { newResponse in
            !previousList.contains { oldResponse in
                oldResponse.centerName == newResponse.centerName &&
                oldResponse.date == newResponse.date &&
                oldResponse.address == newResponse.address &&
                oldResponse.sidoOvrNum == newResponse.sidoOvrNum
            }
        }
    }
    
    private func findStateChanges(newList: [FireDispatch], previousList: [FireDispatch]) -> [StateChange] {
        var changes: [StateChange] = []
        
        for newResponse in newList {
            if let oldResponse = previousList.first(where: {
                $0.centerName == newResponse.centerName &&
                $0.date == newResponse.date &&
                $0.address == newResponse.address &&
                $0.sidoOvrNum == newResponse.sidoOvrNum
            }) {
                if oldResponse.state != newResponse.state {
                    changes.append(StateChange(
                        centerName: newResponse.centerName,
                        oldState: oldResponse.state,
                        newState: newResponse.state,
                        address: newResponse.address,
                        date: newResponse.date
                    ))
                }
            }
        }
        
        return changes
    }
}

extension FireDispatchService {
    private struct StateChange {
        let centerName: String
        let oldState: String
        let newState: String
        let address: String
        let date: String
    }
}
