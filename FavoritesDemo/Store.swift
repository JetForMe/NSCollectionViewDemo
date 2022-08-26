/**
	Store.swift
	FavoritesDemo

	Created by Rick Mann on 2022-08-25.
*/

import AppKit
import Combine
import Foundation

import Marshal


/**
	Class is responsible for caching downloaded titles, and tracking
	favorites
*/

class
Store
{
		public	static	var			shared					=	Store()
	
	@Published	public	var			availableTitles			=	[ITMSItem]()
	@Published	public	var			favorites				=	[ITMSItem]()
	
	
	public
	init()
	{
		self.allTitles
			.receive(on: DispatchQueue.main)
			.assign(to: &self.$availableTitles)
	}
	
	public
	func
	fetchTop100()
		async
		throws
	{
		let session = URLSession.shared
		
		let url = URL(string: "https://itunes.apple.com/us/rss/topmovies/limit=100/json")!
		let (data, _) = try await session.data(from: url)
		let json = try JSONSerialization.jsonObject(with: data)
		guard
			let obj = json as? [String:Any]
		else
		{
			throw MarshalError.typeMismatch(expected: MarshaledObject.self, actual: type(of: json))
		}
		let items: [ITMSItem] = try obj.value(for: "feed.entry")
		print("Fetched \(items.count) items")
//		items.forEach
//		{ inItem in
//			print("\(inItem.title)")
//		}
		self.allTitles.send(items)
	}
	
	
	
	var			allTitles				=	CurrentValueSubject<[ITMSItem], Never>([ITMSItem]())
}



struct
ITMSItem
{
	let			id					:	String
	var			title				:	String
	var			thumbURL			:	URL?
	var			thumb				:	NSImage?
	var			summary				:	String
}


extension
ITMSItem : Unmarshaling
{
	init(object inObj: Marshal.MarshaledObject)
		throws
	{
		self.id = try inObj.value(for: "id.attributes.im:id")
		self.title = try inObj.value(for: "title.label")
		let thumbs: [[String:Any]] = try inObj.value(for: "im:image")
		if let urlS: String = try thumbs.last?.value(for: "label"),
			let url = URL(string: urlS)
		{
			self.thumbURL = url
		}
		self.summary = try inObj.value(for: "summary.label")
	}
	
}
