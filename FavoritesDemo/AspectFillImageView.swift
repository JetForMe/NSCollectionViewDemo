/**
	AspectFillImageView.swift
	FavoritesDemo

	Created by Rick Mann on 2022-08-27.
*/


import Cocoa

/**
	This ridiculous class is needed because Cocoa is so far
	behind UIKit. It has no built-in "aspect fill" mode for
	images. This gives us that.
*/

class
AspectFillImageView : NSImageView
{

	override
	var
	image: NSImage?
	{
		set(inNewValue)
		{
			self.layer = CALayer()
			self.layer?.contentsGravity = .resizeAspectFill
			self.layer?.contents = inNewValue
			self.wantsLayer = true

			super.image = inNewValue
		}

		get
		{
			return super.image
		}
	}
}
