//
//  AboutViewController.swift
//  OfflineMovies
//
//  Created by Douwe Osinga on 9/13/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var introText: UILabel!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var textAcknowledgements: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        while true {
            self.introText.frame = CGRectMake(self.introText.frame.origin.x,
                                              self.introText.frame.origin.y,
                                              self.view.bounds.width - self.logoView.bounds.size.width - 40,
                                              0)
            self.introText.sizeToFit()
            self.introText.setNeedsDisplay()
            if self.introText.frame.size.height < self.logoView.frame.size.height {
                break
            }
            self.introText.font = self.introText.font.fontWithSize(self.introText.font.pointSize - 1.0)
        }
        
        let urls = [["Wikipedia", "https://www.wikipedia.org"],
                    ["SQLite.swift", "https://github.com/stephencelis/SQLite.swift"],
                    ["my Github page", "https://github.com/DOsinga/offline_movies"],
                    ["SDWebImage", "https://github.com/rs/SDWebImage"],
                    ["WebP", "https://developers.google.com/speed/webp/"],
                    ["wiki_import", "https://github.com/DOsinga/wiki_import"]]
        
        let str = self.textAcknowledgements.attributedText!.string as NSString
        let attributedText = NSMutableAttributedString(string: self.textAcknowledgements.attributedText!.string)
        for pair in urls {
            let range = str.rangeOfString(pair[0])
            if range.location != NSNotFound  {
                attributedText.addAttribute(NSLinkAttributeName, value: pair[1], range: range)
            }
        }
        self.textAcknowledgements.linkTextAttributes = [NSForegroundColorAttributeName : UIColor.blueColor(), NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleNone.rawValue]

        self.textAcknowledgements.attributedText = attributedText
        self.textAcknowledgements.font = self.introText.font
        self.textAcknowledgements.frame = CGRectMake(self.textAcknowledgements.frame.origin.x,
                                                self.textAcknowledgements.frame.origin.y,
                                                self.view.bounds.width - 20,
                                                0)
        self.textAcknowledgements.sizeToFit()
        self.textAcknowledgements.setNeedsDisplay()
    }
    
}
