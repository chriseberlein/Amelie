//
//  ViewController.swift
//  Viewer
//
//  Created by Christian Eberlein on 10.09.2016.
//  Copyright © 2016 Christian Eberlein. All rights reserved.
//

import Cocoa
import MetalKit
import GLKit

let AAPLBuffersInFlightBuffers = 3

enum AAPLViews: Int {
    case Front, Right, Top
}

class ViewController: NSViewController, MTKViewDelegate {
    var mtkview: MTKView!
    
    var inflightSemaphore: dispatch_semaphore_t!
    var constantDataBufferIndex = 0

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var defaultLibrary: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!
    var depthState: MTLDepthStencilState!

    
    var windowcontroller:WindowController!
    var document:Document!
    var meshes: [Mesh] = []
    var frameUniformBuffers: [MTLBuffer] = []


    var object:Object!
    var object2:Object!
    var test:Int = 1
    
    var zoom:Float = 1.0
    var translate:GLKMatrix4 = GLKMatrix4Identity
    var rotate:GLKMatrix4 = GLKMatrix4Identity
    var rotate2:GLKMatrix4 = GLKMatrix4Identity
    var newrotate:GLKMatrix4 = GLKMatrix4Identity
    var diffrotate:GLKMatrix4 = GLKMatrix4Identity
    
    var translate1:GLKMatrix4 = GLKMatrix4Identity
    var translate2:GLKMatrix4 = GLKMatrix4Identity
    var lastpoint:NSPoint = NSPoint(x: 0, y: 0)
    var newview:AAPLViews = AAPLViews.Front
    var nxr:Float = 0.0, nyr:Float = 0.0, nzr:Float = 0.0

    var counter:Int = 0
    var test2:Int = 0
    var test3:float4 = float4(0,0,0,0)
    
    func setnewView(new: AAPLViews)
    {
//        xr = atan2(rotate2.m21, rotate2.m22)
//        yr = atan2(-rotate2.m20, sqrt(rotate2.m21*rotate2.m21+rotate2.m22*rotate2.m22) )
//        zr = atan2(rotate2.m10, rotate2.m00)
        
        
//        print("asdf")
//        for i in 0 ..< 16
//        {
//            print(String(rotate2[i]))
//        }
//        print("fsa")
//        print(String(xr)+" "+String(yr)+" "+String(zr))
//        newview = new
        if (new == AAPLViews.Front)
        {
            newrotate = GLKMatrix4Identity

            nxr = 0//atan2(newrotate.m21, newrotate.m22)
            nyr = 0//atan2(-newrotate.m20, sqrt(newrotate.m21*newrotate.m21+newrotate.m22*newrotate.m22) )
            nzr = 0//atan2(newrotate.m10, newrotate.m00)

        }
        else if (new == AAPLViews.Right)
        {
            newrotate = GLKMatrix4MakeYRotation(Float(M_PI_2))
            
            nxr = 0//atan2(newrotate.m21, newrotate.m22)
            nyr = -Float(M_PI_2)//atan2(-newrotate.m20, sqrt(newrotate.m21*newrotate.m21+newrotate.m22*newrotate.m22) )
            nzr = 0//atan2(newrotate.m10, newrotate.m00)
//            nxr = 0// atan2(newrotate.m21, newrotate.m22)
//            nyr = // atan2(-newrotate.m20, sqrt(newrotate.m21*newrotate.m21+newrotate.m22*newrotate.m22) )
//            nzr = 0//atan2(newrotate.m10, newrotate.m00)
        }
        else if (new == AAPLViews.Top)
        {
            newrotate = GLKMatrix4MakeXRotation(Float(-M_PI_2))
            
            
            nxr = Float(M_PI_2)
            nyr = 0//atan2(-newrotate.m20, sqrt(newrotate.m21*newrotate.m21+newrotate.m22*newrotate.m22) )
            nzr = 0//atan2(newrotate.m10, newrotate.m00)
        }
        test3 = toAxisAngle(rotate2)
        
//        let matrix = newrotate
//        if(abs(matrix.m20) < 1)
//        {
//            nyr = -asin(matrix.m20)
//            nxr = atan2(matrix.m21/cos(nyr), matrix.m22/cos(nyr))
//            nzr = atan2(matrix.m10/cos(nyr), matrix.m00/cos(nyr))
//            
//        }
//        else{
//            nzr = 0.0
//            if(matrix.m20 == -1)
//            {
//                nyr = Float(M_PI_2)
//                nxr = atan2(matrix.m01, matrix.m02)
//            } else
//            {
//                nyr = -Float(M_PI_2)
//                nxr = atan2(-matrix.m01, -matrix.m02)
//            }
//        }
        

    //    diffrotate = GLKMatrix4Scale(GLKMatrix4Subtract(newrotate, rotate2), 0.01, 0.01, 0.01)
        counter = 0
        test2 = 1
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank NSView, an application could also fallback to OpenGL here.
            print("Metal is not supported on this device")
            self.view = NSView(frame: self.view.frame)
            return
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
        
    }
    override func viewDidAppear() {
        windowcontroller = self.view.window!.windowController as! WindowController
        windowcontroller.viewController = self
        document = windowcontroller.document as! Document
        
        inflightSemaphore = dispatch_semaphore_create(AAPLBuffersInFlightBuffers)
        
        setupMetal()
        
        setupView()
        load()
        
        reshape()
    }
    
    
    
    func setupMetal() {
        
        commandQueue = device.newCommandQueue()
        defaultLibrary = device.newDefaultLibrary()
    }
    
    func setupView() {
        guard let mView = self.view as? MTKView else { print("fail in setupView"); return }
        mView.delegate = self
        mView.device = device
        mView.sampleCount = 4
        mView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        
        mtkview = mView
    }
    
    func refit()
    {
        if((object.maxx - object.minx) > (object.maxy - object.miny) * Float(view.frame.width / view.frame.height) )
        {
            zoom = (2 / (object.maxx - object.minx) ) * Float(view.frame.width / view.frame.height) * 0.9
        }
        else
        {
            zoom = 2 / (object.maxy - object.miny) * 0.9
        }
    }
    
    func load(){

        object = Object(newlibrary: defaultLibrary, path: document.url)
        object2 = Object(newlibrary: defaultLibrary, path: document.url)
        translate1 = GLKMatrix4MakeTranslation(-object.middlex, -object.middley, -object.middlez)
        
        // resizes object to fit in window
        refit()
        
        
        let pipelineStateDestriptor = MTLRenderPipelineDescriptor()
        pipelineStateDestriptor.label = "MyPipeline"
        pipelineStateDestriptor.sampleCount = mtkview.sampleCount
        pipelineStateDestriptor.vertexFunction = object.vertexProgram!
        pipelineStateDestriptor.fragmentFunction = object.fragmentProgram!
        pipelineStateDestriptor.vertexDescriptor = object.mtlVertexDescriptor
        pipelineStateDestriptor.colorAttachments[0].pixelFormat = mtkview.colorPixelFormat
        pipelineStateDestriptor.depthAttachmentPixelFormat = mtkview.depthStencilPixelFormat
        pipelineStateDestriptor.stencilAttachmentPixelFormat = mtkview.depthStencilPixelFormat
        
        do { pipelineState = (try device.newRenderPipelineStateWithDescriptor(pipelineStateDestriptor)) }
        catch _ {
            print("Failed to create pipeline state")
            return
        }
        
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = MTLCompareFunction.LessEqual
        depthStateDesc.depthWriteEnabled = true
        depthState = device.newDepthStencilStateWithDescriptor(depthStateDesc)
        
        
        for _ in 0 ..< AAPLBuffersInFlightBuffers {
            frameUniformBuffers.append(device.newBufferWithLength(
                sizeof(AAPLFrameUniform),
                options: MTLResourceOptions.CPUCacheModeDefaultCache // = 0 rawValue
                ))
        }
        
    }
    func update() {
        let frameContentsPointer = UnsafeMutablePointer<AAPLFrameUniform>(
            frameUniformBuffers[constantDataBufferIndex].contents()
        )
        var frameData = frameContentsPointer.memory
        
        frameData.model = GLKMatrix4Identity
        frameData.rotate = rotate
        
        frameData.normal = translate
        frameData.view = translate1
        frameData.translate = translate2
   /*     frameData.view = GLKMatrix4Multiply(translatef, rotatef)
        
        let modelViewMatrix = GLKMatrix4Multiply(frameData.view,frameData.model)

        frameData.projectionView = GLKMatrix4Multiply(projectionMatrix , modelViewMatrix)
        
        frameData.normal = GLKMatrix4Invert(GLKMatrix4Transpose(modelViewMatrix), nil)
        
        frameData.rotate = rotate
        frameData.translate = translate*/
        
        frameContentsPointer.memory = frameData

    }
    
    func render() {
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        update()
        
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.label = "Main Command Buffer"
        
        if let currentDrawable = mtkview.currentDrawable,
            renderPassDescriptor = mtkview.currentRenderPassDescriptor {
            
            renderPassDescriptor.colorAttachments[0].loadAction = .Clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.7, 0.7, 0.7, 1)
            
            let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            renderEncoder.label = "Final Pass Encoder"
            renderEncoder.setViewport(MTLViewport(
                originX: 0, originY: 0,
                width:  Double(mtkview.drawableSize.width),
                height: Double(mtkview.drawableSize.height),
                znear: 0, zfar: 1)
            )
            renderEncoder.setDepthStencilState(depthState)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(
                frameUniformBuffers[constantDataBufferIndex],
                offset: 0, atIndex: AAPLBufferIndex.FrameUniform.rawValue
            )
            
            
            renderEncoder.pushDebugGroup("Render Objects")
            
            renderEncoder.setTriangleFillMode(.Fill)

            object.renderWithEncoderColor(renderEncoder)
            
            //renderEncoder.setTriangleFillMode(.Lines)
            //object2.renderWithEncoderWhite(renderEncoder)

            
            renderEncoder.setCullMode(MTLCullMode.Front)
            renderEncoder.popDebugGroup()
            
            
            renderEncoder.endEncoding()
            
            let block_sema = inflightSemaphore
            commandBuffer.addCompletedHandler { (buffer) -> Void in
                dispatch_semaphore_signal(block_sema)
            }
            
            constantDataBufferIndex = (constantDataBufferIndex + 1) % AAPLBuffersInFlightBuffers
            
            commandBuffer.presentDrawable(currentDrawable)
            commandBuffer.commit()
        }
    }
    override func mouseDown(theEvent: NSEvent) {
        lastpoint = theEvent.locationInWindow
    }
    
    override func mouseUp(theEvent: NSEvent) {
        
    }
    
    func reshape() {
     //   rotate = GLKMatrix4Scale(rotate2, zoom, zoom * Float(view.frame.width / view.frame.height), zoom)
            let scale = GLKMatrix4MakeScale(Float(view.frame.height / view.frame.width), 1, 1)
            rotate = GLKMatrix4Multiply(scale, rotate2)
        
        translate2 = GLKMatrix4MakeScale(zoom,zoom,zoom)
        
    }
    func updaterotate()
    {
        let cou = 30
        if counter < cou
        {
           // if(counter == 0)
            //{
                 diffrotate = GLKMatrix4Scale(GLKMatrix4Subtract(rotate2 ,newrotate ), 1/Float(cou-counter), 1/Float(cou-counter), 1/Float(cou-counter))
                
                //            var yr = -asin(diffrotate.m02)
                var yr:Float = 0.0
                var zr:Float = 0.0
                var xr:Float = 0.0
                var yr2:Float = 0.0
                var zr2:Float = 0.0
                var xr2:Float = 0.0
                //
                //            var xr = Float(0.0)
                //            // let yr = atan2(-rotate2.m20, sqrt(rotate2.m21*rotate2.m21+rotate2.m22*rotate2.m22) )
                //           // var yr = Float(0.0)
                //            var zr = Float(0.0)
                
                let matrix = rotate2
                
//                if(abs(matrix.m20) < 1)
//                {
//                    
//                    yr = -asin(matrix.m20)
//                    xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
//                    zr = atan2(matrix.m10/cos(yr), matrix.m00/cos(yr))
//                    
//                }
//                else{
//                    zr = 0.0
//                    if(matrix.m20 == -1)
//                    {
//                        yr = Float(M_PI_2)
//                        xr = atan2(matrix.m01, matrix.m02)
//                    } else
//                    {
//                        yr = -Float(M_PI_2)
//                        xr = atan2(-matrix.m01, -matrix.m02)
//                    }
//                }
            if(abs(matrix.m20) != 1)
            {
                yr = -asin(matrix.m20)
                yr2 = Float(M_PI) - yr
                xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
                xr2 = atan2(matrix.m21/cos(yr2), matrix.m22/cos(yr2))
                zr = atan2(matrix.m10/cos(yr), matrix.m00/cos(yr))
                zr2 = atan2(matrix.m10/cos(yr2), matrix.m00/cos(yr2))
                
                if(abs(xr)+abs(yr)+abs(zr) > abs(xr2)+abs(yr2)+abs(zr2))
                {
                    print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2) + " 2")

                    xr = xr2
                    yr = yr2
                    zr = zr2

               //     print(String(2))
                }
                else{
                    
                    print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2) + " 1")
                }
            }
            else
            {
                yr = Float(M_PI_2)
                xr = atan2(matrix.m10, matrix.m11)
                zr = 0
                print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2) + " 3")
            }

            
            
            if(yr > Float(M_PI))
            {
                yr = Float(M_2_PI) - yr
            }
            
            
            let dxr = nxr - xr
            let dyr = nyr - yr
            let dzr = nzr - zr
//            rotate2 = GLKMatrix4RotateX(rotate2, dxr/Float(cou-counter))
//            rotate2 = GLKMatrix4RotateY(rotate2, dyr/Float(cou-counter))
//            rotate2 = GLKMatrix4RotateZ(rotate2, dzr/Float(cou-counter))
            //rotate2 = GLKMatrix4Rotate(
            rotate2 = GLKMatrix4Rotate(rotate2, test3.w/cou, test3.x, test3.y, test3.z)
            
            
          //  rotate2 = GLKMatrix4Rotate
            
            
//            }
//            else
//            {
//                diffrotate = GLKMatrix4Identity
//            }
          

//            rotate2 = GLKMatrix4Add(diffrotate, rotate2)
            counter = counter + 1
        }
        else
        {
            counter = 0
            rotate2 = newrotate
            test2 = 0
        }
        reshape()
    }
    
    func drawInMTKView(view: MTKView) {
        if(test2 == 0)
        {
            if test == 1{
                render()
                test = 0
            }
        }
        else
        {
            updaterotate()
            render()
        }
    }
    
    
    
    
    
    
    
    
    func toAxisAngle(matrix:GLKMatrix4) -> float4
    {
//        // variables for result
//        var angle:Float, x:Float, y:Float, z:Float
//        var epsilon:Float = 0.01// margin to allow for rounding errors
//        var epsilon2:Float = 0.1// margin to distinguish between 0 and 180 degrees
//        if ((abs(matrix.m01 - matrix.m10) < epsilon)
//            && (abs(matrix.m02 - matrix.m20) < epsilon)
//            && (abs(matrix.m12 - matrix.m21) < epsilon))
//        {
//            // singularity found
//            // first check for identity matrix which must have +1 for all terms
//            //  in leading diagonaland zero in other terms
//            if ((abs(matrix.m01 + matrix.m10) < epsilon2)
//                && (abs(matrix.m02 + matrix.m20) < epsilon2)
//                && (abs(matrix.m12 + matrix.m21) < epsilon2)
//                && (abs(matrix.m00 + matrix.m11 + matrix.m22 - 3) < epsilon2))
//            {
//                
//                // this singularity is identity matrix so angle = 0
//                return float4(0,1,0,0)// zero angle, arbitrary axis
//            }
//            // otherwise this singularity is angle = 180
//            angle = Float(M_PI)
//            let xx = (matrix.m00+1)/2;
//            let yy = (matrix.m11+1)/2;
//            let zz = (matrix.m22+1)/2;
//            let xy = (matrix.m01+matrix.m10)/4;
//            let xz = (matrix.m02+matrix.m20)/4;
//            let yz = (matrix.m12+matrix.m21)/4;
//            if ((xx > yy) && (xx > zz)) { // m[0][0] is the largest diagonal term
//                if (xx < epsilon) {
//                    x = 0;
//                    y = 0.7071;
//                    z = 0.7071;
//                } else {
//                    x = sqrt(xx);
//                    y = xy/x;
//                    z = xz/x;
//                }
//            } else if (yy > zz) { // m[1][1] is the largest diagonal term
//                if (yy < epsilon) {
//                    x = 0.7071;
//                    y = 0;
//                    z = 0.7071;
//                } else {
//                    y = sqrt(yy);
//                    x = xy/y;
//                    z = yz/y;
//                }
//            } else { // m[2][2] is the largest diagonal term so base result on this
//                if (zz < epsilon) {
//                    x = 0.7071;
//                    y = 0.7071;
//                    z = 0;
//                } else {
//                    z = sqrt(zz);
//                    x = xz/z;
//                    y = yz/z;
//                }
//            }
//            return float4(angle,x,y,z); // return 180 deg rotation
//        }
//        // as we have reached here there are no singularities so we can handle normally
//        var s = sqrt((matrix.m21 - matrix.m12) * (matrix.m21 - matrix.m12) + (matrix.m02 - matrix.m20) * (matrix.m02 - matrix.m20) + (matrix.m10 - matrix.m01) * (matrix.m10 - matrix.m01)); // used to normalise
//        if (abs(s) < 0.001)
//        {
//            s = 1
//        }
//        // prevent divide by zero, should not happen if matrix is orthogonal and should be
//        // caught by singularity test above, but I've left it in just in case
//        angle = acos(( matrix.m00 + matrix.m11 + matrix.m22 - 1)/2);
//        x = (matrix.m21 - matrix.m12)/s;
//        y = (matrix.m02 - matrix.m20)/s;
//        z = (matrix.m10 - matrix.m01)/s;
//        return float4(angle,x,y,z);
        
        
        return float4(0,0,0,0)
    }
    
    


    
    
    
    
    
    
    
    
    
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        reshape()
        test = 1
    }
    override func mouseDragged(theEvent: NSEvent) {

        let asdf = toAxisAngle(rotate2)
        print(String(asdf.x) + " " + String(asdf.y) + " " + String(asdf.z) + " " + String(asdf.w))
        let diff = NSPoint(x:theEvent.locationInWindow.x - lastpoint.x, y: theEvent.locationInWindow.y - lastpoint.y)
        lastpoint = theEvent.locationInWindow
        var lastrotate = rotate2
        if theEvent.modifierFlags.contains(.ShiftKeyMask)
        {
            //translate = GLKMatrix4Translate(translate, Float(diff.x) * 2 / Float(view.frame.width), Float(diff.y) * 2 / Float(view.frame.height), 0.0)
            translate = GLKMatrix4Translate(translate, Float(diff.x) * 2 / (Float(view.frame.width) * zoom), Float(diff.y) * 2 / (Float(view.frame.height)  * zoom), 0.0)

        }
        else if theEvent.modifierFlags.contains(.CommandKeyMask)
        {
            let rot2 = GLKMatrix4MakeZRotation(Float(diff.y)/100)
            rotate2 = GLKMatrix4Multiply(rot2, rotate2)
        }
        else if theEvent.modifierFlags.contains(.ControlKeyMask)

        {
            let rot2 = GLKMatrix4MakeXRotation(Float(diff.y)/100)
            rotate2 = GLKMatrix4Multiply(rot2, rotate2)
        } else {
            let rot = GLKMatrix4MakeYRotation(-Float(diff.x)/100)
            rotate2 = GLKMatrix4Multiply(rot, rotate2)
        }
        diffrotate = GLKMatrix4Scale(GLKMatrix4Subtract(lastrotate, rotate2), 1/Float(60), 1/Float(60), 1/Float(60))
        
        //            var yr = -asin(diffrotate.m02)
//        var yr = -asin(diffrotate.m02)
//        var zr = acos(diffrotate.m00/cos(yr))
//        var xr = asin(diffrotate.m12/cos(yr))
        
        var xr = atan2(rotate2.m21, rotate2.m22)
        // let yr = atan2(-rotate2.m20, sqrt(rotate2.m21*rotate2.m21+rotate2.m22*rotate2.m22) )
        var yr = -asin(rotate2.m20)
        var zr = atan2(rotate2.m10, rotate2.m00)
        var xr2 = atan2(rotate2.m21, rotate2.m22)
        var yr2 = -asin(rotate2.m20)
        var zr2 = atan2(rotate2.m10, rotate2.m00)
        let matrix = rotate2
//        if(abs(matrix.m20) != 1)
//        {
//            yr = -asin(matrix.m20)
//            yr2 = Float(M_PI) - yr
//            xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
//            xr2 = atan2(matrix.m21/cos(yr2), matrix.m22/cos(yr2))
//            zr = atan2(matrix.m10/cos(yr), matrix.m00/cos(yr))
//            zr2 = atan2(matrix.m10/cos(yr2), matrix.m00/cos(yr2))
//        }
//        else
//        {
//            yr = Float(M_PI_2)
//            xr = atan2(matrix.m10, matrix.m11)
//            zr = 0
//        }
//        if(xr+yr+zr < xr2+yr2+zr2)
//        {
//            xr = xr2
//            yr = yr2
//            zr = zr2
//        }
//        if(yr > Float(M_PI))
//        {
//            yr = Float(M_2_PI) - yr
//        }
//        print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2))
//
//        if(abs(xr)+abs(yr)+abs(zr) > abs(xr2)+abs(yr2)+abs(zr2))
//        {
//            xr = xr2
//            yr = yr2
//            zr = zr2
//            print(String(2))
//        }
//        else{
//            print(String(1))
//        }

        
        
        
        if(abs(matrix.m20) != 1)
        {
            yr = -asin(matrix.m20)
            yr2 = Float(M_PI) - yr
            xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
            xr2 = atan2(matrix.m21/cos(yr2), matrix.m22/cos(yr2))
            zr = atan2(matrix.m10/cos(yr), matrix.m00/cos(yr))
            zr2 = atan2(matrix.m10/cos(yr2), matrix.m00/cos(yr2))
            
            if(abs(xr)+abs(yr)+abs(zr) > abs(xr2)+abs(yr2)+abs(zr2))
            {
                print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2) + " 2")

                xr = xr2
                yr = yr2
                zr = zr2
            }
            else{
                
                print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2) + " 1")
            }
        }
        else
        {
            yr = Float(M_PI_2)
            xr = atan2(matrix.m10, matrix.m11)
            zr = 0
            print(String(xr)+" "+String(yr)+" "+String(zr)+" "+String(xr2)+" "+String(yr2)+" "+String(zr2) + " 3")
        }
        
        
        
        if(yr > Float(M_PI))
        {
            yr = Float(M_2_PI) - yr
        }
       
        
        
        
        
        
        
        
        
        //        if(abs(matrix.m20) < 1)
//        {
//            yr = -asin(matrix.m20)
//            xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
//            if(xr > Float(M_PI_2))
//            {
//                yr = Float(M_PI_2)-yr
//                xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
//                if(xr > Float(M_PI_2))
//                {
//                    yr = Float(M_PI_2)-yr
//                    xr = atan2(matrix.m21/cos(yr), matrix.m22/cos(yr))
//                }
//            }
//            zr = atan2(matrix.m10/cos(yr), matrix.m00/cos(yr))
//            
//        }
//        else{
//            zr = 0.0
//            if(matrix.m20 == -1)
//            {
//                yr = Float(M_PI_2)
//                xr = atan2(matrix.m01, matrix.m02)
//            } else
//            {
//                yr = -Float(M_PI_2)
//                xr = atan2(-matrix.m01, -matrix.m02)
//            }
//        }
   //     print(String(rotate2.m00)+" "+String(rotate2.m01)+" "+String(rotate2.m02)+"; "+String(rotate2.m10)+" "+String(rotate2.m11)+" "+String(rotate2.m12)+"; "+String(rotate2.m20)+" "+String(rotate2.m21)+" "+String(rotate2.m22))
      //  rotate = GLKMatrix4Scale(rotate2, zoom, zoom * Float(view.frame.width / view.frame.height), zoom)
      //  let scale = GLKMatrix4MakeScale(zoom, zoom * Float(view.frame.width / view.frame.height), zoom)
    //    rotate = GLKMatrix4Multiply(scale, rotate2)
        reshape()
        test = 1
        test2 = 0
    }
    
    override func scrollWheel(theEvent: NSEvent) {
        zoom = zoom * (1.0 - (Float(theEvent.scrollingDeltaY) / (100)))
       // rotate = GLKMatrix4Scale(rotate2, zoom, zoom * Float(view.frame.width / view.frame.height), zoom)
    //    let scale = GLKMatrix4MakeScale(zoom, zoom * Float(view.frame.width / view.frame.height), zoom)
    //    rotate = GLKMatrix4Multiply(scale, rotate2)
        reshape()
        test = 1
        test2 = 0
    }

    override func rightMouseDown(theEvent: NSEvent) {
        rotate2 = GLKMatrix4Identity
        rotate = GLKMatrix4Identity
        translate = GLKMatrix4Identity
        refit()
        reshape()
        test = 1
        test2 = 0
    }
//    override func rightMouseUp(theEvent: NSEvent) {
//        if let window = windowcontroller.window, screen = window.screen {
//            let offsetFromLeftOfScreen: CGFloat = 50
//            let offsetFromTopOfScreen: CGFloat = 50
//            let width: CGFloat = 300
//            let height: CGFloat = 200
//            
//            let screenRect = screen.visibleFrame
//            let newOriginY = CGRectGetMaxY(screenRect) - height - offsetFromTopOfScreen            
//            window.setFrame(NSRect(x: offsetFromLeftOfScreen, y: newOriginY, width: width, height: height), display: true, animate: true)
//        }
//    }
}

