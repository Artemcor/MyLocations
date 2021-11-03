//
//  HudView.swift
//  MyLocations
//
//  Created by Стожок Артём on 21.10.2021.
//

import UIKit

class HudView: UIView {
    var text = ""
    
    class func hud(inView view: UIView, animated: Bool) -> HudView {
        let hudView = HudView(frame: view.bounds)
        hudView.isOpaque = false
        view.addSubview(hudView)
        view.isUserInteractionEnabled = false
        hudView.show(animated: animated)
        return hudView
    }
    
    override func draw(_ rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        let boxRect = CGRect(x: round((bounds.size.width - boxWidth) / 2), y: round((bounds.size.height - boxHeight) / 2), width: boxWidth, height: boxHeight)
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        // Draw the image
        guard let image = UIImage(named: "Checkmark") else { return }
        let  imagePoint = CGPoint(x: round(((bounds.size.width -  image.size.width) / 2)) , y: round(bounds.size.height / 2 - image.size.height / 1.5))
        image.draw(at: imagePoint)
        // Draw the text
        let attribs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.white]
        let textSize = text.size(withAttributes: attribs)
        let textPoint = CGPoint(x: round((bounds.size.width - textSize.width) / 2 ) , y: round((bounds.size.height) / 2) + textSize.height )
        text.draw(at: textPoint, withAttributes: attribs)
    }
    
    func show(animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                self.alpha = 1
                self.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    func hide() {
        superview?.isUserInteractionEnabled = true
        removeFromSuperview()
    }
}

