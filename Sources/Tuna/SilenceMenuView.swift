import SwiftUI
import AppKit

struct SilenceButton: View {
    @State private var isHovering = false
    let action: () -> Void
    let isActive: Bool
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? Color(red: 0.3, green: 0.9, blue: 0.7) : Color.gray.opacity(0.6))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isActive ? "waveform.slash" : "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .shadow(color: isActive ? Color(red: 0.3, green: 0.9, blue: 0.7).opacity(0.5) : Color.clear, radius: 3)
        .help(isActive ? "Disable Muted Mode" : "Enable Muted Mode")
    }
}

struct SilenceMenuView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var isHovering = false
    @State private var showingSettings = false
    @State private var showingDevices = false
    @State private var isActive = false
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("MUTED MODE")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
                
                Spacer()
                
                if isExpanded {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            
            if isExpanded {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        // Status indicator
                        Circle()
                            .fill(isActive ? Color(red: 0.3, green: 0.9, blue: 0.7) : Color.gray.opacity(0.6))
                            .frame(width: 8, height: 8)
                        
                        Text(isActive ? "Muted Mode Active" : "Muted Mode Disabled")
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    
                    // Description text
                    Text(isActive ?
                         "Your microphone is currently muted system-wide. Unmute to restore normal operation." :
                            "Enable muted mode to prevent microphone usage by all applications.")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 8)
                    
                    HStack {
                        Text("Toggle Muted Mode")
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        SilenceButton(action: {
                            isActive.toggle()
                            // TODO: Implement actual muting functionality
                        }, isActive: isActive)
                    }
                    .padding(.horizontal, 12)
                    
                    // Settings button
                    HStack {
                        Button(action: {
                            showingSettings.toggle()
                            // TODO: Implement settings view
                        }) {
                            HStack {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 12))
                                
                                Text("Settings")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(showingSettings ? Color.white.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Devices button
                        Button(action: {
                            showingDevices.toggle()
                            // TODO: Implement devices list
                        }) {
                            HStack {
                                Image(systemName: "mic")
                                    .font(.system(size: 12))
                                
                                Text("Devices")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(showingDevices ? Color.white.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            } else {
                HStack {
                    Text(isActive ? "Muted Mode Active" : "Muted Mode Disabled")
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                    
                    Spacer()
                    
                    SilenceButton(action: {
                        isActive.toggle()
                        // TODO: Implement actual muting functionality
                    }, isActive: isActive)
                    
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
        .onHover { hovering in
            isHovering = hovering
        }
    }
} 