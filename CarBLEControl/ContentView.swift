//
//  ContentView.swift
//  CarBLEControl
//
//  Created by PROPGM on 23/2/2023.
//

import SwiftUI
import Controls

struct ContentView: View {
    var bluetooth = Bluetooth.shared
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    var isLandscape: Bool { verticalSizeClass == .compact }
    
    @State var radius: Float = 0
    @State var angle: Float = 0

    @State var presented: Bool = false
    @State var isConnected: Bool = Bluetooth.shared.current != nil { didSet { if isConnected { presented.toggle() } } }
    @State var list = [Bluetooth.Device]()
    @State var string: String = ""
    @State var state: Bool = false
    @State var editing = false
    @State var rssi: Int = 0
    @State var response = Data()
    @State var speed: Float = 40
    @State var speedInt: Int = 40
    @State var dir: Direction = .stop
    @State var isBeep = false
    @State var lightMode: LightMode = .off
    @State var motionMode: MotionMode = .ble
    @State var batteryLevel: BatteryLevel = .low
    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    
    enum Direction: Int {
        case stop = 0
        case up
        case left
        case down
        case right
    }
    
    enum MotionMode: UInt8 {
        case auto = 0xc
        case avoid = 0xd
        case ble = 0xe
    }
    
    enum LightMode: UInt8 {
        case on = 0x7
        case off = 0x8
        case auto = 0xf
    }
    
    enum BatteryLevel: UInt8 {
        case empty = 0
        case low = 25
        case middle = 50
        case high = 75
        case full = 100
    }
    
    private var signal: Double {
//        A more strong connection is between -30 to -55
//       • A strong connection starts from -55 to -67
//       • A terrible connection starts from -80 to -90
//       • An unusable connection starts from -90 and below
        var percentage = 0.0
        if rssi > -55 { percentage = 1 }
        else if rssi > -67 { percentage = 0.74 }
        else if rssi > -80 { percentage = 0.5 }
        else if rssi > -90 { percentage = 0.25 }
        return percentage
    }
    
    private var signalColor: Color {
        if rssi > -55 { return .green }
        else if rssi > -67 { return .yellow }
        else if rssi > -80 { return .orange }
        else { return .red }
    }
    
    private var batteryColor: Color {
        switch batteryLevel {
        case .empty: return .red
        case .low: return .orange
        case .middle: return .yellow
        case .high, .full: return .green
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(isConnected ? "\(bluetooth.current?.name ?? "NO_NAME")" : "Choose a Car \(Image(systemName: "chevron.right"))") { presented.toggle() }.buttonStyle(AppButton()).padding(.leading)
                    .font(.system(size: 14))
                Image(systemName: "battery.\(batteryLevel.rawValue)").foregroundColor(batteryColor)
                    .opacity(isConnected ? 1 : 0)
                Spacer()
                if isConnected {
                    Button("Disconnect"){ bluetooth.disconnect() }.buttonStyle(AppButton()).font(.system(size: 14))
                    Image(systemName: "cellularbars", variableValue: signal)
                        .foregroundStyle(signalColor)
                    Text("\(rssi)").font(.system(size: 14)).monospaced()
                }
            }
            Spacer()
            if isLandscape {
                HStack {
                    ArcKnob("", value: $speed, range: 0...100, origin: 0)
                        .backgroundColor(.orange)
                        .foregroundColor(.accentColor)
                        //.squareFrame(300)
                        .overlay {
                            VStack {
                                Spacer()
                                Image(systemName: "speedometer")
                                    .resizable()
                                    .squareFrame(50)
                                    .padding(.bottom, 50)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.accentColor, .secondary)
                            }
                        }
                        
                    
                    VStack {
                        Joystick(radius: $radius, angle: $angle)
                            .backgroundColor(Color.secondary)
                            .foregroundColor(Color.accentColor)
                            .cornerRadius(10)
                        .squareFrame(200)
                        Text("radius: \(radius), angle: \(angle)")
                            .foregroundColor(.secondary)
                            .font(.system(.caption))
                            .monospaced()
                    }
                }
            }
            else {
                SpeedKnob("", value: $speed, range: 0...100, origin: 0)
                    .squareFrame(300)
                    .overlay {
                        VStack {
                            Spacer()
                            Image(systemName: "speedometer")
                                .resizable()
                                .squareFrame(50)
                                .padding(.bottom, 50)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                Spacer()
                Joystick(radius: $radius, angle: $angle)
                    .backgroundColor(Color.secondary)
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                    .squareFrame(200)
            }
            Spacer()
            HStack {
                Button {
                    switch lightMode {
                    case .auto:
                        lightMode = .on
                    case .on:
                        lightMode = .off
                    case .off:
                        lightMode = .auto
                    }
                    let cmd = UInt8(truncatingIfNeeded: lightMode.rawValue)
                    let cmdVal = Data([cmd])
                    sendControlCommand(data: cmdVal)
                } label: {
                    switch lightMode {
                    case .auto:
                        Label("Auto", systemImage: "auto.headlight.high.beam.fill")
                    case .on:
                        Label("On", systemImage: "headlight.high.beam")
                    case .off:
                        Label("Off", systemImage: "headlight.high.beam.fill")
                    }
                }
                Button {
                    sendControlCommand(cmd: isBeep ? [0x6] : [0x5])
                    isBeep.toggle()
                } label: {
                    Label("Beep", systemImage: isBeep ? "speaker.slash" : "speaker.wave.2.fill")
                }
                Button {
                    switch motionMode {
                    case .ble:
                        motionMode = .auto
                    case .auto:
                        motionMode = .avoid
                    case .avoid:
                        motionMode = .ble
                    }
                    let cmd = UInt8(truncatingIfNeeded: motionMode.rawValue)
                    let cmdVal = Data([cmd])
                    sendControlCommand(data: cmdVal)
                } label: {
                    switch motionMode {
                    case .ble:
                        Label {
                            Text("BLE")
                        } icon: {
                            Image("bluetooth")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22)
                        }
                    case .auto:
                        Label("Track", systemImage: "point.topleft.down.curvedto.point.filled.bottomright.up")
                    case .avoid:
                        Label("Avoid", systemImage: "car.top.radiowaves.front.fill")
                    }
                }
            }
            .buttonStyle(FunctionalButton())
            Spacer()
        }
        .padding()
        .sheet(isPresented: $presented) {
            ScanView(bluetooth: bluetooth, presented: $presented, list: $list, isConnected: $isConnected) }
        .onAppear{
            bluetooth.delegate = self
        }
        .onChange(of: radius) { newValue in
            calculateDir(radius: newValue, angle: angle)
        }
        .onChange(of: angle) { newValue in
            calculateDir(radius: radius, angle: newValue)
        }
        .onChange(of: dir) { newValue in
            sendDirComand(dir: newValue)
        }
        .onChange(of: speed) { newValue in
            speedInt = Int(speed)
        }
        .onChange(of: speedInt) { newValue in
            guard let data = "\(8):\(newValue)".data(using: .utf8) else { return }
            sendControlCommand(data: data)
        }
        .onReceive(timer) { _ in
            if isConnected {
                bluetooth.startListening()
                sendControlCommand(cmd: [0x10])
            }
        }
        .onChange(of: response) { newValue in
            guard let response = String(data: newValue, encoding: .utf8), response.count > 3 else { return }
            let cmdValues = response.components(separatedBy: ":")
            guard let cmd = cmdValues.first, let valStr = cmdValues.last, let val = Int(valStr) else { return }
            if cmd == "16" { // 电量检测
                if (val < 1600) {
                    batteryLevel = .empty
                } else if (val < 1900) {
                    batteryLevel = .low
                } else if (val < 2200) {
                    batteryLevel = .middle
                } else if (val < 2500) {
                    batteryLevel = .high
                } else {
                    batteryLevel = .full
                }
            }
        }
    }
}

extension ContentView {
    private func calculateDir(radius: Float, angle: Float) {
        if radius < 0.5 {
            dir = .stop
        } else {
            if angle > 0.12 && angle <= 0.37 {
                dir = .left
            } else if angle > 0.37 && angle <= 0.62 {
                dir = .up
            } else if angle > 0.62 && angle <= 0.87 {
                dir = .right
            } else {
                dir = .down
            }
        }
    }
    
    private func sendDirComand(dir: Direction) {
        let cmd = UInt8(truncatingIfNeeded: dir.rawValue)
        let cmdVal = Data([cmd])
        sendControlCommand(data: cmdVal)
    }
    
    private func sendControlCommand(cmd: [UInt8]) {
        bluetooth.send(cmd)
    }
    
    private func sendControlCommand(data: Data) {
        bluetooth.send(data)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AppButton: ButtonStyle {
    let color: Color
    
    public init(color: Color = .accentColor) {
        self.color = color
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(.accentColor)
            .background(Color.accentColor.opacity(0.2))
            .cornerRadius(8)
    }
}

struct FunctionalButton: ButtonStyle {
    let color: Color
    
    public init(color: Color = .accentColor) {
        self.color = color
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.accentColor)
            .background(Color.accentColor.opacity(0.2))
            .cornerRadius(8)
    }
}

struct AppTextField: TextFieldStyle {
    @Binding var focused: Bool
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(focused ? Color.accentColor : Color.accentColor.opacity(0.2), lineWidth: 2)
            ).padding()
    }
}

extension Bool {
    var int: Int { self ? 1 : 0 }
}

extension Data {
    var hex: String { map{ String(format: "%02x", $0) }.joined() }
}

extension ContentView: BluetoothProtocol {
    func state(state: Bluetooth.State) {
        switch state {
        case .unknown: print("◦ .unknown")
        case .resetting: print("◦ .resetting")
        case .unsupported: print("◦ .unsupported")
        case .unauthorized: print("◦ bluetooth disabled, enable it in settings")
        case .poweredOff: print("◦ turn on bluetooth")
        case .poweredOn: print("◦ everything is ok")
        case .error: print("• error")
        case .connected:
            print("◦ connected to \(bluetooth.current?.name ?? "")")
            isConnected = true
        case .disconnected:
            print("◦ disconnected")
            isConnected = false
        }
    }
    
    func list(list: [Bluetooth.Device]) { self.list = list }
    
    func value(data: Data) { response = data }
    
    func rssi(value: Int) { rssi = value; print(value) }
}
