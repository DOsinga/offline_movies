//
//  StoredMovies.swift
//  OfflineMovies
//
//  Created by Douwe Osinga on 9/8/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

import Foundation
import SQLite
import SDWebImage

protocol MoviesUpdated: class {
    func newMoviesAvailable(movies: [Movie]?)
}


class StoredMovies {
    let db: Connection?
    var filteredMovies = [Movie]()
    var numberOfMovies: Int
    var query: String?
    var delegate: MoviesUpdated?
    var isQuerying: Bool
    
    init()  {
        let path = NSBundle.mainBundle().pathForResource("movies", ofType: "db")
        do {
            self.db = try Connection(path!)
        } catch _ {
            self.db = nil
        }
        self.numberOfMovies = -1
        self.query = nil
        self.delegate = nil
        self.isQuerying = false
    }
    
    func notifyUpdate(movies: [Movie]) {
        dispatch_async(dispatch_get_main_queue(),{
            self.filteredMovies = movies
            self.delegate?.newMoviesAvailable(movies)
        });
    }
    
    func startQuery(query: String) {
        if self.query == query {
            return
        }
        self.query = query
        if self.isQuerying {
            return
        }
        self.isQuerying = true
        var countStatement : Binding?
        if (query == "") {
            countStatement = self.db!.scalar("SELECT count(rowid) FROM movie");
        } else {
            countStatement = self.db!.scalar("SELECT count(rowid) from movie_text where movie_text match ? ORDER BY title", query + "*");
        }
        self.numberOfMovies = Int(countStatement as! Int64)
        self.notifyUpdate([])

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var soFar = [Movie]()
            while true {
                let currentQuery = self.query!
                var statement : Statement?
                do {
                    if (query == "") {
                        statement = try self.db!.prepare("SELECT rowid, title, starring FROM movie ORDER BY title");
                    } else {
                        statement = try self.db!.prepare("SELECT rowid, title, starring FROM movie WHERE rowid in (select rowid from movie_text where movie_text match ?) ORDER BY title", currentQuery + "*");
                    }
                    var count = 0
                    for row in statement! {
                        soFar.append(Movie(id: Int(row[0] as! Int64), title: row[1] as! String, starring: row[2] as! String))
                        if (currentQuery != self.query) {
                            break
                        }
                        count += 1
                        if (count % 500 == 0) {
                            self.notifyUpdate(soFar)
                        }
                    }
                } catch _ {
                    return;
                }
                if (currentQuery == self.query) {
                    break
                }
            }
            self.notifyUpdate(soFar)
            self.isQuerying = false
        })
    }
    
    func movieCount() -> Int {
        if self.numberOfMovies == -1 { // first time
            self.startQuery("")
        }
        return self.numberOfMovies
    }
    
    func movieAt(index : Int) -> Movie? {
        if index < 0 || index >= self.filteredMovies.count {
            return nil;
        }
        return self.filteredMovies[index]
    }

    func detailedMovieAt(index : Int) -> Movie? {
        let fromMovie = self.movieAt(index)
        if (fromMovie == nil) {
            return nil;
        }
        do {
            let statement = try self.db!.prepare("SELECT title, starring, director, written_by, running_time, release_date, language, reception, image FROM movie WHERE rowid = ?", fromMovie!.id);
            for row in statement {
                var image : UIImage?
                if let blob = row[8] as? Blob {
                    let data = NSData(bytes: blob.bytes, length: blob.bytes.count)
                    image = UIImage.sd_imageWithWebPData(data)
                }
                
                if image == nil {
                    image = UIImage(named: "placeholder.png")!;
                }
                return Movie(id: fromMovie!.id,
                             title: row[0] as! String,
                             starring: row[1] as! String,
                             director: row[2] as? String,
                             writtenBy: row[3] as? String,
                             runningTime: row[4] as? String,
                             releaseDate: row[5] as? String,
                             language: row[6] as? String,
                             reception: row[7] as? String,
                             image: image
                )
            }
        } catch _ {
            return nil;
        }
        return nil;
    }
    
    func imageAt(index : Int) -> UIImage? {
        if let fromMovie = self.movieAt(index) {
            do {
                let statement = try self.db!.prepare("SELECT image FROM movie WHERE title = ?", fromMovie.title);
                for row in statement {
                    if let blob = row[0] as? Blob {
                        let data = NSData(bytes: blob.bytes, length: blob.bytes.count)
                        return UIImage.sd_imageWithWebPData(data)
                    }
                }
            } catch _ {
                // pass
            }
        }
        return nil;
    }

}