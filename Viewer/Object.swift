//
//  object.swift
//  Viewer
//
//  Created by Christian Eberlein on 10.09.2016.
//  Copyright © 2016 Christian Eberlein. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import ModelIO

class Object:NSObject {
    
    var asset:MDLAsset!
    var device: MTLDevice!
    var library:MTLLibrary
    let fragmentProgram:MTLFunction?
    let vertexProgram:MTLFunction?
    var meshes: [Mesh] = []
    
    let mtlVertexDescriptor:MTLVertexDescriptor
    
    var minx:Float = 0.0, maxx:Float = 0.0, miny:Float = 0.0, maxy:Float = 0.0, minz:Float = 0.0, maxz:Float = 0.0
    
    var middlex:Float = 0
    var middley:Float = 0
    var middlez:Float = 0

    init(newlibrary:MTLLibrary, path:NSURL?)
    {
        library = newlibrary
        
        
        fragmentProgram = library.newFunctionWithName("fragmentStl")
        vertexProgram = library.newFunctionWithName("vertexStl")
        
        mtlVertexDescriptor = MTLVertexDescriptor()
        
        // hier wird der Vertex - Vektor erstellt, welcher an Shaders weitergegeben wird.
        var index = AAPLVertexAttribute.Position.rawValue
        mtlVertexDescriptor.attributes[index].format = .Float3
        mtlVertexDescriptor.attributes[index].offset = 0
        mtlVertexDescriptor.attributes[index].bufferIndex = AAPLBufferIndex.MeshVertex.rawValue
        
        index = AAPLVertexAttribute.Normal.rawValue
        mtlVertexDescriptor.attributes[index].format = .Float3
        mtlVertexDescriptor.attributes[index].offset = 12
        mtlVertexDescriptor.attributes[index].bufferIndex = AAPLBufferIndex.MeshVertex.rawValue
        
        index = AAPLVertexAttribute.Texcoord.rawValue
        mtlVertexDescriptor.attributes[index].format = .Float4
        mtlVertexDescriptor.attributes[index].offset = 24
        mtlVertexDescriptor.attributes[index].bufferIndex = AAPLBufferIndex.MeshVertex.rawValue
        
        index = AAPLBufferIndex.MeshVertex.rawValue
        mtlVertexDescriptor.layouts[index].stride = 40
        mtlVertexDescriptor.layouts[index].stepRate = 1
        mtlVertexDescriptor.layouts[index].stepFunction = MTLVertexStepFunction.PerVertex
        
        
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        
        let vertAttributePosition = mdlVertexDescriptor.attributes[0] as! MDLVertexAttribute
        vertAttributePosition.name = MDLVertexAttributePosition
        mdlVertexDescriptor.attributes[0] = vertAttributePosition
        
        let vertAttributeNormal = mdlVertexDescriptor.attributes[1] as! MDLVertexAttribute
        vertAttributeNormal.name = MDLVertexAttributeNormal
        mdlVertexDescriptor.attributes[1] = vertAttributeNormal
        
        let vertAttributeTex = mdlVertexDescriptor.attributes[2] as! MDLVertexAttribute
        vertAttributeTex.name = MDLVertexAttributeTextureCoordinate
        mdlVertexDescriptor.attributes[2] = vertAttributeTex
        
        let bufferAllocator = MTKMeshBufferAllocator(device: library.device)
        guard let assetURL = path else{
            print("Could not find asset.")
            return
        }
        
        
        asset = MDLAsset(URL: assetURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: bufferAllocator)
        
        
        
        let mtkMeshes: NSArray?
        var mdlMeshes: NSArray?
        
        do {
            mtkMeshes = try MTKMesh.newMeshesFromAsset(asset, device: library.device, sourceMeshes: &mdlMeshes)
        } catch {
            print("Failed to create mesh")
            return
        }
        
        meshes = []
        for index in 0 ..< mtkMeshes!.count {
            let mtkMesh: MTKMesh = mtkMeshes![index] as! MTKMesh
            let mdlMesh: MDLMesh = mdlMeshes![index] as! MDLMesh
            let newMesh = Mesh(mesh: mtkMesh, mdlMesh: mdlMesh, device: library.device)
            
            meshes.append(newMesh)
            
            let number = meshes[0].submeshes[0].submesh?.indexCount
            let pData = meshes[0].submeshes[0].submesh?.mesh?.vertexBuffers[0].buffer.contents()
            //         vertexBuffer.contents()
            let vData = UnsafeMutablePointer<Float>(pData!)
            let num:Int = number!
            for i in 0 ..< num
            {
                
                vData[10*i+6] = 0.0
                vData[10*i+7] = 0.0
                vData[10*i+8] = 0.3
                vData[10*i+9] = 1.0
            }
            minx = vData[0]
            maxx = vData[0]
            miny = vData[1]
            maxy = vData[1]
            minz = vData[2]
            maxz = vData[2]
            for k in 0 ..< num {
                
                if(vData[10*k] < minx)
                {
                    minx = vData[10*k]
                }
                if(vData[10*k] > maxx)
                {
                    maxx = vData[10*k]
                }

                if(vData[10*k+1] < miny)
                {
                    miny = vData[10*k+1]
                }
                if(vData[10*k+1] > maxy)
                {
                    maxy = vData[10*k+1]
                }
                
                if(vData[10*k+2] < minz)
                {
                    minz = vData[10*k+2]
                }
                if(vData[10*k+2] > maxz)
                {
                    maxz = vData[10*k+2]
                }
                
            }
            
            middlex = (minx + maxx) / 2
            middley = (miny + maxy) / 2
            middlez = (minz + maxz) / 2
            /*
            for i in 0 ..< num/3
            {
                
                vData[30*i+6] = 0.3
                vData[30*i+7] = 0.3
                vData[30*i+8] = 0.3
                vData[30*i+9] = 1.0
            }*/
//            for i in 0 ..< 100
//            {
//                print(String(vData[i]))
//            }
        }
        
    }
    
    func renderWithEncoder(encoder: MTLRenderCommandEncoder) {
        for mesh in meshes {
            mesh.renderWithEncoder(encoder)
        }
    }
    func renderWithEncoderWhite(encoder: MTLRenderCommandEncoder) {
        let number = meshes[0].submeshes[0].submesh?.indexCount
        let pData = meshes[0].submeshes[0].submesh?.mesh?.vertexBuffers[0].buffer.contents()
        //         vertexBuffer.contents()
        let vData = UnsafeMutablePointer<Float>(pData!)
        let num:Int = number!
        for i in 0 ..< num
        {
            
            vData[10*i+6] = 0.0
            vData[10*i+7] = 0.0
            vData[10*i+8] = 0.0
            vData[10*i+9] = 1.0
        }
        for mesh in meshes {
            mesh.renderWithEncoder(encoder)
        }
    }
    func renderWithEncoderColor(encoder: MTLRenderCommandEncoder) {
        let number = meshes[0].submeshes[0].submesh?.indexCount
        let pData = meshes[0].submeshes[0].submesh?.mesh?.vertexBuffers[0].buffer.contents()
        //         vertexBuffer.contents()
        let vData = UnsafeMutablePointer<Float>(pData!)
        let num:Int = number!
        for i in 0 ..< num
        {
            
            vData[10*i+6] = 0.0
            vData[10*i+7] = 0.0
            vData[10*i+8] = 0.3
            vData[10*i+9] = 1.0
        }
        for mesh in meshes {
            mesh.renderWithEncoder(encoder)
        }
    }
    
    

}