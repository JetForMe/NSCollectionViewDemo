//
//  AppDelegate.swift
//  FavoritesDemo
//
//  Created by Rick Mann on 2022-08-25.
//

import Cocoa

@main
class
AppDelegate: NSObject, NSApplicationDelegate
{
	func
	applicationDidFinishLaunching(_ inNotification: Notification)
	{
		Task
		{
			do
			{
				try await Store.shared.fetchTop100()
			}
			
			catch let e
			{
				print("Error fetching \(e)")
			}
		}
	}

	func
	applicationSupportsSecureRestorableState(_ inApp: NSApplication)
		-> Bool
	{
		return true
	}
}

