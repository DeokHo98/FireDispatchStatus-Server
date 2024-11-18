//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/18/24.
//

import Vapor

struct FireDispatchController {
    // API 엔드포인트 핸들러
    func index(req: Request) async throws -> [FireDispatchResponse] {
        let dispatches = try await FireDispatch.query(on: req.db).all()
             return dispatches.toResponseDTO()
    }
    
    // 데이터 업데이트 핸들러
    func updateData(app: Application) async throws {
        do {
            let service = FireDispatchService()
            let currentList = try await service.fetchCurrentData(app: app)
            let previousList = try await FireDispatch.query(on: app.db).all()
          
            // 상태 변경 확인 및 로깅
            if service.checkForUpdates(newList: currentList, previousList: previousList) {
                app.logger.info("이전 데이터: \(previousList.count)개")
                app.logger.info("업데이트 데이터: \(currentList.count)개")
                // 데이터베이스 업데이트
                try await FireDispatch.query(on: app.db).delete()
                
                for dispatch in currentList {
                    try await dispatch.save(on: app.db)
                }
            } else {
                app.logger.info("업데이트 데이터 없음")
            }
        } catch {
            app.logger.error("데이터 업데이트 중 오류 발생: \(error)")
            throw error
        }
    }
}
