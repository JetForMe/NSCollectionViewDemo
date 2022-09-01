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
		
		//	The following is a bit of a hack, in that we can’t just label the
		//	appropriate relationships in IB and then find them (see ``prepare(for:sender:)``).
		//	So instead we configure the items by index…
		
		let available = self.splitViewItems[1].viewController as! ItemCollectionController
		configure(topItems: available)

		let favorites = self.splitViewItems[0].viewController as! ItemCollectionController
		configure(favorites: favorites)
	}
	
	/**
		This method should work to configure the child view controllers, but doesn’t,
		for some inexplicable reason. So we do the hacky thing in ``viewDidLoad``.
	*/
	
	override
	func
	prepare(for inSegue: NSStoryboardSegue, sender: Any?)
	{
		//	Configure our child view controllers…
		
		if inSegue.identifier == .favorites
		{
			let favorites = inSegue.destinationController as! ItemCollectionController
			configure(favorites: favorites)
		}
		else if inSegue.identifier == .topItems
		{
			let available = inSegue.destinationController as! ItemCollectionController
			configure(topItems: available)
		}
	}
	
	func
	configure(favorites inVC: ItemCollectionController)
	{
		inVC.canDrop = true
		inVC.canReorder = true
		inVC.loadItems(from: Store.shared.favorites)
		inVC.setDropHandler
		{ inItems in
			Store.shared.set(favorites: inItems)
		}
	}
	
	func
	configure(topItems inVC: ItemCollectionController)
	{
		inVC.set(collection: Store.shared.$availableTitles)
	}
}

extension
NSStoryboardSegue.Identifier
{
	static	let	favorites				=	"favorites"
	static	let	topItems				=	"topItems"
}
