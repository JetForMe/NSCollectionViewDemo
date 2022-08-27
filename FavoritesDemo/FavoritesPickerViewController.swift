//
//  FavoritesPickerViewController.swift
//  FavoritesDemo
//
//  Created by Rick Mann on 2022-08-25.
//

import Cocoa
import Combine

class
FavoritesPickerViewController : NSSplitViewController
{

	override
	func
	viewDidLoad()
	{
		super.viewDidLoad()
		
		let available = self.splitViewItems[0].viewController as! ItemCollectionController
		available.set(collection: Store.shared.$availableTitles)
		let favorites = self.splitViewItems[1].viewController as! ItemCollectionController
		favorites.set(collection: Store.shared.$favorites)
		favorites.setDropHandler {
			print("handle the drop")
		}
	}
	
}

