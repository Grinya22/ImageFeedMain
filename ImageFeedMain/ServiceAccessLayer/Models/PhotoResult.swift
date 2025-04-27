import Foundation

struct PhotoResult: Codable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let description: String?
    let isLikedByUser: Bool
    let urls: UrlsResult
    var createdAtDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, width, height
        case createdAt = "created_at"
        case description
        case isLikedByUser = "liked_by_user"
        case urls
    }
    
    mutating func convertCreatedAtToDate() {
        guard let createdAtString = createdAt else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.createdAtDate = dateFormatter.date(from: createdAtString)
    }
}
