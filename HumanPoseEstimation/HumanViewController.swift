import UIKit
import Vision
import CoreMedia

class HumanViewController: UIViewController {
    
    public typealias BodyPoint = (point: CGPoint, confidence: Double)
    public typealias DetectObjectsCompletion = ([BodyPoint?]?, Error?) -> Void

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var poseView: HumanPoseView!
	
	typealias EstimationModel = model_cpm
    var coremlModel: EstimationModel? = nil
	
    var request: VNCoreMLRequest!
    var visionModel: VNCoreMLModel! {
        didSet {
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request.imageCropAndScaleOption = .scaleFill
        }
    }
 
    var videoCapture: VideoCapture!

    override func viewDidLoad() {
        super.viewDidLoad()
        visionModel = try? VNCoreMLModel(for: EstimationModel().model)
        setUpCamera()
        poseView.setUpOutputComponent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            
            if success {
 
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

extension HumanViewController {
 
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
       let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    

    func visionRequestDidComplete(request: VNRequest, error: Error?) {
		
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let heatmap = observations.first?.featureValue.multiArrayValue {

            let n_kpoints_Pose = convert(heatmap: heatmap)
            
            DispatchQueue.main.sync {
                self.poseView.bodyPoints = n_kpoints_Pose
            }
        }
    }
    
    func convert(heatmap: MLMultiArray) -> [BodyPoint?] {
        guard heatmap.shape.count >= 3 else {
            print("heatmap invalid. \(heatmap.shape)")
            return []
        }
        let keypoint_number = heatmap.shape[0].intValue
        let heatmap_width = heatmap.shape[1].intValue
        let heatmap_height = heatmap.shape[2].intValue
     
        var n_kpoints_Pose = (0..<keypoint_number).map { _ -> BodyPoint? in
            return nil
        }
        
        for k in 0..<keypoint_number {
            for i in 0..<heatmap_width {
                for j in 0..<heatmap_height {
                    let index = k*(heatmap_width*heatmap_height) + i*(heatmap_height) + j
                    let confidence = heatmap[index].doubleValue
                    guard confidence > 0 else { continue }
                    if n_kpoints_Pose[k] == nil ||
                        (n_kpoints_Pose[k] != nil && n_kpoints_Pose[k]!.confidence < confidence) {
                        n_kpoints_Pose[k] = (CGPoint(x: CGFloat(j), y: CGFloat(i)), confidence)
                    }
                }
            }
        }
        
        

        n_kpoints_Pose = n_kpoints_Pose.map { kpoint -> BodyPoint? in
            if let kp = kpoint {
                return (CGPoint(x: (kp.point.x+0.5)/CGFloat(heatmap_width),
                                y: (kp.point.y+0.5)/CGFloat(heatmap_height)),
                        kp.confidence)
            } else {
                return nil
            }
        }
        
        return n_kpoints_Pose
    }
}


extension HumanViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        if let pixelBuffer = pixelBuffer {
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

//Constant
struct Constant {
	static let pointLabels = [
		"top\t\t\t", //0
		"neck\t\t", //1
		
		"Rshoulder\t", //2
		"Relbow\t\t", //3
		"Rwrist\t\t", //4
		"Lshoulder\t", //5
		"Lelbow\t\t", //6
		"Lwrist\t\t", //7
		
		"Rhip\t\t", //8
		"Rknee\t\t", //9
		"Rankle\t\t", //10
		"Lhip\t\t", //11
		"Lknee\t\t", //12
		"Lankle\t\t", //13
	]
    
	static let connectingPointIndexs: [(Int, Int)] = [
		(0, 1), // top-neck
		
		(1, 2), // neck-rshoulder
		(2, 3), // rshoulder-relbow
		(3, 4), // relbow-rwrist
		(1, 8), // neck-rhip
		(8, 9), // rhip-rknee
		(9, 10), // rknee-rankle
		
		(1, 5), // neck-lshoulder
		(5, 6), // lshoulder-lelbow
		(6, 7), // lelbow-lwrist
		(1, 11), // neck-lhip
		(11, 12), // lhip-lknee
		(12, 13), // lknee-lankle
	]
    static let poseLineColor: UIColor = UIColor(displayP3Red: 87.0/255.0,
                                                 green: 255.0/255.0,
                                                 blue: 211.0/255.0,
                                                 alpha: 0.5)
    
    static let colors: [UIColor] = [
        .green,
        .green,
        .green,
        .green,
        .green,
        .green,
        .green,
        .green,
		.green,
		.green,
		.green,
		.green,
		.green,
		.green,
    ]
}
