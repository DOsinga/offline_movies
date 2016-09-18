//
//  MovieTableCell.swift
//  OfflineMovies
//
//  Created by Douwe Osinga on 9/9/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

import Foundation
import UIKit

class MovieTableCell : UITableViewCell {
    let ImageSize = CGFloat(30)
    
    func transpose(rect: CGRect?, delta: CGFloat) -> CGRect {
        if (rect == nil) {
            return CGRectMake(0, 0, 0, 0);
        }
        return CGRectMake(rect!.origin.x + delta, rect!.origin.y, rect!.size.width, rect!.size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if (self.imageView == nil) {
            return
        }
        let imgFrame = self.imageView!.frame
        let delta = ImageSize - imgFrame.size.width
        if (delta < 0) {
            self.imageView?.frame = CGRectMake(imgFrame.origin.x, imgFrame.origin.y, ImageSize, imgFrame.size.height)
            self.textLabel?.frame = self.transpose(self.textLabel?.frame, delta: delta)
            self.detailTextLabel?.frame = self.transpose(self.detailTextLabel?.frame, delta: delta)
        }
        self.imageView?.frame = self.transpose(self.imageView?.frame, delta: -3)
    }
}
