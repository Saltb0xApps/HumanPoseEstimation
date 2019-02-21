import UIKit

class HumanPoseView: UIView {
    
    var view_Output: [UIView] = []

    var bodyPoints: [HumanViewController.BodyPoint?] = [] {
        didSet {
            self.setNeedsDisplay()
            self.drawKeypoints(with: bodyPoints)
        }
    }
    
    func setUpOutputComponent() {
        view_Output = Constant.colors.map { color in
            let v = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
            v.backgroundColor = color
            v.clipsToBounds = false
            let l = UILabel(frame: CGRect(x: 4 + 3, y: -3, width: 100, height: 8))
            l.text = Constant.pointLabels[Constant.colors.index(where: {$0 == color})!]
            l.textColor = color
            l.font = UIFont.preferredFont(forTextStyle: .caption2)
            v.addSubview(l)
            self.addSubview(v)
            return v
        }
        
        
        var x: CGFloat = 0.0
        let y: CGFloat = self.frame.size.height - 24
        let _ = Constant.colors.map { color in
            let index = Constant.colors.index(where: { color == $0 })
            if index == 2 || index == 8 { x += 28 }
            else { x += 14 }
            let v = UIView(frame: CGRect(x: x, y: y + 10, width: 4, height: 4))
            v.backgroundColor = color
            
            self.addSubview(v)
            return
        }
    }
    
    override func draw(_ rect: CGRect) {
        if let ctx = UIGraphicsGetCurrentContext() {
            
            ctx.clear(rect);
            
            let size = self.bounds.size
            
            let color = Constant.poseLineColor.cgColor
            if Constant.pointLabels.count == bodyPoints.count {
                let _ = Constant.connectingPointIndexs.map { pIndex1, pIndex2 in
                    if let bp1 = self.bodyPoints[pIndex1], bp1.confidence > 0.5,
                        let bp2 = self.bodyPoints[pIndex2], bp2.confidence > 0.5 {
                        let p1 = bp1.point
                        let p2 = bp2.point
                        let point1 = CGPoint(x: p1.x * size.width, y: p1.y*size.height)
                        let point2 = CGPoint(x: p2.x * size.width, y: p2.y*size.height)
                        drawLine(ctx: ctx, from: point1, to: point2, color: color)
                    }
                }
            }
        }
    }
    
    func drawLine(ctx: CGContext, from p1: CGPoint, to p2: CGPoint, color: CGColor) {
        ctx.setStrokeColor(color)
        ctx.setLineWidth(2.0)
        ctx.move(to: p1)
        ctx.addLine(to: p2)
        ctx.strokePath();
    }
    
    func drawKeypoints(with n_kpoints_Pose: [HumanViewController.BodyPoint?]) {
        let imageFrame = view_Output.first?.superview?.frame ?? .zero
        
        let minAlpha: CGFloat = 0.4
        let maxAlpha: CGFloat = 1.0
        let maxC: Double = 0.6
        let minC: Double = 0.1
        
        for (index, kp) in n_kpoints_Pose.enumerated() {
            if let n_kp = kp {
                let x = n_kp.point.x * imageFrame.width
                let y = n_kp.point.y * imageFrame.height
                view_Output[index].center = CGPoint(x: x, y: y)
                let cRate = (n_kp.confidence - minC)/(maxC - minC)
                view_Output[index].alpha = (maxAlpha - minAlpha) * CGFloat(cRate) + minAlpha
            } else {
                view_Output[index].center = CGPoint(x: -4000, y: -4000)
                view_Output[index].alpha = minAlpha
            }
        }
    }
}

