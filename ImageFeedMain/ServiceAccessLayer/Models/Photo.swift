import CoreGraphics
import Foundation

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let smallImageURL: String
    let regularImageURL: String
    let fullImageURL: String
    let isLiked: Bool
}
