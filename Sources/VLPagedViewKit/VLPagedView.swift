import SwiftUI
import UIKit

/// A SwiftUI wrapper around `UIPageViewController` that allows paginated navigation between views.
///
/// This view works with a step type `S` conforming to `VLPagedViewStep`.
/// It provides a SwiftUI-friendly interface while using `UIPageViewController` under the hood.
///
/// The height of the view follows the content of the displayed page.
/// - Parameters:
///   - S: The step type representing each page, must conform to `VLPagedViewStep`.
///   - Content: The SwiftUI view displayed for each step.
public struct VLPagedView<S: VLPagedViewStep, Content: View>: UIViewControllerRepresentable
{
 public typealias UIViewControllerType = UIPageViewController

 /// The hosting controller of a single page.
 package typealias Page = UIHostingController<IdentifiedContent>

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

 /// The transition style used by the underlying `UIPageViewController`.
 ///
 /// Defaults to `.scroll`. Read once, when the page view controller is created.
 private let transitionStyle: UIPageViewController.TransitionStyle

 /// The navigation orientation of the underlying `UIPageViewController`.
 ///
 /// Defaults to `.horizontal`. Read once, when the page view controller is created.
 private let navigationOrientation: UIPageViewController.NavigationOrientation

 /// Creates a new `VLPagedView`.
 ///
 /// - Parameters:
 ///   - current: Binding to the currently displayed step.
 ///   - transition: Transition style for page changes (default `.scroll`).
 ///   - orientation: Navigation orientation for page changes (default `.horizontal`).
 ///   - content: A closure that returns the SwiftUI content for a given step.
 public init(current: Binding<S>,
             transition: UIPageViewController.TransitionStyle = .scroll,
             orientation: UIPageViewController.NavigationOrientation = .horizontal,
             @ViewBuilder content: @escaping (S) -> Content)
 {
  self._currentIndex = current
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

 /// Creates the hosting controller of the page for a given step.
 ///
 /// The page has a transparent background, so the background of the parent view stays visible,
 /// and ignores the safe area, so its content does not move while it slides near the screen edges.
 /// - Parameter pageIndex: The step of the page.
 /// - Returns: The hosting controller of the page.
 package func makePage(_ pageIndex: S) -> Page
 {
  let page = Page(rootView: IdentifiedContent(pageIndex: pageIndex,
                                              content: content(pageIndex)))
  page.view.backgroundColor = .clear
  page.safeAreaRegions = []
  return page
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
  context.coordinator.pageViewController = pageViewController
  context.coordinator.currentPage = currentIndex

  let initialPage = makePage(currentIndex)
  context.coordinator.sizedPage = initialPage
  pageViewController.setViewControllers([ initialPage ],
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
  context.coordinator.parent = self

  guard let displayedPage = uiViewController.viewControllers?.first as? Page
  else { return }

  let displayedIndex = displayedPage.rootView.pageIndex

  if currentIndex != context.coordinator.currentPage
  {
   context.coordinator.show(currentIndex,
                            from: displayedIndex,
                            animated: context.transaction.animation != nil)
  }
  else
  {
   displayedPage.rootView = IdentifiedContent(pageIndex: displayedIndex,
                                              content: content(displayedIndex))
  }
 }

 /// Returns the size of the paged view: the proposed width, and the height of the measured page.
 ///
 /// The measured page is the displayed page, except during an animated page change
 /// where it stays the previous page (see `Coordinator.sizedPage`).
 /// - Parameters:
 ///   - proposal: The size proposed by the parent view.
 ///   - uiViewController: The page view controller.
 ///   - context: The SwiftUI context.
 /// - Returns: The size of the paged view, or `nil` to use the proposed size.
 public func sizeThatFits(_ proposal: ProposedViewSize,
                          uiViewController: UIPageViewController,
                          context: Context) -> CGSize?
 {
  guard let measuredPage = context.coordinator.sizedPage ?? (uiViewController.viewControllers?.first as? Page)
  else { return nil }

  let fittingSize = measuredPage.sizeThatFits(in: CGSize(width: proposal.width ?? .infinity,
                                                         height: proposal.height ?? .infinity))
  return CGSize(width: proposal.width ?? fittingSize.width,
                height: fittingSize.height)
 }

 /// Coordinator bridging `UIPageViewController` delegate/data source with SwiftUI.
 ///
 /// Handles navigation between pages and updates the `currentIndex` binding.
 @MainActor
 public final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate
 {
  /// Reference to the parent `VLPagedView`.
  ///
  /// Used to access the `currentIndex` binding and to create the pages.
  package var parent: VLPagedView

  /// The step requested by SwiftUI or reached by a swipe.
  package var currentPage: S?

  /// The page view controller created by the parent.
  package weak var pageViewController: UIPageViewController?

  /// `true` while a page transition is running, from a swipe or from an animated page change.
  package private(set) var isTransitioning = false

  /// The page measured by `sizeThatFits`.
  ///
  /// It stays the previous page during an animated page change:
  /// resizing `UIPageViewController` during its animation makes it display a wrong page.
  package var sizedPage: Page?

  /// The page requested during a transition, displayed when the transition ends.
  ///
  /// Starting a page change during a transition makes `UIPageViewController` display a wrong page.
  package private(set) var pendingPage: (index: S, animated: Bool)?

  public init(_ parent: VLPagedView)
  {
   self.parent = parent
   self.currentPage = parent.currentIndex
  }

  /// Displays the page of a given step, or keeps it for later if a transition is running.
  ///
  /// - Parameters:
  ///   - pageIndex: The step to display.
  ///   - displayedIndex: The step currently displayed, used to choose the direction of the animation.
  ///   - animated: Whether the change should be animated.
  package func show(_ pageIndex: S,
                    from displayedIndex: S,
                    animated: Bool)
  {
   guard let pageViewController
   else { return }

   currentPage = pageIndex

   guard !isTransitioning
   else
   {
    pendingPage = (index: pageIndex, animated: animated)
    return
   }

   let direction: UIPageViewController.NavigationDirection = pageIndex > displayedIndex ? .forward : .reverse
   let page = parent.makePage(pageIndex)

   guard animated
   else
   {
    pageViewController.setViewControllers([ page ],
                                          direction: direction,
                                          animated: false,
                                          completion: nil)
    resize(to: page)
    return
   }

   isTransitioning = true
   pageViewController.setViewControllers([ page ],
                                         direction: direction,
                                         animated: true)
   {
    _ in
    Task
    {
     @MainActor in
     self.resetPageCache()
    }
   }
  }

  /// Displays the page requested during the last transition, if any.
  package func showPendingPage()
  {
   guard let pendingPage,
         let displayedPage = pageViewController?.viewControllers?.first as? Page
   else { return }

   self.pendingPage = nil

   guard pendingPage.index != displayedPage.rootView.pageIndex
   else { return }

   show(pendingPage.index,
        from: displayedPage.rootView.pageIndex,
        animated: pendingPage.animated)
  }

  /// Measures the given page from now on, and asks SwiftUI for the new size.
  ///
  /// - Parameter page: The page to measure.
  package func resize(to page: UIViewController)
  {
   sizedPage = page as? Page
   pageViewController?.view.invalidateIntrinsicContentSize()
  }

  /// Ends an animated page change.
  ///
  /// A page requested meanwhile is displayed at once: its own change refreshes the cache.
  /// Setting the displayed page again just before that change makes UIKit drop the completion of its animation.
  ///
  /// Otherwise, after an animated change, `UIPageViewController` keeps in cache the neighbours of the previous page.
  /// Setting the displayed page again, without animation, makes it ask the data source for the new neighbours.
  /// Then the new page is measured.
  package func resetPageCache()
  {
   isTransitioning = false

   guard let pageViewController,
         let displayedPage = pageViewController.viewControllers?.first as? Page
   else { return }

   if let pendingPage,
      pendingPage.index != displayedPage.rootView.pageIndex
   {
    showPendingPage()
    return
   }

   self.pendingPage = nil
   pageViewController.setViewControllers([ displayedPage ],
                                         direction: .forward,
                                         animated: false,
                                         completion: nil)
   resize(to: displayedPage)
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
   guard let page = viewController as? Page,
         let previousIndex = page.rootView.pageIndex.pageBackward()
   else { return nil }

   return parent.makePage(previousIndex)
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
   guard let page = viewController as? Page,
         let nextIndex = page.rootView.pageIndex.pageForward()
   else { return nil }

   return parent.makePage(nextIndex)
  }

  /// Called when a swipe starts.
  ///
  /// - Parameters:
  ///   - pageViewController: The page view controller.
  ///   - pendingViewControllers: The view controllers being transitioned to.
  public func pageViewController(_ pageViewController: UIPageViewController,
                                 willTransitionTo pendingViewControllers: [ UIViewController ])
  {
   isTransitioning = true
  }

  /// Called when a swipe ends.
  ///
  /// Updates the `currentIndex` binding to match the currently displayed page,
  /// unless a page was requested during the swipe: that page is displayed instead.
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
   isTransitioning = false

   if let page = pageViewController.viewControllers?.first as? Page
   {
    resize(to: page)

    if completed,
       pendingPage == nil
    {
     currentPage = page.rootView.pageIndex
     parent.currentIndex = page.rootView.pageIndex
    }
   }

   Task
   {
    @MainActor in
    self.showPendingPage()
   }
  }
 }
}
