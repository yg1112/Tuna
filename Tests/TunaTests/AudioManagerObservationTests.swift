import XCTest
import Combine
@testable import Tuna

final class AudioManagerObservationTests: XCTestCase {
    var audioManager: AudioManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        audioManager = AudioManager.shared
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    func testOutputVolumePublishesChanges() {
        // Given
        let expectation = XCTestExpectation(description: "Output volume change published")
        var receivedVolume: Float?
        
        audioManager.$outputVolume
            .dropFirst() // Skip initial value
            .sink { volume in
                receivedVolume = volume
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        audioManager.setOutputVolume(0.75)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedVolume, 0.75, accuracy: 0.01)
    }
    
    func testInputVolumePublishesChanges() {
        // Given
        let expectation = XCTestExpectation(description: "Input volume change published")
        var receivedVolume: Float?
        
        audioManager.$inputVolume
            .dropFirst() // Skip initial value
            .sink { volume in
                receivedVolume = volume
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        audioManager.setInputVolume(0.6)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedVolume, 0.6, accuracy: 0.01)
    }
    
    func testDeviceSelectionPublishesChanges() {
        // Given
        let expectation = XCTestExpectation(description: "Device selection change published")
        var deviceChanged = false
        
        audioManager.$selectedOutputDevice
            .dropFirst() // Skip initial value
            .sink { _ in
                deviceChanged = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let testDevice = AudioDevice(id: 1, name: "Test Device", uid: "test-uid")
        audioManager.setDefaultDevice(testDevice, forInput: false)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(deviceChanged)
        XCTAssertEqual(audioManager.selectedOutputDevice?.name, "Test Device")
    }
} 