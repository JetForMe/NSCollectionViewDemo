A small demonstration app that fetches the top 100 iTunes movies, and lets you drag titles into
a reorderable favorites collection.

## Issues

* At the moment, there is no way to delete a favorite. Two obvious methods would be to select and press
	Delete (or Command-Delete), and to simply drag out fo the collection view; it’s not clear
	to me how to implement the latter.
* It’s unclear why, but the drop location highlighting isn’t working properly.
* The use of Combine, coupled with Apple’s rather clumsy design of `NSCollectionViewDiffableDataSource`,
	results in a redundant update to the data source. This update ends up being a no-op, so I’ve
	left Combine in palce, as it allows for refreshing the Top 100 list.
* The way `NSCollectionView` proposes drop locations makes it challenging for the user to quickly
	place the items where they’re desired.
