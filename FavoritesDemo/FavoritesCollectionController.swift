//
//  FavoritesCollectionController.swift
//  FavoritesDemo
//
//  Created by Rick Mann on 2022-09-01.
//

import AppKit


import OrderedCollections



class
FavoritesCollectionController : ItemCollectionController
{
	override
	func
	viewDidLoad()
	{
		super.viewDidLoad()
		self.collectionView.registerForDraggedTypes([.ITMSItemPBType])
		self.view.needsLayout = true
	}
	
	/**
		In order to dynamically resize the item cells, the layout must be
		invalidated whenever the parent layout changes.
		
		TODO: The first time the window presents,
	*/
	
	override
	func
	viewWillLayout()
	{
		super.viewWillLayout()
		self.collectionView.collectionViewLayout?.invalidateLayout()
	}
	
	override
	func
	update(items inItems: OrderedSet<ITMSItem>)
	{
		Store.shared.set(favorites: inItems)
	}
	
	@IBAction
	func
	delete(_ inSender: Any)
	{
		var snapshot = self.dataSource.snapshot()
		let selected = self.collectionView.selectionIndexPaths.compactMap { self.dataSource.itemIdentifier(for: $0) }
		snapshot.deleteItems(selected)
		self.dataSource.apply(snapshot, animatingDifferences: true)
		update(items: OrderedSet<ITMSItem>(self.dataSource.snapshot().itemIdentifiers))
	}
}


//	MARK: - • Layout -

extension
FavoritesCollectionController : NSCollectionViewDelegateFlowLayout
{
	/**
		Size the items based on the collection view’s height.
		
		TODO: On first presentation, parent size is incorrect. Also get
				an occasional "the item height must be less than the height of
				the UICollectionView minus the section insets top and bottom
				values, minus the content insets top and bottom values" complaint.
	*/
	
	func
	collectionView(_ inView: NSCollectionView,
					layout inLayout: NSCollectionViewLayout,
					sizeForItemAt inPath: IndexPath)
		-> NSSize
	{
		let height = inView.bounds.height - 20.0
		let width = height / 1.5
		return NSSize(width: width, height: height)
	}
}
