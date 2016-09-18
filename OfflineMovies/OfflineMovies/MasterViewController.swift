//
//  MasterViewController.swift
//  OfflineMovies
//
//  Created by Douwe Osinga on 9/8/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

import UIKit
import SQLite

class MasterViewController: UITableViewController, MoviesUpdated {
    
    let storedMovies = StoredMovies()
    var detailViewController: DetailViewController? = nil
    let searchController = UISearchController(searchResultsController: nil)
    var cellMovieMap = [UITableViewCell: Int]()
    let imageCache = NSCache()
    let imageQueue = dispatch_queue_create("com.douweosinga.offlinemovies.images", DISPATCH_QUEUE_SERIAL)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        self.storedMovies.delegate = self

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            split.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        }
    }
    
    func runSearch(searchedFor: String) {
        self.storedMovies.startQuery(searchedFor)
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let movie = storedMovies.detailedMovieAt(indexPath.row) {
                    let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                    controller.detailItem = movie
                    controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }
    
    @IBAction func unwindToList(segue:UIStoryboardSegue) {
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.storedMovies.movieCount()
        if count == 0 {
            return 1
        } else {
            return count
        }
    }

    func cellStillLinked(cell: UITableViewCell, movie: Movie) -> Bool {
        objc_sync_enter(self.cellMovieMap)
        let curVal = self.cellMovieMap[cell]
        objc_sync_exit(self.cellMovieMap)
        return curVal == movie.id
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        if let movie = storedMovies.movieAt(indexPath.row) {
            objc_sync_enter(self.cellMovieMap)
            self.cellMovieMap[cell] = movie.id
            objc_sync_exit(self.cellMovieMap)
            cell.textLabel!.text = movie.title
            cell.detailTextLabel!.text = movie.starring
            if let cachedImage = self.imageCache.objectForKey(movie.id) as! UIImage? {
                cell.imageView!.image = cachedImage;
            } else {
                dispatch_async(self.imageQueue) {
                    if self.cellStillLinked(cell, movie: movie) {
                        var image = self.storedMovies.imageAt(indexPath.row)
                        if image == nil {
                            image = UIImage(named: "placeholder.png")!;
                        } else {
                            self.imageCache.setObject(image!, forKey: movie.id)
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            if self.cellStillLinked(cell, movie: movie) {
                                cell.imageView!.image = image
                            }
                        }
                    }
                }
            }
        } else {
            if self.storedMovies.movieCount() == 0 {
                cell.textLabel!.text = "No movies found"
                cell.detailTextLabel!.text = ""
            } else {
                cell.textLabel!.text = "Loading..."
                cell.detailTextLabel!.text = ""
            }
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func newMoviesAvailable(movies: [Movie]?) {
        tableView.reloadData()
    }
}

extension MasterViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        runSearch(searchController.searchBar.text!)
    }
}


