import SwiftUI

extension VLPagedView
{
 /// Wrapper view associant un contenu SwiftUI à un index de page.
 ///
 /// Used internally by `VLPagedView` to uniquely identify each page and provide
 /// the corresponding SwiftUI content.
 package struct IdentifiedContent<PagedContent: View, SteppableType: VLPagedViewStep>: View
 {
  /// The step/index associated with this page.
  ///
  /// Used internally to determine the current page and perform navigation.
  package let pageIndex: SteppableType

  /// Closure that generates the SwiftUI content for this page.
  ///
  /// Executed when the page is rendered in the UI.
  package let content: () -> PagedContent

  /// Initializes a new `IdentifiedContent` instance.
  ///
  /// - Parameters:
  ///   - pageIndex: The step/index associated with the page.
  ///   - content: A closure returning the SwiftUI content of the page.
  package init(pageIndex: SteppableType,
               @ViewBuilder content: @escaping () -> PagedContent)
  {
   self.pageIndex = pageIndex
   self.content = content
  }

  package var body: some View
  {
   content()
  }
 }
}
