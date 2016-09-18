//
//  Movie.swift
//  OfflineMovies
//
//  Created by Douwe Osinga on 9/8/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

import Foundation
import UIKit

struct Movie {
    let id: Int
    let title: String
    let starring: String
    let director: String?
    let writtenBy: String?
    let runningTime: String?
    let releaseDate: String?
    let language: String?
    let reception: String?
    let image: UIImage?

    init(id: Int, title: String, starring: String) {
        self.id = id
        self.title = title
        self.starring = starring
        self.director = nil
        self.writtenBy = nil
        self.runningTime = nil
        self.releaseDate = nil
        self.language = nil
        self.reception = nil
        self.image = nil
    }

    init(id: Int, title: String, starring: String, director: String?, writtenBy: String?, runningTime: String?, releaseDate: String?, language: String?, reception: String?, image: UIImage?) {
        self.id = id
        self.title = title
        self.starring = starring
        self.director = director
        self.writtenBy = writtenBy
        self.runningTime = runningTime
        self.releaseDate = releaseDate
        self.language = language
        self.reception = reception
        self.image = image
    }

}
