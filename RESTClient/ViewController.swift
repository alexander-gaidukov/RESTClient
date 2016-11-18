//
//  ViewController.swift
//  RESTClient
//
//  Created by Alexander Gaidukov on 11/18/16.
//  Copyright © 2016 Alexander Gaidukov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var friends: [User] = []
    
    var friendsTask: URLSessionDataTask!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        loadFriends()
    }
    
    private func loadFriends() {
        friendsTask?.cancel() //Cancel previous loading task.
        
        activityIndicator.startAnimating() //Show loading indicator
        
        friendsTask = FriendsService().loadFriends {[weak self] friends, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating() //Stop loading indicators
                if let error = error {
                    print(error.localizedDescription) //Handle service error
                } else if let friends = friends {
                    self?.friends = friends //Update friends property
                    self?.updateUI() //Update user interface
                }
            }
        }
    }
    
    private func updateUI() {
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath)
        let friend = friends[indexPath.row]
        cell.textLabel?.text = friend.name
        cell.detailTextLabel?.text = friend.email
        return cell
    }
}

