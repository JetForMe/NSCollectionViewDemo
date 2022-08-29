//
//  AppDelegate.swift
//  FavoritesDemo
//
//  Created by Rick Mann on 2022-08-25.
//

import os.log

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
				debugLog("Error fetching \(e)")
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



public
func
debugLog(_ inFormat: String, file inFile : String = #file, line inLine : Int = #line, _ inArgs: CVarArg...)
{
	let s = String(format: inFormat, arguments: inArgs)
	
	let file = (inFile as NSString).lastPathComponent
	let ss = "\(file):\(inLine)    \(s)"
	os_log("%{public}@", ss)
}
