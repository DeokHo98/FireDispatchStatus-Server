import Vapor

actor PreviousStorage {
    
    static let shared = PreviousStorage()
    
    var list: [TransformedDetail] = []
    
    func update(list: [TransformedDetail]) {
        self.list = list
    }
}

func routes(_ app: Application) throws {
    let eventLoop = app.eventLoopGroup.next().scheduleRepeatedTask(
        initialDelay: .zero,
        delay: .seconds(60)
    ) { task in
        Task {
            do {
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
                
                let currentResponse = TransformedResponse(list: originalResponse.defail.map { original in
                    TransformedDetail(
                        centerName: original.cntrNm,
                        date: original.overDate,
                        state: original.progressStat,
                        address: original.addr,
                        deadNum: original.dethNum,
                        injuryNum: original.injuNum
                    )
                })
                
                let currentList = currentResponse.list
                print("debug1 \(currentList.count)")
                let previousList = await PreviousStorage.shared.list
                print("debug2 \(previousList.count)")
                checkForUpdates(newList: currentList, previousList: previousList)
                await PreviousStorage.shared.update(list: currentList)
            } catch {
                app.logger.error("모니터링 중 오류 발생: \(error)")
            }
        }
    }
    
    // API 엔드포인트
    app.get("api", "firedispatchstatus") { req async throws -> TransformedResponse in
        let list = await PreviousStorage.shared.list
        return TransformedResponse(list: list)
    }
}

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

// 변환된 응답을 위한 구조체
struct TransformedResponse: Content {
    let list: [TransformedDetail]
}

struct TransformedDetail: Content, Equatable {
    let centerName: String
    let date: String
    let state: String
    let address: String
    let deadNum: Int
    let injuryNum: Int
}


func checkForUpdates(newList: [TransformedDetail], previousList: [TransformedDetail]) {
     // 1. 새로운 출동 확인
     let newResponses = findNewResponses(newList: newList, previousList: previousList)
     for response in newResponses {
         print("🚒 새로운 출동 발생: \(response.centerName)")
         print("   위치: \(response.address)")
         print("   시간: \(response.date)")
     }
     
     // 2. 상태 변경 확인
     let stateChanges = findStateChanges(newList: newList, previousList: previousList)
     for change in stateChanges {
         print("🔄 상태 변경 발생: \(change.centerName)")
         print("   이전 상태: \(change.oldState)")
         print("   새로운 상태: \(change.newState)")
     }
 }
 
private func findNewResponses(newList: [TransformedDetail], previousList: [TransformedDetail]) -> [TransformedDetail] {
     return newList.filter { newResponse in
         !previousList.contains { oldResponse in
             oldResponse.centerName == newResponse.centerName &&
             oldResponse.date == newResponse.date &&
             oldResponse.address == newResponse.address
         }
     }
 }
 
 private struct StateChange {
     let centerName: String
     let oldState: String
     let newState: String
 }
 
 private func findStateChanges(newList: [TransformedDetail],  previousList: [TransformedDetail]) -> [StateChange] {
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
