import Foundation
import UIKit
import Display
import AccountContext

@available(iOS 15.0, *)
final class TelewhiteColorPickerPresenter: NSObject, UIColorPickerViewControllerDelegate {
    private static var activePresenter: TelewhiteColorPickerPresenter?

    private let apply: (Int64) -> Void

    private init(apply: @escaping (Int64) -> Void) {
        self.apply = apply
        super.init()
    }

    static func present(context: AccountContext, title: String, initialColor: Int64?, apply: @escaping (Int64) -> Void) {
        let controller = UIColorPickerViewController()
        controller.title = title
        controller.supportsAlpha = false
        if let initialColor = initialColor {
            controller.selectedColor = UIColor(rgb: UInt32(truncatingIfNeeded: initialColor))
        }

        let presenter = TelewhiteColorPickerPresenter(apply: apply)
        controller.delegate = presenter
        TelewhiteColorPickerPresenter.activePresenter = presenter

        context.sharedContext.applicationBindings.presentNativeController(controller)
    }

    private func commit(_ color: UIColor) {
        self.apply(Int64(color.rgb))
    }

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        guard !continuously else { return }
        self.commit(color)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.commit(viewController.selectedColor)
        if TelewhiteColorPickerPresenter.activePresenter === self {
            TelewhiteColorPickerPresenter.activePresenter = nil
        }
    }
}
