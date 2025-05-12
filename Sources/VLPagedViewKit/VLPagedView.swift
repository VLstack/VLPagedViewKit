import SwiftUI
import UIKit

public struct VLPagedView<S: VLPagedViewStep & Comparable, Content: View>: UIViewControllerRepresentable
{
 public typealias UIViewControllerType = UIPageViewController

 @Binding public var currentIndex: S
 private let content: (S) -> Content
 private let stepComponent: (any Equatable)?
 private let transitionStyle: UIPageViewController.TransitionStyle
 private let navigationOrientation: UIPageViewController.NavigationOrientation
  
 public init(current: Binding<S>,
             stepComponent: (any Equatable)? = nil,
             transition: UIPageViewController.TransitionStyle = .scroll,
             orientation: UIPageViewController.NavigationOrientation = .horizontal,
             @ViewBuilder content: @escaping (S) -> Content)
 {
  self._currentIndex = current
  self.stepComponent = stepComponent
  self.transitionStyle = transition
  self.navigationOrientation = orientation
  self.content = content
 }

 public func makeCoordinator() -> Coordinator
 {
  Coordinator(self)
 }

 public func makeUIViewController(context: Context) -> UIPageViewController
 {
  let pageViewController = UIPageViewController(transitionStyle: transitionStyle,
                                                navigationOrientation: navigationOrientation)
  pageViewController.dataSource = context.coordinator
  pageViewController.delegate = context.coordinator

  let initialViewController = UIHostingController(rootView: VLPagedView.IdentifiedContent(pageIndex: currentIndex,
                                                                                          content: { content(currentIndex) }))
  pageViewController.setViewControllers([ initialViewController ],
                                        direction: .forward,
                                        animated: false,
                                        completion: nil)

  return pageViewController
 }

 public func updateUIViewController(_ uiViewController: UIPageViewController,
                                    context: Context)
 {
  let currentViewController = uiViewController.viewControllers?.first as? UIHostingController<VLPagedView.IdentifiedContent<Content, S>>
  let rootCurrentIndex = currentViewController?.rootView.pageIndex ?? self.currentIndex

  if currentIndex != rootCurrentIndex
  {
   let direction: UIPageViewController.NavigationDirection = currentIndex > rootCurrentIndex ? .forward : .reverse
   let newViewController = UIHostingController(rootView: VLPagedView.IdentifiedContent(pageIndex: currentIndex,
                                                                                       content: { content(currentIndex) }))
   uiViewController.setViewControllers([ newViewController ],
                                       direction: direction,
                                       animated: true,
                                       completion: nil)
  }
 }

 public class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate
 {
  package var parent: VLPagedView

  public init(_ parent: VLPagedView)
  {
   self.parent = parent
  }

  public func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerBefore viewController: UIViewController) -> UIViewController?
  {
   guard let currentView = viewController as? UIHostingController<VLPagedView.IdentifiedContent<Content, S>>,
         let currentIndex = currentView.rootView.pageIndex as S?,
         let previousIndex = currentIndex.pageBackward(parent.stepComponent)
   else { return nil }

   return UIHostingController(rootView: VLPagedView.IdentifiedContent(pageIndex: previousIndex,
                                                                      content: { self.parent.content(previousIndex) }))
  }

  public func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerAfter viewController: UIViewController) -> UIViewController?
  {
   guard let currentView = viewController as? UIHostingController<VLPagedView.IdentifiedContent<Content, S>>,
         let currentIndex = currentView.rootView.pageIndex as S?,
         let nextIndex = currentIndex.pageForward(parent.stepComponent)
   else { return nil }
   
   return UIHostingController(rootView: VLPagedView.IdentifiedContent(pageIndex: nextIndex,
                                                                      content: { self.parent.content(nextIndex) }))
  }

  public func pageViewController(_ pageViewController: UIPageViewController,
                                 didFinishAnimating finished: Bool,
                                 previousViewControllers: [ UIViewController ],
                                 transitionCompleted completed: Bool)
  {
   if completed,
      let currentView = pageViewController.viewControllers?.first as? UIHostingController<VLPagedView.IdentifiedContent<Content, S>>,
      let currentIndex = currentView.rootView.pageIndex as S?
   {
    parent.currentIndex = currentIndex
   }
  }
 }
}
