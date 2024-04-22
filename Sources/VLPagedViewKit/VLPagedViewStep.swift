public protocol VLPagedViewStep
{
 func pageForward(_ component: (any Equatable)?) -> Self?
 func pageBackward(_ component: (any Equatable)?) -> Self?
}
