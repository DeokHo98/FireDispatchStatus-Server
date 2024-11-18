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
            let state = switch original.progressStat {
            case "A": "화재접수"
            case "B": "출동"
            case "C": "현장 도착"
            case "F": "귀소"
            case "E": "완진"
            case "H": "잔불감시"
            default: "알수 없는 상태"
            }
            return FireDispatch(
                centerName: original.cntrNm,
                date: original.overDate,
                state: state,
                address: original.addr,
                deadNum: original.dethNum,
                injuryNum: original.injuNum
            )
        }
    }
    
    // 업데이트 확인 및 로깅
    func checkForUpdates(newList: [FireDispatch], previousList: [FireDispatch]) -> Bool {
        let newResponses = findNewResponses(newList: newList, previousList: previousList)
        for response in newResponses {
            print("🚒 새로운 출동 발생: \(response.centerName)")
            print("   위치: \(response.address)")
            print("   시간: \(response.date)")
        }
        
        let stateChanges = findStateChanges(newList: newList, previousList: previousList)
        for change in stateChanges {
            print("🔄 상태 변경 발생: \(change.centerName)")
            print("   이전 상태: \(change.oldState)")
            print("   새로운 상태: \(change.newState)")
        }
        return !newResponses.isEmpty && !stateChanges.isEmpty
    }
    
    private func findNewResponses(newList: [FireDispatch], previousList: [FireDispatch]) -> [FireDispatch] {
        return newList.filter { newResponse in
            !previousList.contains { oldResponse in
                oldResponse.centerName == newResponse.centerName &&
                oldResponse.date == newResponse.date &&
                oldResponse.address == newResponse.address
            }
        }
    }
    
    private func findStateChanges(newList: [FireDispatch], previousList: [FireDispatch]) -> [StateChange] {
        var changes: [StateChange] = []
        
        for newResponse in newList {
            if let oldResponse = previousList.first(where: {
                $0.centerName == newResponse.centerName &&
                $0.date == newResponse.date &&
                $0.address == newResponse.address
            }) {
                if oldResponse.state != newResponse.state {
                    changes.append(StateChange(
                        centerName: newResponse.centerName,
                        oldState: oldResponse.state,
                        newState: newResponse.state
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
    }
}
