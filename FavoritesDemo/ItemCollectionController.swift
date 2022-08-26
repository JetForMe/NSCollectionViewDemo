/**
	ItemCollectionController.swift
	FavoritesDemo

	Created by Rick Mann on 2022-08-25.
*/

import Cocoa
import Combine




class
ItemCollectionController : NSViewController
{
	override
	func
	viewDidLoad()
	{
		super.viewDidLoad()
		
		self.collectionView.register(ITMSItemCollectionViewItem.self, forItemWithIdentifier: .ITMSItemIdentifier)
	}
	
	func
	set(collection inCollection: any Publisher<[ITMSItem], Never>)
	{
		self.sub =
			inCollection
				.sink
				{ [weak self] inItems in
					guard let self = self else { return }

					print("Got \(inItems.count) items")
					self.items = inItems
					self.view.layoutSubtreeIfNeeded()
					self.collectionView.reloadData()
				}
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
	
	
	private var	sub					:	AnyCancellable?
	private	var	items											=	[ITMSItem]()
	
	@IBOutlet weak var collectionView: NSCollectionView!
}



extension
ItemCollectionController : NSCollectionViewDataSource
{
	func
	collectionView(_ inView: NSCollectionView, numberOfItemsInSection inSection: Int)
		-> Int
	{
		return self.items.count
	}
	
	func
	collectionView(_ inView: NSCollectionView, itemForRepresentedObjectAt inPath: IndexPath)
		-> NSCollectionViewItem
	{
		let iv = inView.makeItem(withIdentifier: .ITMSItemIdentifier, for: inPath) as! ITMSItemCollectionViewItem
		
		let item = self.items[inPath.item]
		iv.titleLabel.stringValue = item.title
		return iv
	}
	
}

extension
ItemCollectionController : NSCollectionViewDelegate
{
}

extension
ItemCollectionController : NSCollectionViewDelegateFlowLayout
{
	/**
		Size the items based on the collection view’s height.
		
		TODO: On first presentation, parent size is incorrect.
	*/
	
	func
	collectionView(_ inView: NSCollectionView,
					layout inLayout: NSCollectionViewLayout,
					sizeForItemAt inPath: IndexPath)
		-> NSSize
	{
		let height = inView.bounds.height - 20.0
		let width = height * 9.0 / 16.0
		return NSSize(width: width, height: height)
	}
}




//	MARK: - • Item -

class
ITMSItemCollectionViewItem : NSCollectionViewItem
{
	override
	func
	viewDidLoad()
	{
		self.titleLabel.maximumNumberOfLines = 2
		self.view.layer?.backgroundColor = CGColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.3)
	}
	
	@IBOutlet weak var titleLabel: NSTextField!
	@IBOutlet weak var posterView: NSImageView!
}

extension
NSUserInterfaceItemIdentifier
{
	static let ITMSItemIdentifier			=	NSUserInterfaceItemIdentifier("ITMSItem")
}
