@preconcurrency import JavaScriptKit
import Chip8Emulator

// MARK: - Web Delegate

class WebDelegate: Chip8EngineDelegate {
    let ctx: JSObject
    let canvas: JSObject
    let pixelScale: Int = 10
    let screenWidth: Int = 64
    let screenHeight: Int = 32

    var isBeeping = false

    init(canvas: JSObject) {
        self.canvas = canvas
        self.ctx = canvas.getContext!("2d").object!
    }

    func render(screen: Chip8Screen) {
        let width = screenWidth
        let height = screenHeight
        let scale = pixelScale

        _ = ctx.clearRect!(0, 0, width * scale, height * scale)

        ctx.fillStyle = .string("#33ff33")
        for y in 0..<height {
            for x in 0..<width {
                let pixelAddress = y * width + x
                if screen.pixels[pixelAddress] == 1 {
                    _ = ctx.fillRect!(x * scale, y * scale, scale, scale)
                }
            }
        }
    }

    func beep() {
        guard !isBeeping else { return }
        isBeeping = true

        let AudioContext = JSObject.global.AudioContext.function!
        let actx = AudioContext.new()
        let osc = actx.createOscillator!().object!
        let gain = actx.createGain!().object!

        osc.type = .string("square")
        osc.frequency.value = .number(440)
        gain.gain.value = .number(0.1)

        _ = osc.connect!(gain)
        _ = gain.connect!(actx.destination)
        _ = osc.start!()

        let duration = 0.1
        _ = osc.stop!(actx.currentTime.number! + duration)

        _ = JSObject.global.setTimeout!(
            JSClosure { [weak self] _ in
                self?.isBeeping = false
                return .undefined
            },
            150
        )
    }
}

// MARK: - Keyboard Mapping

func mapKeyToChip8(_ key: String) -> Chip8InputCode? {
    switch key {
    case "1": return .one
    case "2": return .two
    case "3": return .three
    case "4": return .c
    case "q", "Q": return .four
    case "w", "W": return .five
    case "e", "E": return .six
    case "r", "R": return .d
    case "a", "A": return .seven
    case "s", "S": return .eight
    case "d", "D": return .nine
    case "f", "F": return .e
    case "z", "Z": return .a
    case "x", "X": return .zero
    case "c", "C": return .b
    case "v", "V": return .f
    default: return nil
    }
}

// MARK: - Globals

let document = JSObject.global.document
let canvas = document.getElementById("screen").object!
nonisolated(unsafe) let engine = Chip8Engine()
let webDelegate = WebDelegate(canvas: canvas)
nonisolated(unsafe) var animationFrameId: JSValue = .undefined
nonisolated(unsafe) var gameLoop: JSClosure!
let defaultTicksPerFrame = 7

// MARK: - Setup

engine.delegate = webDelegate

// Keyboard listeners
let keyDownHandler = JSClosure { args in
    guard let event = args.first?.object else { return .undefined }
    let key = event.key.string!
    if let chip8Key = mapKeyToChip8(key) {
        _ = event.preventDefault!()
        engine.handleKeyDown(key: chip8Key)
    }
    return .undefined
}

let keyUpHandler = JSClosure { args in
    guard let event = args.first?.object else { return .undefined }
    let key = event.key.string!
    if let chip8Key = mapKeyToChip8(key) {
        _ = event.preventDefault!()
        engine.handleKeyUp(key: chip8Key)
    }
    return .undefined
}

_ = document.addEventListener("keydown", keyDownHandler)
_ = document.addEventListener("keyup", keyUpHandler)

// MARK: - ROM Loading

func startEmulator(with romBytes: [UInt8]) {
    let ram = RomLoader.loadRam(from: romBytes)
    engine.start(with: ram)
    startGameLoop()
}

func loadRomFromJSArray(_ arrayBuffer: JSValue) {
    let uint8Array = JSObject.global.Uint8Array.function!.new(arrayBuffer)
    let length = Int(uint8Array.length.number!)
    var bytes = [UInt8](repeating: 0, count: length)
    for i in 0..<length {
        bytes[i] = UInt8(uint8Array[i].number!)
    }
    startEmulator(with: bytes)
}

// File input handler
let fileInput = document.getElementById("rom-file").object!
let fileChangeHandler = JSClosure { _ in
    let files = fileInput.files
    guard files.length.number! > 0 else { return .undefined }
    let file = files[0]
    let reader = JSObject.global.FileReader.function!.new()
    reader.onload = .object(JSClosure { _ in
        let result = reader.result
        loadRomFromJSArray(result)
        return .undefined
    }.jsValue.object!)
    _ = reader.readAsArrayBuffer!(file)
    return .undefined
}
_ = fileInput.addEventListener!("change", fileChangeHandler)

// Bundled ROM selector
let romSelect = document.getElementById("rom-select").object!
let romSelectHandler = JSClosure { _ in
    let value = romSelect.value.string!
    guard !value.isEmpty else { return .undefined }
    _ = JSObject.global.fetch!(value)
        .object!.then!(JSClosure { args in
            let response = args[0].object!
            return response.arrayBuffer!()
        })
        .object!.then!(JSClosure { args in
            loadRomFromJSArray(args[0])
            return .undefined
        })
    return .undefined
}
_ = romSelect.addEventListener!("change", romSelectHandler)

// MARK: - Game Loop

func startGameLoop() {
    let gameLoopClosure = JSClosure { _ in
        let ticks = Int(JSObject.global.chipTickRate.number ?? Double(defaultTicksPerFrame))
        for _ in 0..<ticks {
            engine.tick()
        }
        animationFrameId = JSObject.global.requestAnimationFrame!(gameLoop)
        return .undefined
    }
    gameLoop = gameLoopClosure
    animationFrameId = JSObject.global.requestAnimationFrame!(gameLoopClosure)
}

// Draw initial blank screen
let ctx = canvas.getContext!("2d").object!
ctx.fillStyle = .string("#000000")
_ = ctx.fillRect!(0, 0, 640, 320)

// Status message
let status = document.getElementById("status").object!
status.textContent = .string("Select a ROM to start playing")
