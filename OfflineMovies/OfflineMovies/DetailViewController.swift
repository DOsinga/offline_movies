//
//  DetailViewController.swift
//  OfflineMovies
//
//  Created by Douwe Osinga on 9/8/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    var mainImage: UIImageView?
    var details: UILabel?
    var reception: UILabel?

    var detailItem: Movie? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        if self.detailItem != nil {
            self.navigationItem.title = self.detailItem!.title;
        }
    }

    override func viewDidLoad() {
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.automaticallyAdjustsScrollViewInsets = false

        super.viewDidLoad()
        self.configureView()
        
        if self.detailItem?.image != nil {
            self.mainImage = UIImageView()
            self.mainImage!.image = self.detailItem?.image
            self.scrollView.addSubview(self.mainImage!)
        }
        self.details = UILabel()
        self.details?.numberOfLines = 0
        self.details?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        self.scrollView.addSubview(self.details!)

        self.reception = UILabel()
        self.reception!.numberOfLines = 0
        self.reception!.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.scrollView.addSubview(self.reception!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        if self.detailItem != nil {
            let frameWidth = self.scrollView.bounds.size.width
            let halfFrameWidth = frameWidth / 2
            var receptionY = CGFloat(0)
            if self.detailItem?.image != nil {
                let image = self.detailItem!.image!
                self.mainImage!.image = image
                let imageHeight = image.size.height * (halfFrameWidth / image.size.width)
                self.mainImage!.frame = CGRectMake(-10, 10, halfFrameWidth, imageHeight)
                receptionY = self.mainImage!.bounds.size.height
            }
            
            let res = NSMutableAttributedString()
            let items : [[String?]] = [["Starring", self.detailItem!.starring],
                                       ["Director", self.detailItem!.director],
                                       ["Written by", self.detailItem!.writtenBy],
                                       ["Running time", self.detailItem!.runningTime],
                                       ["Release date", self.detailItem!.releaseDate],
                                       ["Language", self.detailItem!.language]
            ]
            
            let font = UIFont.systemFontOfSize(16)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = font.lineHeight * 0.5
            for pair in items {
                if pair[1] != nil && pair[1] != "" {
                    res.appendAttributedString(NSAttributedString(string: pair[0]! + ":\n", attributes:[NSFontAttributeName : UIFont.boldSystemFontOfSize(16)]))
                    res.appendAttributedString(NSAttributedString(string: pair[1]! + "\n",
                        attributes:[NSFontAttributeName : UIFont.systemFontOfSize(16),
                            NSParagraphStyleAttributeName : paragraphStyle]))
                }
            }
            
            self.details!.attributedText = res
            
            self.details!.preferredMaxLayoutWidth = halfFrameWidth
            self.details!.frame = CGRectMake(halfFrameWidth + 10, 5, halfFrameWidth, 0)
            self.details!.sizeToFit()
            self.details!.setNeedsDisplay()
            receptionY = max(receptionY, self.details!.bounds.size.height) + 10
            
            self.reception!.attributedText = NSAttributedString(string: self.detailItem!.reception! + "\n\n",
                                                                attributes:[NSFontAttributeName : UIFont.systemFontOfSize(16),
                                                                    NSParagraphStyleAttributeName : paragraphStyle])
            self.reception!.preferredMaxLayoutWidth = frameWidth
            self.reception!.frame = CGRectMake(0, receptionY, frameWidth, 0)
            self.reception!.sizeToFit()
            self.reception!.setNeedsDisplay()
            
            self.scrollView.contentSize = CGSizeMake(frameWidth, self.reception!.bounds.size.height + receptionY)
            
        }
        super.viewDidLayoutSubviews()
    }
}

