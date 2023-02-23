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
    @State var isConnected: Bool = true // Bluetooth.shared.current != nil { didSet { if isConnected { presented.toggle() } } }
    @State var list = [Bluetooth.Device]()
    @State var string: String = ""
    @State var state: Bool = false
    @State var editing = false
    @State var rssi: Int = 0
    @State var response = Data()
    @State var speed: Float = 40
    
    var body: some View {
        VStack {
            HStack{
                Text("Car:")
                Button("scan"){ presented.toggle() }.buttonStyle(AppButton()).padding()
                Spacer()
                if isConnected {
                    Button("disconnect"){ bluetooth.disconnect() }.buttonStyle(AppButton()).padding()
                    Image(systemName: "cellularbars", variableValue: 0.5)
                        .foregroundStyle(.green)
                    Text("\(rssi)")
                }
            }
            Spacer()
            if isLandscape {
                HStack {
                    ArcKnob("", value: $speed, range: 0...100, origin: 0)
                        .backgroundColor(.orange)
                        .foregroundColor(.red)
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
                ArcKnob("", value: $speed, range: 0...100, origin: 0)
                    .backgroundColor(.orange)
                    .foregroundColor(.red)
                    .squareFrame(300)
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
                Spacer()
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
            Spacer()
            HStack {
                
                Button {
                    
                } label: {
                    Label("Light", systemImage: "headlight.high.beam")
                }
                Button {
                    
                } label: {
                    Label("Beep", systemImage: "speaker.wave.2.fill")
                }
                Button {
                    
                } label: {
                    Label("Track", systemImage: "point.topleft.down.curvedto.point.filled.bottomright.up")
                }
                
            }
            .buttonStyle(FunctionalButton())
//            if isConnected {
//                TextField("cmd", text: $string, onEditingChanged: { editing = $0 })
//                    .onChange(of: string){ bluetooth.send(Array($0.utf8)) }
//                    .textFieldStyle(AppTextField(focused: $editing))
//                Text("returned byte value from \(bluetooth.current?.name ?? ""): \(response.hex)")
//                Text("returned string: \(String(data: response, encoding: .utf8) ?? "")")
//            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $presented){ ScanView(bluetooth: bluetooth, presented: $presented, list: $list, isConnected: $isConnected) }
            .onAppear{ bluetooth.delegate = self }
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
