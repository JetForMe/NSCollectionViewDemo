A small demonstration app that fetches the top 100 iTunes movies, and lets you drag titles into
a reorderable favorites collection.

## Issues

* It’s unclear why, but the drop location highlighting isn’t working properly.
* The use of Combine, coupled with Apple’s rather clumsy design of `NSCollectionViewDiffableDataSource`,
	results in a redundant update to the data source. This update ends up being a no-op, so I’ve
	left Combine in palce, as it allows for refreshing the Top 100 list.
* The way `NSCollectionView` proposes drop locations makes it challenging for the user to quickly
	place the items where they’re desired (you have to go all the way to the right of an item to
	drop after it, rather than just to the right of the center of the item).
