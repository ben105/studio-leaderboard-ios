//
//  ViewController.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/23/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  fileprivate static let leaderboardIdentifier: String = "kLeaderboardIdentifier"

  fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

  fileprivate lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(
      frame: CGRect.zero,
      collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.register(
      LeaderboardCell.self,
      forCellWithReuseIdentifier: ViewController.leaderboardIdentifier)
    return collectionView
  }()

  fileprivate let dataSource: DataSource = DataSource()

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource.update()

    view.addSubview(collectionView)
    collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

extension ViewController: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int) -> Int
  {
    return 5
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ViewController.leaderboardIdentifier,
      for: indexPath) as? LeaderboardCell else
    {
        fatalError("failed trying to dequeue a reusable cell")
    }
    switch indexPath.section {
    case 0: cell.color = LeaderboardColors.color(for: indexPath.row)
    default: cell.color = LeaderboardColors.extraPlace
    }
    cell.rankCircle.label.text = "\(indexPath.row + 1)"
    return cell
  }
}

extension ViewController : UICollectionViewDelegateFlowLayout {

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath) -> CGSize
  {
    var itemsPerRow: CGFloat = 1
    if indexPath.section == 1 {
      itemsPerRow = 3
    }
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    return CGSize(width: widthPerItem, height: LeaderboardCell.cellHeight)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int) -> UIEdgeInsets
  {
    return sectionInsets
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int) -> CGFloat
  {
    return sectionInsets.left
  }
}

