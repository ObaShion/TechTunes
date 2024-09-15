//
//  CustomSlider.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/12.
//

import UIKit

class CustomSlider: UISlider {
    
    @IBInspectable var thumbRadius: CGFloat = 10
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Customize the thumb
        let thumb = thumbImage(diameter: thumbRadius)
        setThumbImage(thumb, for: .normal)
        
        // (Optional) Enlarge thumb size while dragging (1.2 times larger)
        let highlightedThumb = thumbImage(diameter: thumbRadius * 1.2)
        setThumbImage(highlightedThumb, for: .highlighted)
    }
    
    // Generate a circular thumb image with the specified diameter
    private func thumbImage(diameter: CGFloat) -> UIImage? {
        let size = CGSize(width: diameter, height: diameter)
        
        // Create a graphics context to draw the circle
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw a circle
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(ovalIn: rect)
        UIColor.white.setFill() // You can change the color here
        path.fill()
        
        // Get the generated image
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}
