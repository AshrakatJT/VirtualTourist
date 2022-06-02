//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Ashrakat Sherif on 22/05/2022.
//

import Foundation

struct PhotoResponse: Codable {
    let photos: Photos
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case photos = "photos"
        case status = "stat"
    }
}
struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [FlickrPhoto]
}

struct FlickrPhoto: Codable {
    let id: String
    let secret: String
    let server: String
    
    
}
