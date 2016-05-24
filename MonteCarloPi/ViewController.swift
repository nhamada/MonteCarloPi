//
//  ViewController.swift
//  MonteCarloPi
//
//  Created by Naohiro Hamada on 2016/05/25.
//  Copyright © 2016年 HaNoHito. All rights reserved.
//

import Cocoa
import Metal

struct Point {
    var x: Float
    var y: Float
}

class ViewController: NSViewController {
    
    let inputDataSize = 10_000_000

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        let start = NSDate()
        
        let metalConfiguration = initMetal()
        let inVector = prepareInputData(size: inputDataSize)
        guard let mcFunc = metalConfiguration.library.newFunction(withName: "monteCarloPi") else {
            abort()
        }
        guard let computePipelineState = try? metalConfiguration.device.newComputePipelineState(with: mcFunc) else {
            abort()
        }
        metalConfiguration.computeCommandEncoder.setComputePipelineState(computePipelineState)
        let inVectorBuffer = metalConfiguration.device.newBuffer(withBytes: inVector, length: inVector.byteLength, options: [])
        metalConfiguration.computeCommandEncoder.setBuffer(inVectorBuffer, offset: 0, at: 0)
        let outVector = [Bool](repeating: false, count: inVector.count)
        let outVectorBuffer = metalConfiguration.device.newBuffer(withBytes: outVector, length: outVector.byteLength, options: [])
        metalConfiguration.computeCommandEncoder.setBuffer(outVectorBuffer, offset: 0, at: 1)
        
        let threadsPerGroup = MTLSize(width: 32, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: (inVector.count + 31) / 32, height: 1, depth: 1)
        metalConfiguration.computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)

        metalConfiguration.computeCommandEncoder.endEncoding()
        metalConfiguration.commandBuffer.commit()
        metalConfiguration.commandBuffer.waitUntilCompleted()

        let data = NSData(bytesNoCopy: outVectorBuffer.contents(), length: outVector.byteLength, freeWhenDone: false)
        var finalResultArray = [Bool](repeating: false, count: outVector.count)
        data.getBytes(&finalResultArray, length: outVector.byteLength)
        
        let count = finalResultArray.reduce(0) {
            $1 ? $0 + 1 : $0
        }
        
        let pi = Double(4 * count) / Double(inputDataSize)
        
        let end = NSDate()
        let elapsed = end.timeIntervalSince(start)
        
        print(pi)
        print(elapsed)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func initMetal() -> (device: MTLDevice, commandQueue: MTLCommandQueue, library: MTLLibrary, commandBuffer: MTLCommandBuffer, computeCommandEncoder: MTLComputeCommandEncoder) {
        
        guard let device = MTLCreateSystemDefaultDevice(), defaultLibrary = device.newDefaultLibrary() else {
            abort()
        }
        let commandQueue = device.newCommandQueue()
        let commandBuffer = commandQueue.commandBuffer()
        let computeCommandEncoder = commandBuffer.computeCommandEncoder()
        return (device, commandQueue, defaultLibrary, commandBuffer, computeCommandEncoder)
    }

    private func prepareInputData(size: Int) -> [Point] {
        var dataSet = [Point]()
        for _ in 0..<size {
            let x = Float(arc4random_uniform(UInt32.max)) / Float(UInt32.max)
            let y = Float(arc4random_uniform(UInt32.max)) / Float(UInt32.max)
            dataSet.append(Point(x: x, y: y))
        }
        return dataSet
    }
}

private extension Array {
    var byteLength: Int {
        return self.count * sizeofValue(self[0])
    }
}
