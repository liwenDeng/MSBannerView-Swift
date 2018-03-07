//
//  BannerView.swift
//  BannerView
//
//  Created by dengliwen on 2018/3/7.
//  Copyright © 2018年 dsjk. All rights reserved.
//

import UIKit

public class BannerView: UIView {

    private let cellIdentifier = "cellIdentifier"
    private var collectionView: UICollectionView!
    private var flowLayout = UICollectionViewFlowLayout()
    private var realImageCount = 0          //实际数量
    private var originImages: [Any] = []    //传入的图片数组
    private var showingImages: [Any] = []   //显示的图片数组
    private var pageCount = 1               //分页数量
    private var perPageCount: Int = 1       //每页显示图片数
    private var cellClass: AnyClass
    private var timer: Timer?
    
    public var autoScroll: Bool = false {
        didSet {
            if autoScroll {
                startAutoScroll()
            }
        }
    }
    public var interval = 2.5               //滑动间隔
    public var scrollByItem = false  {      //每次滑动一个item
        didSet {
            collectionView.isPagingEnabled = !scrollByItem
        }
    }
    
    public var configCellBlock: ((_ cell: UICollectionViewCell, _ index: Int) -> ())?
    public var clickedCellBlock: ((_ index: Int) -> ())?
    
    deinit {
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }
    
    public init(frame: CGRect, cellClass: AnyClass) {
        self.cellClass = cellClass
        super.init(frame: frame)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white
        collectionView.isPagingEnabled = true
        collectionView.register(cellClass, forCellWithReuseIdentifier: cellIdentifier)
        addSubview(collectionView)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 本地图片
    ///
    /// - Parameters:
    ///   - images: 图片数组
    ///   - perPageCount: 每页显示图片数
    public func setImages(_ images: [Any], perPageCount: Int = 1) {
        self.perPageCount = perPageCount
        self.originImages = images
        self.realImageCount = images.count
        
        configFlowLayout()
        configCollectionView()
        loadShowingImages()
        collectionView.reloadData()
    }

    private func configFlowLayout() {
        setNeedsLayout()
        layoutIfNeeded()
        let width = frame.width / CGFloat(perPageCount)
        let height = frame.height
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
    }
    
    private func configCollectionView() {
        collectionView.collectionViewLayout = flowLayout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.frame = bounds
    }
    
    /// 计算需要显示的图片数量
    private func loadShowingImages() {
        guard originImages.count > 0 else {
            return
        }
        if perPageCount == 1 {
            showingImages = originImages
            showingImages.append(originImages.first!)
            showingImages.insert(originImages.last!, at: 0)
            pageCount = showingImages.count / perPageCount
            return
        }
        
        if originImages.count % perPageCount == 0 {
            // 如果能除尽，则传入的个数为一个循环，再补上头和尾
            showingImages = originImages
            showingImages.insert(contentsOf: originImages.suffix(from: originImages.count - perPageCount), at: 0)
            showingImages.append(contentsOf: originImages.prefix(perPageCount))
            pageCount = showingImages.count / perPageCount
            
        } else {
            // 如果除不尽，则，每 originImages.count * perPageCount 为一组循环，再加上头和尾
            for _ in 0..<perPageCount {
                showingImages.append(contentsOf: originImages)
            }
            showingImages.insert(contentsOf: originImages.suffix(from: originImages.count - perPageCount), at: 0)
            showingImages.append(contentsOf: originImages.prefix(perPageCount))
            pageCount = showingImages.count / perPageCount
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension BannerView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showingImages.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let configBlock = configCellBlock {
            var index = (indexPath.row - perPageCount) % realImageCount
            if index < 0 {
                index = realImageCount - perPageCount + indexPath.row
            }
            configBlock(cell, index)
        }
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let clickBlock = clickedCellBlock {
            var index = (indexPath.row - perPageCount) % realImageCount
            if index < 0 {
                index = realImageCount - perPageCount + indexPath.row
            }
            clickBlock(index)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension BannerView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        switch x {
        case 0:
            scrollToLastPage()
        case CGFloat(pageCount - 1) * collectionView.frame.width:
            scrollToFirstPage()
        default:
            break
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScroll {
            stopAutoScroll()
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScroll {
            startAutoScroll()
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if autoScroll {
            stopAutoScroll()
        }
        if scrollByItem {
            let targetOffset = nearestTargetOffsetForOffset(targetContentOffset.pointee)
            targetContentOffset.pointee.x = targetOffset.x
            targetContentOffset.pointee.y = targetOffset.y
        }
    }
}


// MARK: - Util
extension BannerView {
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        timer = Timer(timeInterval: self.interval, target: self, selector: #selector(scrollToNextGroupOrItem), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    @objc private func scrollToNextGroupOrItem() {
        // 如果在播放时点击了图片，可能会使分割出现偏差 需要修正当前x
        let currentIndex = collectionView.contentOffset.x / flowLayout.itemSize.width
        let amendX = currentIndex * flowLayout.itemSize.width
        if scrollByItem {
            let targetX = amendX + flowLayout.itemSize.width
            stopAutoScroll()
            collectionView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
            startAutoScroll()
        } else {
            let targetX = amendX + collectionView.frame.width
            stopAutoScroll()
            collectionView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
            startAutoScroll()
        }
    }
    
    // 参考 http://www.cocoachina.com/ios/20141216/10645.html 模仿分页功能 可以连续滑动
    private func nearestTargetOffsetForOffset(_ offset: CGPoint) -> CGPoint {
        let pageSize = collectionView.frame.width / CGFloat(perPageCount)
        let page = roundf(Float(offset.x / pageSize))
        let targetX = pageSize * CGFloat(page)
        return CGPoint(x: targetX, y: offset.y)
    }
    
    private func scrollToLastPage() {
        let x = CGFloat(pageCount - 2) * collectionView.frame.width
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    private func scrollToFirstPage() {
        let x = collectionView.frame.width
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    override public func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: window)
        if newWindow != nil {
            startAutoScroll()
        } else {
            stopAutoScroll()
        }
    }
}
