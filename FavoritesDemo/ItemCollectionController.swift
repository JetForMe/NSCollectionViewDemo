/**
	ItemCollectionController.swift
	FavoritesDemo

	Created by Rick Mann on 2022-08-25.
*/

import Cocoa
import Combine

import Kingfisher
import OrderedCollections


class
ItemCollectionController : NSViewController
{
	public	var		canDrop							=	false
	public	var		canReorder						=	false
	
	func
	loadItems(from inItems: OrderedSet<ITMSItem>)
	{
		var snapshot = NSDiffableDataSourceSnapshot<Int, ITMSItem>()
		snapshot.appendSections([0])
		snapshot.appendItems(inItems.elements)

		self.dataSource.apply(snapshot, animatingDifferences: true)
	}
	
	func
	set(collection inCollection: any Publisher<OrderedSet<ITMSItem>, Never>)
	{
		self.sub =
			inCollection
				.sink
				{ [weak self] inItems in
					guard let self = self else { return }
					
					var snapshot = NSDiffableDataSourceSnapshot<Int, ITMSItem>()
					snapshot.appendSections([0])
					snapshot.appendItems(inItems.elements)

					self.dataSource.apply(snapshot, animatingDifferences: true)
				}
	}
	
	typealias	DropHandler			=	(_ items: OrderedSet<ITMSItem>) -> ()
	
	func
	setDropHandler(_ inDH: @escaping DropHandler)
	{
		self.dropHandler = inDH
		self.collectionView.registerForDraggedTypes([.ITMSItemPBType])
	}
	
	override
	func
	viewDidLoad()
	{
		super.viewDidLoad()
		
		//	Configure the collection view…
		
		self.collectionView.register(ITMSItemCollectionViewItem.self, forItemWithIdentifier: .ITMSItemIdentifier)
		self.collectionView.setDraggingSourceOperationMask([.move], forLocal: true)
		self.collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
		
		//	Configure the data source…
		
		self.dataSource = .init(collectionView: self.collectionView,
								itemProvider:
								{ (inView: NSCollectionView, inPath: IndexPath, inItem: ITMSItem) -> NSCollectionViewItem? in
									let iv = inView.makeItem(withIdentifier: .ITMSItemIdentifier, for: inPath) as! ITMSItemCollectionViewItem
									
									iv.titleLabel.stringValue = inItem.title
									iv.posterView.kf.indicatorType = .activity
									iv.posterView.kf.setImage(with: inItem.posterURL)
									
									return iv
								})
		self.dataSource.supplementaryViewProvider =
		{ (inView: NSCollectionView, inKind: String, inPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
			debugLog("supplementaryViewProvider \(inKind)")
			return nil
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
	
	private var sub							:	AnyCancellable?
	private var dataSource					:	NSCollectionViewDiffableDataSource<Int, ITMSItem>!
	
	private var dropHandler					:	DropHandler?
	
	@IBOutlet weak var collectionView		:	NSCollectionView!
}

//	MARK: - • Drag & Drop -

extension
ItemCollectionController : NSCollectionViewDelegate
{
	func
	collectionView(_ inView: NSCollectionView, pasteboardWriterForItemAt inPath: IndexPath)
		-> NSPasteboardWriting?
	{
		guard
			let item = self.dataSource.itemIdentifier(for: inPath)
		else
		{
			return nil
		}
		
		let pbi = ITMSItemProvider(item: item)
		return pbi
	}
	
	func
	collectionView(_ inView: NSCollectionView,
					validateDrop inInfo: NSDraggingInfo,
					proposedIndexPath inProposedPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
					dropOperation inProposedOp: UnsafeMutablePointer<NSCollectionView.DropOperation>)
		-> NSDragOperation
	{
		guard
			let draggingSource = inInfo.draggingSource as? NSCollectionView,
			(draggingSource != inView && self.canDrop) || (draggingSource == inView && self.canReorder)
		else
		{
			return []
		}
		
		if inProposedOp.pointee == .on
		{
			inProposedOp.pointee = .before
		}
		
		return .move
	}

	func
	collectionView(_ inView: NSCollectionView,
					acceptDrop inInfo: NSDraggingInfo,
					indexPath inPath: IndexPath,
					dropOperation inOp: NSCollectionView.DropOperation)
		-> Bool
	{
		guard
			let draggingSource = inInfo.draggingSource as? NSCollectionView
		else
		{
			return false
		}
		
		//	Build a list of dragged items…
		
		var items = OrderedSet<ITMSItem>()
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
						if let data = pbItem.data(forType: .ITMSItemPBType)
						{
							let item = try ITMSItem(with: data)
							debugLog("\(item)")
							items.append(item)
						}
					}
					catch
					{
						debugLog("failed to unarchive indexPath for dropped photo item.")
					}
				}
			})
		
		//	If it came from our own view, see if we can reorder, and do so…
		
		let toPath = self.dropLocation(from: inPath)
		var snapshot = self.dataSource.snapshot()
		
		if draggingSource == inView
		{
			guard self.canReorder else { return false }
			
			//	Move to the appropriate place…
			
			let dropItem = snapshot.itemIdentifiers[toPath.item]
			if toPath.item == 0												//	Items dropped at beginning
			{
				items.forEach { snapshot.moveItem($0, beforeItem: dropItem) }
			}
			else															//	Items dropped between or at end
			{
				items.forEach { snapshot.moveItem($0, afterItem: dropItem) }
			}
		}
		else
		{
			//	The diffable data source is a bit clunky thanks to not using simple indices
			//	into the collection, so we have to jump through some hoops to figure out
			//	exactly where to drop the items…
			
			if snapshot.numberOfItems(inSection: 0) == 0
			{
				//	We’re empty, so just append…
				
				snapshot.appendItems(items.elements)
			}
			else
			{
				//	Insert at the appropriate place…
				
				let dropItem = snapshot.itemIdentifiers[toPath.item]
				if toPath.item == 0												//	Items dropped at beginning
				{
					snapshot.insertItems(items.elements, beforeItem: dropItem)
				}
				else															//	Items dropped between or at end
				{
					snapshot.insertItems(items.elements, afterItem: dropItem)
				}
			}
		}
		
		self.dataSource.apply(snapshot, animatingDifferences: true)
		
		//	Let the top level controller know what happened…
		
		self.dropHandler?(OrderedSet<ITMSItem>(self.dataSource.snapshot().itemIdentifiers))
		
		return true
	}
	
	/**
		The diffable data source is a bit clunky thanks to not using simple indices
		into the collection, so we have to jump through some hoops to figure out
		exactly where to drop the items.
	*/
	
	func
	dropLocation(from inPath: IndexPath)
		-> IndexPath
	{
		return inPath.item == 0
				? IndexPath(item: inPath.item, section: inPath.section)
				: IndexPath(item: inPath.item - 1, section: inPath.section)
	}
}

//	MARK: - • Drag & Drop Provider -

class
ITMSItemProvider : NSObject, NSPasteboardWriting
{
	init(item inItem: ITMSItem)
	{
		self.item = inItem
	}
	
	func
	writableTypes(for inPB: NSPasteboard)
		-> [NSPasteboard.PasteboardType]
	{
		return [.ITMSItemPBType]
	}
	
	func
	pasteboardPropertyList(forType inType: NSPasteboard.PasteboardType)
		-> Any?
	{
		let data = self.item.encode()
		return data
	}
	
	let item				:	ITMSItem
}
