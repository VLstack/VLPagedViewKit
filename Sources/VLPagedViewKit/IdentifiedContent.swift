import SwiftUI

public extension VLPagedView
{
 package struct IdentifiedContent<PagedContent: View, SteppableType: VLPagedViewStep>: View
 {
  let pageIndex: SteppableType
  let content: PagedContent

  init(pageIndex: SteppableType,
       @ViewBuilder content: @escaping () -> PagedContent)
  {
   self.pageIndex = pageIndex
   self.content = content()
  }

  var body: some View
  {
   content
  }
 }
}
