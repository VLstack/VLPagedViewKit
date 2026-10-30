import SwiftUI

extension VLPagedView
{
 /// A wrapper view that associates SwiftUI content with a page index.
 ///
 /// Used internally by `VLPagedView` to uniquely identify each page and provide
 /// the corresponding SwiftUI content.
 package struct IdentifiedContent: View
 {
  /// The step/index associated with this page.
  ///
  /// Used internally to determine the current page and perform navigation.
  package let pageIndex: S

  /// The SwiftUI content of this page.
  package let content: Content

  /// Initializes a new `IdentifiedContent` instance.
  ///
  /// - Parameters:
  ///   - pageIndex: The step/index associated with the page.
  ///   - content: The SwiftUI content of the page.
  package init(pageIndex: S,
               content: Content)
  {
   self.pageIndex = pageIndex
   self.content = content
  }

  package var body: some View
  {
   content
  }
 }
}
