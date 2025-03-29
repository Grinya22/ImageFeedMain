//
//  Constants.swift
//  ImageFeed
//
//  Created by Gregory Vanyurin on 20.03.2025.
//

import UIKit

enum Constants {
    static let accessKey = "u15mRlVXuYIjj_vstcVwraoGeVBasdJBI6g2Cq7WnVc"
    static let secretKey = "HSRpBF_Mj3Bl4c3wReUHfbzHGq7MdGsiUmckfTn-VUA"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    
    static let accessScope = "public+read_user+write_likes"
    
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
}
