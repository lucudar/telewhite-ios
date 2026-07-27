import Foundation
import UIKit
import Display
import AccountContext

// Telewhite: the custom colour rows in the mods screen used to ask for a typed HEX code,
// which meant no wheel, no live feel and no eyedropper. The system picker gives all three
// (grid, spectrum wheel, sliders with a HEX field) so there is nothing left to hand-roll.
// Gated at 15.0 rather than the picker's own 14.0: the non-deprecated delegate callback
// (didSelect:continuously:) only exists from 15, and implementing the 14-era one instead
// would trip -warnings-as-errors on the deprecation. iOS 13/14 keep the HEX prompt.
@available(iOS 15.0, *)
final class TelewhiteColorPickerPresenter: NSObject, UIColorPickerViewControllerDelegate {
    // UIColorPickerViewController holds its delegate weakly. Without keeping the presenter
    // alive here it would be deallocated as soon as present() returns and the picked colour
    // would never reach the settings.
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
        // Skip the intermediate values of a drag: every commit rewrites the settings and
        // rebuilds the presentation theme, which is far too heavy to run per touch move.
        guard !continuously else {
            return
        }
        self.commit(color)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.commit(viewController.selectedColor)

        if TelewhiteColorPickerPresenter.activePresenter === self {
            TelewhiteColorPickerPresenter.activePresenter = nil
        }
    }
}
