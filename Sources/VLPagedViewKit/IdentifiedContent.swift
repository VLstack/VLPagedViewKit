import SwiftUI

extension VLPagedView
{
 package struct IdentifiedContent<PagedContent: View, SteppableType: VLPagedViewStep>: View
 {
  package let pageIndex: SteppableType
  package let content: () -> PagedContent

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
