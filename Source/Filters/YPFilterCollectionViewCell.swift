//
//  YPFilterCollectionViewCell.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import Stevia

class YPFilterCollectionViewCell: UICollectionViewCell {
    
    let name = UILabel()
    let imageView = UIImageView()
    override var isHighlighted: Bool { didSet {
        UIView.animate(withDuration: 0.1) {
            self.contentView.transform = self.isHighlighted
                ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                : CGAffineTransform.identity
        }
        }
    }
    override var isSelected: Bool {
        didSet {
            name.font = .systemFont(
                ofSize: 11,
                weight: isSelected ? .bold : .regular
            )
            imageView.layer.borderWidth = isSelected ? 2 : 0

        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        sv(
            imageView,
            name
        )
        
        |imageView|.top(0).heightEqualsWidth()
        |name|.bottom(0)
        
        name.font = .systemFont(ofSize: 11, weight: UIFont.Weight.regular)
        name.textColor = YPConfig.colors.filterTextColor
        name.textAlignment = .center
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        
        imageView.layer.borderColor = YPConfig.colors.filterTextColor.cgColor
        imageView.layer.borderWidth = 0
            
        self.clipsToBounds = false
        self.layer.shadowColor = UIColor.ypLabel.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 4, height: 7)
        self.layer.shadowRadius = 5
        self.layer.backgroundColor = UIColor.clear.cgColor
    }
}
