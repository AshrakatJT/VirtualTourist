//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ashrakat Sherif on 22/05/2022.
//

import Foundation

class FlickrClient {
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/"
        case getPhotos(Double, Double)
        case getUrls(String, String, String)
        
        struct Auth {
            static let apiKey = "f570d8534ebf1866cd7d713dffd218e7"
        }
        var stringValue: String {
            switch self {
            case.getPhotos(let latitude, let longitude): return
                Endpoints.base + "&api_key=\(Auth.apiKey)&lat=\(latitude)&lon=\(longitude)&per_page=20&page=\(Int.random(in: 1...10))&format=json&nojsoncallback=1"
            case .getUrls(let serverId, let id, let secret): return
                "https://live.staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
                }
            }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    @discardableResult class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            guard let data = data
            else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
                }
            let decoder = JSONDecoder()
            print(String(data: data, encoding: .utf8)!)
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        return task
    }
    class func getPhotos(latitude: Double, longitude: Double, completion: @escaping(PhotoResponse?, Error?) -> Void ){
        taskForGETRequest(url: Endpoints.getPhotos(latitude, longitude).url, responseType:PhotoResponse.self){
            response, error in
            if let response = response {
                completion(response.self, nil)
                print(response)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func downloadPhotos(imageURL: URL, completion: @escaping (Data?, Error?) throws -> Void) {
        let task = URLSession.shared.dataTask(with: imageURL) {
            data, response, error in
            guard let data = data
            else {
                DispatchQueue.main.async {
                    try? completion(nil, error)
                }
            return
            }
            DispatchQueue.main.async {
                try? completion(data, nil)
            }
        }
        task.resume()
    }
            
}

