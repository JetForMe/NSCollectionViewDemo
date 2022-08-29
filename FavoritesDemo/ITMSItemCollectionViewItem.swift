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
		//	Set up a simple selection indication…
		
		self.view.wantsLayer = true
		self.view.layer?.borderWidth = 0.0
		self.view.layer?.borderColor = CGColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
		
		//	Give us some color until the poster loads…
		
		self.view.layer?.backgroundColor = CGColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.3)
		
		//	Two lines of title…
		
		self.titleLabel.maximumNumberOfLines = 2
		//	Attempt to set the title text shadow, but doesn't seem to do much…
		
		self.titleLabel.cell?.backgroundStyle = .raised
	}
	
	override
	var
	isSelected: Bool
	{
		didSet
		{
			self.view.layer?.borderWidth = self.isSelected ? 10.0 : 0.0
		}
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
