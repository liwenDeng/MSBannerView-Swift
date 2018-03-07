//
//  TestViewController.swift
//  MSBannerView_Example
//
//  Created by dengliwen on 2018/3/7.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import MSBannerView

class TestCell: UICollectionViewCell {
    var imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        imageView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TestViewController: UIViewController {

    var baner: BannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        baner = BannerView(frame: CGRect(x: 0, y: 90, width: view.bounds.width, height: 88), cellClass: TestCell.self)
        view.addSubview(baner)
        let images: [UIImage] = [#imageLiteral(resourceName: "1"), #imageLiteral(resourceName: "2"), #imageLiteral(resourceName: "3"), #imageLiteral(resourceName: "4")]
        baner.scrollByItem = true
        baner.autoScroll = true
        baner.setImages(images,perPageCount: 2)
        baner.configCellBlock = {(cell, index) in
            (cell as! TestCell).imageView.image = images[index]
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
