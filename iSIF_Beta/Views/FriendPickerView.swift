// FriendPickerView.swift

import UIKit

class FriendPickerView: UIViewController {
    
    enum SelectionMode {
        case single
        case multiple
    }
    
    var selectionMode: SelectionMode = .single
    var selectedFriends: [Friend] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up the view based on selection mode
        setupView() 
    }
    
    func setupView() {
        switch selectionMode {
        case .single:
            // Configure the view for single selection
            break
        case .multiple:
            // Configure the view for multiple selection
            break
        }
    }
    
    // Method to handle friend selection
    func friendSelected(friend: Friend) {
        switch selectionMode {
        case .single:
            selectedFriends = [friend]
        case .multiple:
            if let index = selectedFriends.firstIndex(of: friend) {
                selectedFriends.remove(at: index)
            } else {
                selectedFriends.append(friend)
            }
        }
    }
}