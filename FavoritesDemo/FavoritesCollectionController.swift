//
//  FavoritesCollectionController.swift
//  FavoritesDemo
//
//  Created by Rick Mann on 2022-09-01.
//

import AppKit





class
FavoritesCollectionController : ItemCollectionController
{
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
