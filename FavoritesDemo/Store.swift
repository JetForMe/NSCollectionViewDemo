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
		self.allTitles.send(items)
	}
	
	/**
		Adds the specified items to the favorites, culling duplicates
		and returning the items added.
	*/
	
	func
	add(favorites inItems: [ITMSItem])
		-> [ITMSItem]
	{
		var subset = inItems.filter { !self.favorites.contains($0) }
		
		//	Remove from available…
		
		var available = self.availableTitles
		subset.forEach
		{ inFave in
			available.removeAll { $0.id == inFave.id }
		}
		self.availableTitles = available
		
		//	Update our favorites…
		
		var faves = self.favorites
		faves.append(contentsOf: subset)		//	TODO: at a specific location
		self.favorites = faves
		
		return subset
	}
	
	
	var			allTitles				=	CurrentValueSubject<[ITMSItem], Never>([ITMSItem]())
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
ITMSItem : Unmarshaling
{
	init(object inObj: Marshal.MarshaledObject)
		throws
	{
		self.id = try inObj.value(for: "id.attributes.im:id")
		self.title = try inObj.value(for: "im:name.label")
		
		//	Being so cautious with the downloaded data is probably overkill
		//	for this little example, but here we are, and dealing with
		//	it everywhere…
		
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
			
			self.posterURL = comps.url
		}
		self.summary = try inObj.value(for: "summary.label")
	}
	
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
		return "\(self.id): “\(self.title)”, poster: \(self.posterURL?.absoluteString)"
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
