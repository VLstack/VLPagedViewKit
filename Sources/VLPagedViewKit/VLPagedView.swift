import SwiftUI
import UIKit

/// A SwiftUI wrapper around `UIPageViewController` that allows paginated navigation between views.
///
/// This view works with a step type `S` conforming to `VLPagedViewStep` and `Comparable`.
/// It provides a SwiftUI-friendly interface while using `UIPageViewController` under the hood.
/// - Parameters:
///   - S: The step type representing each page, must conform to `VLPagedViewStep` & `Comparable`.
///   - Content: The SwiftUI view displayed for each step.
public struct VLPagedView<S: VLPagedViewStep & Comparable, Content: View>: UIViewControllerRepresentable
{
 public typealias UIViewControllerType = UIPageViewController

 /// The currently displayed step in the paged view.
 ///
 /// Binding allows two-way synchronization: updating this value changes the page,
 /// and swiping pages updates this value.
 @Binding public var currentIndex: S

 /// Closure that returns the SwiftUI view for a given step.
 ///
 /// - Parameter S: The step for which the content is requested.
 /// - Returns: A SwiftUI `View` to display for the given step.
 private let content: (S) -> Content

 /// Optional component used to compute the next or previous page in the sequence.
 ///
 /// This is passed to the `pageForward` and `pageBackward` methods of `VLPagedViewStep`.
 private let stepComponent: (any Equatable)?

 /// The transition style used by the underlying `UIPageViewController`.
 ///
 /// Defaults to `.scroll`.
 private let transitionStyle: UIPageViewController.TransitionStyle

 /// The navigation orientation of the underlying `UIPageViewController`.
 ///
 /// Defaults to `.horizontal`.
 private let navigationOrientation: UIPageViewController.NavigationOrientation

 /// Creates a new `VLPagedView`.
 ///
 /// - Parameters:
 ///   - current: Binding to the currently displayed step.
 ///   - stepComponent: Optional component used for computing next/previous pages (default `nil`).
 ///   - transition: Transition style for page changes (default `.scroll`).
 ///   - orientation: Navigation orientation for page changes (default `.horizontal`).
 ///   - content: A closure that returns the SwiftUI content for a given step.
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

 /// Creates the `Coordinator` for the paged view.
 ///
 /// The coordinator handles `UIPageViewController` data source and delegate methods,
 /// bridging UIKit and SwiftUI.
 @inlinable
 public func makeCoordinator() -> Coordinator
 {
  Coordinator(self)
 }

 /// Creates the underlying `UIPageViewController`.
 ///
 /// Sets up the initial page and assigns the coordinator as data source and delegate.
 /// - Parameter context: The SwiftUI context for creating the view controller.
 /// - Returns: A configured `UIPageViewController`.
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

 /// Updates the `UIPageViewController` when SwiftUI state changes.
 ///
 /// Checks if `currentIndex` differs from the currently displayed page and
 /// performs a page transition if needed.
 /// - Parameters:
 ///   - uiViewController: The page view controller to update.
 ///   - context: The SwiftUI context for updating the view controller.
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

 /// Coordinator bridging `UIPageViewController` delegate/data source with SwiftUI.
 ///
 /// Handles navigation between pages and updates the `currentIndex` binding.
 public class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate
 {
  /// Reference to the parent `VLPagedView`.
  ///
  /// Used to access the `currentIndex`, `content`, and `stepComponent`.
  package var parent: VLPagedView

  public init(_ parent: VLPagedView)
  {
   self.parent = parent
  }

  /// Returns the view controller before the given one.
  ///
  /// Uses the `pageBackward` method of the current step to determine the previous page.
  /// - Parameters:
  ///   - pageViewController: The page view controller requesting the view controller.
  ///   - viewController: The currently visible view controller.
  /// - Returns: The previous view controller, or `nil` if at the beginning.
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

  /// Returns the view controller after the given one.
  ///
  /// Uses the `pageForward` method of the current step to determine the next page.
  /// - Parameters:
  ///   - pageViewController: The page view controller requesting the view controller.
  ///   - viewController: The currently visible view controller.
  /// - Returns: The next view controller, or `nil` if at the end.
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

  /// Called when a page transition completes.
  ///
  /// Updates the `currentIndex` binding to match the currently displayed page.
  /// - Parameters:
  ///   - pageViewController: The page view controller.
  ///   - finished: Whether the animation finished.
  ///   - previousViewControllers: The previous view controllers.
  ///   - completed: Whether the transition was completed successfully.
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
