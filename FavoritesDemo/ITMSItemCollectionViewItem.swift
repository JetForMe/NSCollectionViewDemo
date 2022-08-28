//
//  ITMSItemCollectionViewItem.swift
//  FavoritesDemo
//
//  Created by Rick Mann on 2022-08-27.
//

import Cocoa





class
ITMSItemCollectionViewItem : NSCollectionViewItem
{
	override
	func
	viewDidLoad()
	{
		self.titleLabel.maximumNumberOfLines = 2
		self.view.layer?.backgroundColor = CGColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.3)
		self.titleLabel.cell?.backgroundStyle = .raised
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
