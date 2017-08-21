//
//  GSInterestCell.swift
//  Chming_iOS
//
//  Created by HwangGisu on 2017. 8. 15..
//  Copyright © 2017년 leejaesung. All rights reserved.
//

import UIKit

class GSInterestCell: UICollectionViewCell {
    @IBOutlet weak var interestNameLabel: UILabel!
    
    override func awakeFromNib() {
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.layer.bounds.size.height/2
    }
    override var isSelected: Bool{
        didSet{
            if isSelected{
                self.backgroundColor = .black
                self.interestNameLabel.textColor = .white
            }else{
                self.backgroundColor = .white
                self.interestNameLabel.textColor = .black
            }
        }
    }
}
