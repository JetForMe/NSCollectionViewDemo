/**
	Store.swift
	FavoritesDemo

	Created by Rick Mann on 2022-08-25.
*/

import AppKit
import Combine
import Foundation

import Marshal
import OrderedCollections
import Path



/**
	Class is responsible for caching downloaded titles, and tracking
	favorites
*/

class
Store
{
		public	static	var			shared					=	Store()
	
	@Published	public	var			availableTitles			=	OrderedSet<ITMSItem>()
	@Published	public	var			favorites				=	OrderedSet<ITMSItem>()
	
	
	public
	init()
	{
		do
		{
			try loadFavorites()
		}
		
		catch let e
		{
			debugLog("Error loading favorites: \(e)")
		}
		
		//	Note: While it’s desirable to do the culling work on the
		//			receive queue, but I’m not sure how risky that
		//			is, given that self.favorites is modified on
		//			the main queue. The amount of actual work here
		//			is so small, that we’ll just do it on the main
		//			queue…
		
		self.allTitles
			.receive(on: DispatchQueue.main)
			.map { $0.subtracting(self.favorites) }		//	Remove any persisted favorites
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
		
		let items = try OrderedSet<ITMSItem>(obj.value(for: "feed.entry", inContext: .itms) as [ITMSItem])
		self.allTitles.send(items)
	}
	
	/**
		Updates the favorites with the new list.
	*/
	
	func
	set(favorites inItems: OrderedSet<ITMSItem>)
	{
		//	Remove from available…
		
		let available = self.availableTitles.subtracting(inItems)
		self.availableTitles = available
		
		//	Update our favorites…
		
		self.favorites = inItems
		
		do
		{
			try persistFavorites()
		}
		
		catch let e
		{
			debugLog("Unable to write favorites: \(e)")
		}
	}
	
	/**
		Writes the current set of favorites to disk, just a simple JSON
		representation.
	*/
	
	func
	persistFavorites()
		throws
	{
		let path = try Path.applicationSupport.join(Bundle.main.bundleIdentifier!).mkdir().join("favorites.json")
		debugLog("Persisting favorites to \(path)")
		
		let faves = self.favorites.elements.map { $0.marshaled() }
		let obj = [ "favorites" : faves ]
		let json = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
		try json.write(to: path, atomically: true)
	}
	
	/**
		Loads favorites previously stored to disk.
	*/
	
	func
	loadFavorites()
		throws
	{
		let path = Path.applicationSupport.join(Bundle.main.bundleIdentifier!).join("favorites.json")
		debugLog("Loading favorites from \(path)")
		
		let data = try Data(contentsOf: path)
		let json = try JSONSerialization.jsonObject(with: data)
		guard
			let obj = json as? [String:Any]
		else
		{
			throw MarshalError.typeMismatch(expected: MarshaledObject.self, actual: type(of: json))
		}
		let items: [ITMSItem] = try obj.value(for: "favorites", inContext: .localStore)
		self.favorites = OrderedSet<ITMSItem>(items)
	}
	
	var			allTitles				=	CurrentValueSubject<OrderedSet<ITMSItem>, Never>(OrderedSet<ITMSItem>())
}

//	MARK: - • ITMSItem -

struct
ITMSItem
{
	let			id					:	String
	var			title				:	String
	var			posterURL			:	URL?
	var			summary				:	String
}

extension
ITMSItem : Hashable
{
    func
    hash(into ioHasher: inout Hasher)
    {
    	self.id.hash(into: &ioHasher)
    }
}

extension
ITMSItem : UnmarshalingWithContext
{
	enum
	Source
	{
		case itms
		case localStore
	}
	
	static
	func
	value(from inObj: Marshal.MarshaledObject, inContext inCTX: Source)
		throws
		-> ITMSItem
	{
		
		let id: String = try inObj.value(for: inCTX == .itms ? "id.attributes.im:id" : "id")
		let title: String = try inObj.value(for: inCTX == .itms ? "im:name.label" : "title")
		let summary: String = try inObj.value(for: inCTX == .itms ? "summary.label" : "summary")
		
		var item = ITMSItem(id: id, title: title, summary: summary)
		
		//	Being so cautious with the downloaded data is probably overkill
		//	for this little example, but here we are, and dealing with
		//	it everywhere…
		
		if inCTX == .itms
		{
			let thumbs: [[String:Any]] = try inObj.value(for: "im:image")
			if let urlS: String = try thumbs.last?.value(for: "label"),
				let url = URL(string: urlS)
			{
				//	Massage the URL to give us a higher-res version than
				//	the one explicitly given…
				
				var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
				var path = comps.path
				path.set(lastPathComponent: "460x0w.png")
				comps.path = path
				
				item.posterURL = comps.url
			}
		}
		else
		{
			if let urlS: String = try inObj.value(for: "posterURL"),
				let url = URL(string: urlS)
			{
				item.posterURL = url
			}
		}
		
		return item
	}
	
//	init(object inObj: Marshal.MarshaledObject)
//		throws
//	{
//		self.id = try inObj.value(for: "id.attributes.im:id")
//		self.title = try inObj.value(for: "im:name.label")
//
//		//	Being so cautious with the downloaded data is probably overkill
//		//	for this little example, but here we are, and dealing with
//		//	it everywhere…
//
//		let thumbs: [[String:Any]] = try inObj.value(for: "im:image")
//		if let urlS: String = try thumbs.last?.value(for: "label"),
//			let url = URL(string: urlS)
//		{
//			//	Massage the URL to give us a higher-res version than
//			//	the one explicitly given…
//
//			var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//			var path = comps.path
//			path.set(lastPathComponent: "460x0w.png")
//			comps.path = path
//
//			self.posterURL = comps.url
//		}
//		self.summary = try inObj.value(for: "summary.label")
//	}
//
}

extension
ITMSItem : Marshaling
{
	func
	marshaled()
		-> [String : Any]
	{
		var d: [String : Any] =
			[
				"id" : self.id,
				"title" : self.title,
				"summary" : self.summary,
			]
		
		if let url = self.posterURL
		{
			d["posterURL"] = url.absoluteString
		}
		
		return d
	}
}

extension
ITMSItem : ValueType
{
}

//	MARK: - • Data Encoding/Decoding -

/**
	This is rather annoying to have to do, but I’m not sure there’s
	a better way in Swift to drag & drop structs.
*/

extension
ITMSItem
{
	func
	encode()
		-> Data
	{
		let archiver = NSKeyedArchiver(requiringSecureCoding: false)
		archiver.encode(self.id, forKey: "id")
		archiver.encode(self.title, forKey: "title")
		archiver.encode(self.summary, forKey: "summary")
		if let url = self.posterURL
		{
			archiver.encode(url.absoluteString, forKey: "posterURL")
		}
		return archiver.encodedData
	}
	
	init(with inData: Data)
		throws
	{
		let archiver = try NSKeyedUnarchiver(forReadingFrom: inData)
		
		//	These should never be anything but valid strings…
		
		self.id = archiver.decodeDecodable(String.self, forKey: "id")!
		self.title = archiver.decodeDecodable(String.self, forKey: "title")!
		self.summary = archiver.decodeDecodable(String.self, forKey: "summary")!
		
		if let url = archiver.decodeDecodable(String.self, forKey: "posterURL")
		{
			self.posterURL = URL(string: url)
		}
	}
}

//	MARK: - • Debugging -

extension
ITMSItem : CustomDebugStringConvertible
{
	var
	debugDescription: String
	{
		return "\(self.id): “\(self.title)”, poster: \(self.posterURL?.absoluteString ?? "nil")"
	}
	
}

//	MARK: - • String Path Helpers -

public
extension
String
{
	func
	lastPathComponent(separator inSep: String = "/")
		-> String?
	{
		let comps = self.components(separatedBy: inSep)
		if let last = comps.last
		{
			return String(last)
		}
		
		return nil
	}
	
	mutating
	func
	set(lastPathComponent inComp: String, separator inSep: String = "/")
	{
		var comps = self.components(separatedBy: inSep)
		if comps.count > 0
		{
			comps[comps.count - 1] = inComp
			self = comps.joined(separator: inSep)
		}
		else
		{
			self = inComp
		}
	}
}


enum
Errors : Error
{
	case decodeFailure
}
