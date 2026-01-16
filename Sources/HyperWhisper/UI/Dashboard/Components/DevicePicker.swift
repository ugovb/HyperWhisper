import SwiftUI

// MARK: - Device Picker
/// Visual device selector with icons for audio input devices
struct DevicePicker: View {
    let devices: [AudioState.InputDevice]
    @Binding var selectedDeviceId: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HyperSpacing.sm) {
            Text("Input Device")
                .font(.hyperUI(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HyperSpacing.md) {
                    ForEach(devices) { device in
                        DeviceCard(
                            device: device,
                            isSelected: device.id == selectedDeviceId
                        ) {
                            withAnimation(.hyperSpring) {
                                selectedDeviceId = device.id
                                onSelect(device.id)
                            }
                        }
                    }
                }
                .padding(.vertical, HyperSpacing.xs)
            }
        }
    }
}

// MARK: - Device Card
struct DeviceCard: View {
    let device: AudioState.InputDevice
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    private var deviceInfo: (icon: String, color: Color) {
        let lowercaseName = device.name.lowercased()
        
        if lowercaseName.contains("airpods") {
            return ("airpodspro", Color(hex: 0x6366F1))
        } else if lowercaseName.contains("macbook") || lowercaseName.contains("built-in") {
            return ("laptopcomputer.and.iphone", .secondary)
        } else if lowercaseName.contains("usb") || lowercaseName.contains("external") {
            return ("mic.fill", .blue)
        } else if lowercaseName.contains("bluetooth") {
            return ("wave.3.right", .cyan)
        } else if lowercaseName.contains("studio") {
            return ("music.mic", .purple)
        }
        
        return ("mic", .secondary)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HyperSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? deviceInfo.color.opacity(0.2) : Color.secondary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: deviceInfo.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? deviceInfo.color : .secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                
                // Name
                Text(shortName)
                    .font(.hyperUI(.caption, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
            .padding(HyperSpacing.md)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: HyperRadius.md)
                            .fill(.ultraThinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: HyperRadius.md)
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: HyperRadius.md)
                    .stroke(
                        isSelected
                            ? deviceInfo.color.opacity(0.5)
                            : (isHovered ? Color.glassBorder : Color.clear),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.hyperSpring, value: isHovered)
            .animation(.hyperSpring, value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var shortName: String {
        // Shorten common device names for display
        var name = device.name
        
        // Common replacements
        name = name.replacingOccurrences(of: "MacBook Pro Microphone", with: "MacBook Mic")
        name = name.replacingOccurrences(of: "MacBook Air Microphone", with: "MacBook Mic")
        name = name.replacingOccurrences(of: "Built-in Microphone", with: "Built-in Mic")
        name = name.replacingOccurrences(of: "AirPods Pro", with: "AirPods Pro")
        
        return name
    }
}

// MARK: - Preview
#Preview("Device Picker") {
    struct PreviewWrapper: View {
        @State private var selectedId = "1"
        let mockDevices: [AudioState.InputDevice] = [
            AudioState.InputDevice(id: "1", name: "MacBook Pro Microphone"),
            AudioState.InputDevice(id: "2", name: "AirPods Pro"),
            AudioState.InputDevice(id: "3", name: "USB Microphone"),
            AudioState.InputDevice(id: "4", name: "Studio Mic")
        ]
        
        var body: some View {
            ZStack {
                Color(hex: 0x1a1a2e)
                    .ignoresSafeArea()
                
                DevicePicker(
                    devices: mockDevices,
                    selectedDeviceId: $selectedId
                ) { id in
                    print("Selected: \(id)")
                }
                .padding()
            }
            .frame(width: 500, height: 200)
        }
    }
    
    return PreviewWrapper()
}
