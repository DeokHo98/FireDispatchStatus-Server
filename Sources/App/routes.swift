import Vapor

func routes(_ app: Application) throws {
    app.get("api", "firedispatchstatus") { req async throws -> TransformedResponse in
        let url = "https://nfds.go.kr/dashboard/monitorData.do"
        
        var headers = HTTPHeaders()
        headers.add(name: .accept, value: "application/json, text/javascript, */*; q=0.01")
        headers.add(name: .acceptEncoding, value: "gzip, deflate, br, zstd")
        headers.add(name: .acceptLanguage, value: "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7")
        headers.add(name: .cacheControl, value: "no-cache")
        headers.add(name: .connection, value: "keep-alive")
        headers.add(name: .contentType, value: "application/x-www-form-urlencoded; charset=UTF-8")
        headers.add(name: .cookie, value: "JSESSIONID=LFYiBTBin+ehhZ00W+xN8mgf.node20; clientid=050009318656")
        headers.add(name: .origin, value: "https://nfds.go.kr")
        headers.add(name: .referer, value: "https://nfds.go.kr/dashboard/monitor.do")
        headers.add(name: .xRequestedWith, value: "XMLHttpRequest")
        headers.add(name: .userAgent, value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36")

        let apiResponse = try await req.client.post(URI(string: url), headers: headers)
        
        guard let body = apiResponse.body,
              let responseString = body.getString(at: body.readerIndex, length: body.readableBytes),
              let responseData = responseString.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "응답 데이터를 처리할 수 없습니다.")
        }
        
        // 원본 응답을 디코딩
        let originalResponse = try JSONDecoder().decode(OriginalResponse.self, from: responseData)
        
        // 새로운 형식으로 변환
        let transformedDetails = originalResponse.defail.map { original in
            TransformedDetail(
                centerName: original.cntrNm,
                date: original.overDate,
                state: original.progressStat,
                address: original.addr,
                deadNum: original.dethNum,
                injuryNum: original.injuNum
            )
        }
        
        // 변환된 응답 반환
        return TransformedResponse(list: transformedDetails)
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

struct TransformedDetail: Content {
    let centerName: String
    let date: String
    let state: String
    let address: String
    let deadNum: Int
    let injuryNum: Int
}
