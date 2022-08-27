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
		self.collectionView.setDraggingSourceOperationMask([.move], forLocal: true)
		self.collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
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
	
	typealias	DropHandler			=	() -> ()
	
	func
	setDropHandler(_ inDH: @escaping DropHandler)
	{
		self.dropHandler = inDH
		self.collectionView.registerForDraggedTypes([.ITMSItemPBType])
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
	
	/**
		Starts loading additional items (e.g. movie posters) for
		the currently-visible items in the collection view.
	*/
	
	func
	loadVisibleItems()
	{
		let paths = self.collectionView.indexPathsForVisibleItems()
		paths.forEach
		{ inPath in
			
		}
	}
	
	private var	sub					:	AnyCancellable?
	private	var	items											=	[ITMSItem]()
	
	private	var	dropHandler			:	DropHandler?
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
	func
	collectionView(_ inView: NSCollectionView, pasteboardWriterForItemAt inPath: IndexPath)
		-> NSPasteboardWriting?
	{
		let item = self.items[inPath.item]
		
		print("pasteboardWriterForItemAt")
		
		let pbi = NSPasteboardItem()
		pbi.setString(item.id, forType: .ITMSItemPBType)
		pbi.setPropertyList(inPath.item, forType: .ITMSSourceIndexPBType)
		let v = pbi.pasteboardPropertyList(forType: .ITMSSourceIndexPBType)
		print("V: \(String(describing: v))")
		return pbi
	}
	
    func collectionView(_ collectionView: NSCollectionView,
                        validateDrop draggingInfo: NSDraggingInfo,
                        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
                        dropOperation inProposedOp: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation
	{
		print("validateDrop, proposed op: \(inProposedOp.pointee.rawValue)")
		return NSDragOperation.copy
	}

    func
    collectionView(_ inView: NSCollectionView,
                        acceptDrop inInfo: NSDraggingInfo,
                        indexPath inPath: IndexPath,
                        dropOperation inOp: NSCollectionView.DropOperation) -> Bool
	{
		print("handle drop: \(inOp) at \(inPath)")
        // Check where the dragged items are coming from.
        if let draggingSource = inInfo.draggingSource as? NSCollectionView,
        	draggingSource != inView
		{
            // Drag source from your own collection view.
            // Move each dragged photo item to their new place.
//            dropInternalPhotos(collectionView, inInfo: inInfo, indexPath: indexPath)
			inInfo.enumerateDraggingItems(
				options: NSDraggingItemEnumerationOptions.concurrent,
				for: inView,
				classes: [NSPasteboardItem.self],
				searchOptions: [:],
				using:
				{ (inItem, inIdx, outStop) in
					if let pbItem = inItem.item as? NSPasteboardItem
					{
						do
						{
							if let data = pbItem.data(forType: .ITMSItemPBType)//,
//								let photoIndexPath = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(indexPathData) as? IndexPath
							{
								print("\(data)")
//								if let photoItem = self.dataSource.itemIdentifier(for: photoIndexPath)
//								{
//									// Find out the proper indexPath drop point.
//									let toIndexPath = self.dropLocation(indexPath: indexPath)
//
//									let dropItemLocation = snapshot.itemIdentifiers[toIndexPath.item]
//									if toIndexPath.item == 0 {
//										// Item is being dropped at the beginning.
//										snapshot.moveItem(photoItem, beforeItem: dropItemLocation)
//									} else {
//										// Item is being dropped between items or at the very end.
//										snapshot.moveItem(photoItem, afterItem: dropItemLocation)
//									}
//								}
							}
						} catch {
							Swift.debugPrint("failed to unarchive indexPath for dropped photo item.")
						}
					}
				})
			self.dropHandler?()
	        return true
        } else {
            return false
        }
    }
}

extension
ItemCollectionController : NSCollectionViewDelegateFlowLayout
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


extension
NSPasteboard.PasteboardType
{
	static let	ITMSItemPBType = NSPasteboard.PasteboardType("com.latencyzero.ITMSItemPBType")
	static let	ITMSSourceIndexPBType = NSPasteboard.PasteboardType("com.latencyzero.ITMSSourceIndexPBType")
}
