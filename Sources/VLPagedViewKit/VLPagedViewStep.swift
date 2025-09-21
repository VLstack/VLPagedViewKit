/// Represents a single step in a paged view sequence.
/// Provides methods to navigate forward or backward in the sequence.
public protocol VLPagedViewStep
{
 /// Returns the next step in the paged view sequence, or `nil` if none exists.
 /// - Parameter component: Optional component used to determine the next step.
 func pageForward(_ component: (any Equatable)?) -> Self?

 /// Returns the previous step in the paged view sequence, or `nil` if none exists.
 /// - Parameter component: Optional component used to determine the previous step.
 func pageBackward(_ component: (any Equatable)?) -> Self?
}
