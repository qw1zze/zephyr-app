//
//  QRScannerSheet.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI
import AVFoundation

private let accentLime = Color(red: 0.78, green: 1.0, blue: 0.0)

struct QRScannerSheet: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var torchOn = false

    var body: some View {
        ZStack {
            QRCameraView(torchOn: $torchOn) { value in
                onScan(value)
                dismiss()
            }
            .ignoresSafeArea()

            VStack {
                closeButton
                Spacer()
                finder
                hint
                Spacer()
                torchButton
            }
        }
        .preferredColorScheme(.dark)
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(20)
        }
    }

    private var finder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        }
        .frame(width: 240, height: 240)
    }

    private var hint: some View {
        Text("Наведите камеру на QR-код с Ethereum-адресом")
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
            .padding(.top, 20)
    }

    private var torchButton: some View {
        Button { torchOn.toggle() } label: {
            Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.system(size: 22))
                .foregroundStyle(torchOn ? accentLime : .white)
                .padding(16)
                .background(Color(white: 0.18), in: Circle())
        }
        .padding(.bottom, 48)
    }
}

private struct QRCameraView: UIViewRepresentable {
    @Binding var torchOn: Bool
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    func makeUIView(context: Context) -> _CameraUIView {
        let view = _CameraUIView()
        view.delegate = context.coordinator
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: _CameraUIView, context: Context) {
        uiView.setTorch(torchOn)
    }

    static func dismantleUIView(_ uiView: _CameraUIView, coordinator: Coordinator) {
        uiView.stopSession()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        private var scanned = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !scanned,
                  let obj = objects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue, !value.isEmpty else { return }
            scanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            DispatchQueue.main.async { self.onScan(value) }
        }
    }
}

final class _CameraUIView: UIView {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func startSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        session.stopRunning()
        setTorch(false)
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch,
              (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}
