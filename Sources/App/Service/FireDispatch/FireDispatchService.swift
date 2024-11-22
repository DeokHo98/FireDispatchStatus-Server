//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/18/24.
//

import Vapor
import Fluent
import FCM

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
                date: getDateString(original.overDate ?? "-"),
                state: getStateString(stateCode: original.progressStat ?? "-",
                                      state: original.progressNm ?? "-",
                                      frfalType: original.frfalTypeCd),
                address: original.addr ?? "-",
                deadNum: original.dethNum ?? 0,
                injuryNum: original.injuNum ?? 0,
                sidoOvrNum: original.sidoOvrNum ?? "-"
            )
        }
    }
    
    // 업데이트 확인 및 로깅
    func checkForUpdates(newList: [FireDispatch], previousList: [FireDispatch], app: Application) -> Bool {
        if !previousList.isEmpty && newList.isEmpty {
            return true
        }
        
        let newResponses = findNewResponses(newList: newList, previousList: previousList, app: app)
        for response in newResponses {
            app.logger.info("🚒🚒 \(response.centerName) 새로운 출동 발생")
            app.logger.info("위치: \(response.address) 시간: \(response.date)")
        }
  
        let stateChanges = findStateChanges(newList: newList, previousList: previousList)
        for change in stateChanges {
            app.logger.info("🔄🔄 \(change.centerName) \(change.newState)")
            app.logger.info("위치: \(change.address) 시간: \(change.date)")
        }
        return !newResponses.isEmpty || !stateChanges.isEmpty
    }
    
    private func findNewResponses(newList: [FireDispatch], previousList: [FireDispatch], app: Application) -> [FireDispatch] {
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
    
    private func getDateString(_ date: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH시 mm분"
        guard let formatedDate = inputFormatter.date(from: date) else { return date }
        return outputFormatter.string(from: formatedDate)
    }
    
    private func getStateString(stateCode: String, state: String, frfalType: String?) -> String {
        var string = ""
        switch stateCode {
        case "A":
            string = "화재접수"
        case "B":
            string = "화재출동"
        case "C":
            string = "현장도착"
        case "F":
            string = "귀소"
        case "H":
            string = "잔불감시"
        default:
            string = state
        }
        guard let frfalType, !frfalType.isEmpty else { return string }
        return string + " (\(frfalType))"
    }
    
    private func sendFCMNewFire(model: FireDispatch, app: Application) {
//        let token = "coKNBm8uTUbDkpQpvIMRw8:APA91bGhfbO5gZAIF8dZ9EU6HfSFkKKKGqjjwlUa7iRcvJy3CyD3Rh3WNreZh4sJRmBh7DUBPxm2K0OJw_TmRigSla-w5k_PhF-dRrvoAP6AOWfI7LWcj78"
//        let notification = FCMNotification(
//            title: "🚒🚒 \(model.centerName)",
//            body: "새로운 화재신고가 접수 되었습니다.\n주소: \(model.address)"
//        )
//        let message = FCMMessage(token: token, notification: notification)
//        let sendResult = app.fcm.send(message)
//        sendResult.whenSuccess { response in
//            app.logger.info("새로운화재 푸시 전송 성공: \(response)")
//        }
//        sendResult.whenFailure { error in
//            app.logger.error("새로운 화재 푸시 전송 실패: \(error.localizedDescription)")
//        }
    }
    
    private func sendFCMUpdateFire(model: StateChange, app: Application) {
//        let token = "coKNBm8uTUbDkpQpvIMRw8:APA91bGhfbO5gZAIF8dZ9EU6HfSFkKKKGqjjwlUa7iRcvJy3CyD3Rh3WNreZh4sJRmBh7DUBPxm2K0OJw_TmRigSla-w5k_PhF-dRrvoAP6AOWfI7LWcj78"
//        let notification = FCMNotification(
//            title: "🔄🔄 \(model.centerName)",
//            body: "\(model.oldState) -> \(model.newState)\n주소: \(model.address)"
//        )
//        let message = FCMMessage(token: token, notification: notification)
//        let sendResult = app.fcm.send(message)
//        sendResult.whenSuccess { response in
//            app.logger.info("상태변경 푸시 전송 성공: \(response)")
//        }
//        sendResult.whenFailure { error in
//            app.logger.error("상태변경 푸시 전송 실패: \(error.localizedDescription)")
//        }
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
