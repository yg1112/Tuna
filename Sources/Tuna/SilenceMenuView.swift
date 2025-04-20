import AppKit
import SwiftUI

struct SilenceButton: View {
    @State private var isHovering = false
    let action: () -> Void
    let isActive: Bool

    var body: some View {
        Button(action: self.action) {
            ZStack {
                Circle()
                    .fill(
                        self.isActive ? Color(red: 0.3, green: 0.9, blue: 0.7) : Color.gray
                            .opacity(0.6)
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: self.isActive ? "waveform.slash" : "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            self.isHovering = hovering
        }
        .shadow(
            color: self.isActive ? Color(red: 0.3, green: 0.9, blue: 0.7).opacity(0.5) : Color
                .clear,
            radius: 3
        )
        .help(self.isActive ? "Disable Muted Mode" : "Enable Muted Mode")
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

                if self.isExpanded {
                    Button(action: {
                        withAnimation {
                            self.isExpanded.toggle()
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

            if self.isExpanded {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        // Status indicator
                        Circle()
                            .fill(
                                self.isActive ? Color(red: 0.3, green: 0.9, blue: 0.7) : Color.gray
                                    .opacity(0.6)
                            )
                            .frame(width: 8, height: 8)

                        Text(self.isActive ? "Muted Mode Active" : "Muted Mode Disabled")
                            .foregroundColor(.white)
                            .font(.system(size: 13))

                        Spacer()
                    }
                    .padding(.horizontal, 12)

                    // Description text
                    Text(
                        self.isActive ?
                            "Your microphone is currently muted system-wide. Unmute to restore normal operation." :
                            "Enable muted mode to prevent microphone usage by all applications."
                    )
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
                            self.isActive.toggle()
                            // TODO: Implement actual muting functionality
                        }, isActive: self.isActive)
                    }
                    .padding(.horizontal, 12)

                    // Settings button
                    HStack {
                        Button(action: {
                            self.showingSettings.toggle()
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
                            .background(
                                self.showingSettings ? Color.white.opacity(0.2) : Color
                                    .clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // Devices button
                        Button(action: {
                            self.showingDevices.toggle()
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
                            .background(
                                self.showingDevices ? Color.white.opacity(0.2) : Color
                                    .clear
                            )
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
                    Text(self.isActive ? "Muted Mode Active" : "Muted Mode Disabled")
                        .foregroundColor(.white)
                        .font(.system(size: 13))

                    Spacer()

                    SilenceButton(action: {
                        self.isActive.toggle()
                        // TODO: Implement actual muting functionality
                    }, isActive: self.isActive)

                    Button(action: {
                        withAnimation {
                            self.isExpanded.toggle()
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
            self.isHovering = hovering
        }
    }
}
