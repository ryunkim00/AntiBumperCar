/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var Coordinates: UILabel!
    @IBOutlet weak var driving_state: UILabel!
    @IBOutlet var sceneView: ARSCNView!

    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
      let safe_longitudinal_dist_min: Float = -0.3; // assuming m
      let safe_longitudinal_dist_max: Float = -0.7; // assuming m
      let safe_lateral_dist: Float = 0.2 // assuming m


    func get_driving_state(d_x: Float, d_y: Float, plane: SCNPlane) -> Int {

       if d_y < safe_longitudinal_dist_max || (d_y > safe_longitudinal_dist_min * -1){
         return 1; // drive at speed
       }
      if d_x > (safe_lateral_dist * -1) && d_x < 0{ // pov entering from left
        if d_y > safe_longitudinal_dist_max && d_y < safe_longitudinal_dist_min{ // pov in front of the vehicle
            
            return 0; // apply "brakes"
        } else {
            
            return 2;
        } // turn right
      }
      else if d_x < safe_lateral_dist && d_x >= 0{ // POV entering from the right
        if d_y > safe_longitudinal_dist_max && d_y < safe_longitudinal_dist_min{ // pov in front of the vehicle
            
            return 0; // apply "brakes"
        } else {
            
            return 3;} // turn left
      }
        
      return 1;
    }
    
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        if #available(iOS 12.0, *) {
            configuration.maximumNumberOfTrackedImages = 3
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            
            // Create a plane to visualize the initial position of the detected image.
            let plane = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0.75

            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            planeNode.eulerAngles.x = -.pi / 2
            
            /*
             Image anchors are not tracked after initial detection, so create an
             animation that limits the duration for which the plane visualization appears.
             */
//            planeNode.runAction(self.imageHighlightAction)
            
            // Add the plane visualization to the scene.
            node.addChildNode(planeNode)
            
        }

        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor){
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let x_coord = imageAnchor.transform.columns.3.x
        let z_coord = imageAnchor.transform.columns.3.z

        let referenceImage = imageAnchor.referenceImage
        let plane = SCNPlane(width: referenceImage.physicalSize.width,
                             height: referenceImage.physicalSize.height)
//        let planeNode = SCNNode(geometry: plane)
       
        let driving_state_int = get_driving_state(d_x: x_coord, d_y: z_coord, plane: plane)
        DispatchQueue.main.async { // Correct
            self.Coordinates.text = "(" + String(x_coord) + ", " + String(z_coord) + ")"
            self.driving_state.text = String(driving_state_int)
        }
        
        // Create URL
        let url = URL(string: "https://gtipold.api.stdlib.com/HackThe6ix@dev/update_state/?state=" + String(driving_state_int))
        guard let requestUrl = url else { fatalError() }
        
        // Create URL request
        var request = URLRequest(url: requestUrl)
        
        // Specify HTTP Method to use
        request.httpMethod = "GET"
        
        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check if Error took place
            if let error = error {
                print("error took place \(error)")
            }
            
            // Read HTTP Response Status Code
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
            }
            
            // Convert HTTP Response Data to a simple String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
            }
        }
        task.resume()
        
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
}
