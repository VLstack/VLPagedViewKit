/// Represents a single step in a paged view sequence.
/// Provides methods to navigate forward or backward in the sequence.
///
/// The `Comparable` order of the type must follow the order of the pages:
/// `VLPagedView` uses it to choose the direction of the page animation.
public protocol VLPagedViewStep: Comparable
{
 /// Returns the next step in the paged view sequence, or `nil` if none exists.
 func pageForward() -> Self?

 /// Returns the previous step in the paged view sequence, or `nil` if none exists.
 func pageBackward() -> Self?
}
