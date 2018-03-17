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

  var topAttendance: [(name: String, count: Int64)] = []
  var extraAttendance: [(name: String, count: Int64)] = []

  fileprivate let topSectionInsets = UIEdgeInsets.zero
  fileprivate let extraSectionInsets = UIEdgeInsets(
    top: 12.0,
    left: 12.0,
    bottom: 12.0,
    right: 12.0)

  fileprivate lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(
      frame: CGRect.zero,
      collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.backgroundColor = UIColor(
      red: 56.0/255.0,
      green: 60.0/255.0,
      blue: 76.0/255.0,
      alpha: 1.0)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.register(
      LeaderboardCell.self,
      forCellWithReuseIdentifier: ViewController.leaderboardIdentifier)
    return collectionView
  }()

  fileprivate let dataSource: DataSource = DataSource()

  fileprivate func handleResults(_ results: [(name: String, count: Int64)]) {
    let toTopFive = min(results.count, 5)
    self.topAttendance = Array(results[..<toTopFive])
    self.extraAttendance = results.count > 5 ? Array(results[5...]) : []
    DispatchQueue.main.async {
      self.collectionView.reloadData()
    }
  }

  fileprivate func update() {
    dataSource.update() { (results) in
      self.handleResults(results)
      self.update()
    }
  }

  fileprivate func initialUpdate() {
    dataSource.update() { (results) in
      self.handleResults(results)
      self.dataSource.save()
      self.update()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(collectionView)
    collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    initialUpdate()
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
    guard section == 0 else {
      return extraAttendance.count
    }
    // TODO: Show an empty state, when topAttendance.count == 0
    return topAttendance.count
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
    case 0:
      cell.color = LeaderboardColors.color(for: indexPath.row)
      cell.clientName.text = topAttendance[indexPath.row].name
      cell.attendanceLabel.text = "\(topAttendance[indexPath.row].count)"
    default:
      cell.color = LeaderboardColors.extraPlace
      cell.clientName.text = extraAttendance[indexPath.row].name
      cell.attendanceLabel.text = "\(extraAttendance[indexPath.row].count)"
    }
    cell.isCompactLayout = indexPath.section == 1
    var rank = indexPath.row + 1
    if indexPath.section == 1 {
      rank += 5
    }
    cell.rankCircle.label.text = "\(rank)"
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
    var insets = topSectionInsets
    if indexPath.section == 1 {
      itemsPerRow = 3
      insets = extraSectionInsets
    }
    let paddingSpace = insets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = floor(availableWidth / itemsPerRow)
    return CGSize(width: widthPerItem, height: LeaderboardCell.cellHeight)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int) -> UIEdgeInsets
  {
    guard section == 0 else {
      return extraSectionInsets
    }
    return topSectionInsets
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int) -> CGFloat
  {
    guard section == 0 else {
      return extraSectionInsets.left
    }
    return topSectionInsets.left
  }
}

