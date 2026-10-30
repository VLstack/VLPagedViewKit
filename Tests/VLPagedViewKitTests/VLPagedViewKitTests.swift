import SwiftUI
import Testing
import UIKit
@testable import VLPagedViewKit

/// Step type bounded between 0 and 3.
struct TestStep: VLPagedViewStep
{
 static let range = 0...3

 let value: Int

 static func < (lhs: TestStep, rhs: TestStep) -> Bool
 {
  lhs.value < rhs.value
 }

 func pageForward() -> TestStep?
 {
  value < Self.range.upperBound ? TestStep(value: value + 1) : nil
 }

 func pageBackward() -> TestStep?
 {
  value > Self.range.lowerBound ? TestStep(value: value - 1) : nil
 }
}

/// Storage behind the binding of the tests.
/// `@unchecked Sendable`: only used from the main actor, by the tests.
final class StepBox: @unchecked Sendable
{
 var step: TestStep

 init(_ step: TestStep)
 {
  self.step = step
 }
}

typealias TestPagedView = VLPagedView<TestStep, Text>

@MainActor
struct VLPagedViewKitTests
{
 let box = StepBox(TestStep(value: 1))

 func makePagedView() -> TestPagedView
 {
  let box = self.box
  return TestPagedView(current: Binding(get: { box.step },
                                        set: { box.step = $0 }))
  {
   step in
   Text("\(step.value)")
  }
 }

 /// Page view controller displaying the page of a given step, with its coordinator.
 func makePageViewController(_ pagedView: TestPagedView,
                             displaying step: TestStep) -> (UIPageViewController, TestPagedView.Coordinator)
 {
  let coordinator = pagedView.makeCoordinator()
  let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                navigationOrientation: .horizontal)
  pageViewController.dataSource = coordinator
  pageViewController.delegate = coordinator
  coordinator.pageViewController = pageViewController
  pageViewController.setViewControllers([ pagedView.makePage(step) ],
                                        direction: .forward,
                                        animated: false,
                                        completion: nil)
  return (pageViewController, coordinator)
 }

 func displayedStep(_ pageViewController: UIPageViewController) -> TestStep?
 {
  (pageViewController.viewControllers?.first as? TestPagedView.Page)?.rootView.pageIndex
 }

 // MARK: - Steps

 @Test func stepsFollowTheirOrder()
 {
  #expect(TestStep(value: 1).pageForward() == TestStep(value: 2))
  #expect(TestStep(value: 1).pageBackward() == TestStep(value: 0))
  #expect(TestStep(value: 3).pageForward() == nil)
  #expect(TestStep(value: 0).pageBackward() == nil)
  #expect(TestStep(value: 0) < TestStep(value: 1))
 }

 // MARK: - Pages

 @Test func makePageSetsIndexBackgroundAndSafeArea()
 {
  let page = makePagedView().makePage(TestStep(value: 2))

  #expect(page.rootView.pageIndex == TestStep(value: 2))
  #expect(page.view.backgroundColor == .clear)
  #expect(page.safeAreaRegions == [])
 }

 // MARK: - Data source

 @Test func pageAfterAndBeforeHaveNeighbourSteps()
 {
  let pagedView = makePagedView()
  let (pageViewController, coordinator) = makePageViewController(pagedView, displaying: TestStep(value: 1))
  let page = pagedView.makePage(TestStep(value: 1))

  let after = coordinator.pageViewController(pageViewController, viewControllerAfter: page) as? TestPagedView.Page
  let before = coordinator.pageViewController(pageViewController, viewControllerBefore: page) as? TestPagedView.Page

  #expect(after?.rootView.pageIndex == TestStep(value: 2))
  #expect(before?.rootView.pageIndex == TestStep(value: 0))
 }

 @Test func noPageBeyondTheBounds()
 {
  let pagedView = makePagedView()
  let (pageViewController, coordinator) = makePageViewController(pagedView, displaying: TestStep(value: 1))

  #expect(coordinator.pageViewController(pageViewController,
                                         viewControllerAfter: pagedView.makePage(TestStep(value: 3))) == nil)
  #expect(coordinator.pageViewController(pageViewController,
                                         viewControllerBefore: pagedView.makePage(TestStep(value: 0))) == nil)
 }

 @Test func noPageAroundAForeignViewController()
 {
  let pagedView = makePagedView()
  let (pageViewController, coordinator) = makePageViewController(pagedView, displaying: TestStep(value: 1))
  let foreign = UIViewController()

  #expect(coordinator.pageViewController(pageViewController, viewControllerAfter: foreign) == nil)
  #expect(coordinator.pageViewController(pageViewController, viewControllerBefore: foreign) == nil)
 }

 // MARK: - Delegate

 @Test func completedSwipeUpdatesBinding()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 2))

  coordinator.pageViewController(pageViewController, willTransitionTo: [])
  #expect(coordinator.isTransitioning)

  coordinator.pageViewController(pageViewController,
                                 didFinishAnimating: true,
                                 previousViewControllers: [],
                                 transitionCompleted: true)

  #expect(box.step == TestStep(value: 2))
  #expect(coordinator.currentPage == TestStep(value: 2))
  #expect(!coordinator.isTransitioning)
 }

 @Test func cancelledSwipeKeepsBinding()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 2))

  coordinator.pageViewController(pageViewController, willTransitionTo: [])
  coordinator.pageViewController(pageViewController,
                                 didFinishAnimating: true,
                                 previousViewControllers: [],
                                 transitionCompleted: false)

  #expect(box.step == TestStep(value: 1))
  #expect(coordinator.currentPage == TestStep(value: 1))
  #expect(!coordinator.isTransitioning)
 }

 // MARK: - Page changes

 @Test func showWithoutAnimationDisplaysThePage()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 1))

  coordinator.show(TestStep(value: 3), from: TestStep(value: 1), animated: false)

  #expect(displayedStep(pageViewController) == TestStep(value: 3))
  #expect(coordinator.currentPage == TestStep(value: 3))
  #expect(coordinator.sizedPage?.rootView.pageIndex == TestStep(value: 3))
  #expect(!coordinator.isTransitioning)
 }

 @Test func animatedShowKeepsThePreviousSizedPage()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 1))
  coordinator.sizedPage = pageViewController.viewControllers?.first as? TestPagedView.Page

  coordinator.show(TestStep(value: 3), from: TestStep(value: 1), animated: true)

  #expect(coordinator.isTransitioning)
  #expect(coordinator.currentPage == TestStep(value: 3))
  #expect(coordinator.sizedPage?.rootView.pageIndex == TestStep(value: 1))
 }

 @Test func showDuringASwipeIsDeferred()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 1))

  coordinator.pageViewController(pageViewController, willTransitionTo: [])
  coordinator.show(TestStep(value: 0), from: TestStep(value: 1), animated: false)

  #expect(displayedStep(pageViewController) == TestStep(value: 1))
  #expect(coordinator.currentPage == TestStep(value: 0))
  #expect(coordinator.pendingPage?.index == TestStep(value: 0))

  coordinator.pageViewController(pageViewController,
                                 didFinishAnimating: true,
                                 previousViewControllers: [],
                                 transitionCompleted: false)
  coordinator.showPendingPage()

  #expect(displayedStep(pageViewController) == TestStep(value: 0))
  #expect(coordinator.pendingPage == nil)
 }

 @Test func pendingPageWinsOverACompletedSwipe()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 2))

  coordinator.pageViewController(pageViewController, willTransitionTo: [])
  coordinator.show(TestStep(value: 3), from: TestStep(value: 2), animated: false)
  coordinator.pageViewController(pageViewController,
                                 didFinishAnimating: true,
                                 previousViewControllers: [],
                                 transitionCompleted: true)

  #expect(box.step == TestStep(value: 1))
  #expect(coordinator.currentPage == TestStep(value: 3))

  coordinator.showPendingPage()

  #expect(displayedStep(pageViewController) == TestStep(value: 3))
 }

 @Test func resetPageCacheEndsTheTransition()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 1))

  coordinator.pageViewController(pageViewController, willTransitionTo: [])
  coordinator.resetPageCache()

  #expect(!coordinator.isTransitioning)
  #expect(displayedStep(pageViewController) == TestStep(value: 1))
  #expect(coordinator.sizedPage?.rootView.pageIndex == TestStep(value: 1))
 }

 @Test func resetPageCacheShowsThePendingPage()
 {
  let (pageViewController, coordinator) = makePageViewController(makePagedView(), displaying: TestStep(value: 1))

  coordinator.pageViewController(pageViewController, willTransitionTo: [])
  coordinator.show(TestStep(value: 2), from: TestStep(value: 1), animated: false)
  coordinator.resetPageCache()

  #expect(displayedStep(pageViewController) == TestStep(value: 2))
  #expect(coordinator.pendingPage == nil)
  #expect(coordinator.sizedPage?.rootView.pageIndex == TestStep(value: 2))
  #expect(!coordinator.isTransitioning)
 }
}
