import XCTest
import SwiftUI
import ViewInspector
@testable import Tuna

final class VolumeSliderTests: XCTestCase {
    var audioManager: AudioManager!
    
    override func setUp() {
        super.setUp()
        self.audioManager = AudioManager.shared
    }
    
    func testVolumeSliderPresence() throws {
        let devicesView = DevicesTabView()
            .environmentObject(self.audioManager)
        
        let sliders = try devicesView.inspect().findAll(Slider<Float>.self)
        XCTAssertEqual(sliders.count, 2, "Expected exactly two volume sliders (input and output)")
    }
    
    func testOutputVolumeSliderChange() throws {
        let devicesView = DevicesTabView()
            .environmentObject(self.audioManager)
        
        // Find output volume slider
        let slider = try devicesView.inspect().findAll(Slider<Float>.self).first { slider in
            let binding = try slider.binding()
            return binding.address == self.audioManager.outputVolume.address
        }
        
        XCTAssertNotNil(slider, "Output volume slider not found")
        
        // Test volume change
        let newVolume: Float = 0.75
        try slider?.setInput(newVolume)
        XCTAssertEqual(self.audioManager.outputVolume, newVolume, accuracy: 0.01)
    }
    
    func testInputVolumeSliderChange() throws {
        let devicesView = DevicesTabView()
            .environmentObject(self.audioManager)
        
        // Find input volume slider
        let slider = try devicesView.inspect().findAll(Slider<Float>.self).first { slider in
            let binding = try slider.binding()
            return binding.address == self.audioManager.inputVolume.address
        }
        
        XCTAssertNotNil(slider, "Input volume slider not found")
        
        // Test volume change
        let newVolume: Float = 0.6
        try slider?.setInput(newVolume)
        XCTAssertEqual(self.audioManager.inputVolume, newVolume, accuracy: 0.01)
    }
}

// Make DevicesTabView inspectable
extension DevicesTabView: Inspectable { } 