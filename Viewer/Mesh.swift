//  Created by Jeff Biggus sometime in July, 2015.
//  Copyright © 2015 HyperJeff, Inc. All rights reserved.
//  Based on Apple's MetalKitEssentialsUsingtheMetalKitViewTextureLoaderandModelIO project.

import Foundation
import MetalKit
import GLKit

enum AAPLVertexAttribute: Int {
	case Position, Normal, Texcoord
}

enum AAPLTextureIndex: Int {
	case Diffuse
}

enum AAPLBufferIndex: Int {
	case MeshVertex, FrameUniform, MaterialUniform
}

struct AAPLFrameUniform {
	var model, view, projection, projectionView, normal, rotate, translate: GLKMatrix4
}

struct AAPLMaterialUniform {
	var emissiveColor, diffuseColor, specularColor: float4
	var specularIntensity: Float
	var pad1, pad2, pad3: Float
}

class Mesh {
	
	var mesh: MTKMesh?
	var submeshes: [Submesh] = []
	
	init(mesh newMesh: MTKMesh, mdlMesh: MDLMesh, device: MTLDevice) {
		mesh = newMesh
		for i in 0 ..< newMesh.submeshes.count {
			let submesh = Submesh(
				submesh: newMesh.submeshes[i],
				
				// possible radar: submeshes coming back as NSArray?
				
				mdlSubmesh: mdlMesh.submeshes[i] as! MDLSubmesh,
				device: device
			)
			submeshes.append(submesh)
		}
	}
	
	func renderWithEncoder(encoder: MTLRenderCommandEncoder) {
		if let mesh = mesh {
			var bufferIndex = 0
			for vertexBuffer in mesh.vertexBuffers {
				
				// possible radar: buffer is not an optional
				
				encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, atIndex: bufferIndex)
				bufferIndex += 1
			}
			
			//print("# of submeshes: \(submeshes.count)")
			for submesh in submeshes {
				submesh.renderWithEncoder(encoder)
			}
		}
	}
}

class Submesh {
	
	var materialUniforms: MTLBuffer?
	var diffuseTexture: MTLTexture?
	var submesh: MTKSubmesh?
	
	init(submesh newSubmesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, device: MTLDevice)
    {
		materialUniforms = device.newBufferWithLength(sizeof(AAPLMaterialUniform),
			options: MTLResourceOptions.CPUCacheModeDefaultCache)
		
		if let mu = materialUniforms {
            let matUniPtr = UnsafeMutablePointer<AAPLMaterialUniform>(mu.contents())
			var matUni = matUniPtr.memory
			
			submesh = newSubmesh
			
			if let material = mdlSubmesh.material {
				
                
				if let property = material.propertyNamed("baseColorMap") {
					if property.type == MDLMaterialPropertyType.String {
						if let fileString = property.stringValue {
							let fileLocation = "file://\(fileString)"
//							print(fileLocation)
							if let textureUrl = NSURL(string: fileLocation) {
								let textureLoader = MTKTextureLoader(device: device)
								do {
									diffuseTexture = try textureLoader.newTextureWithContentsOfURL(textureUrl, options: nil)
								} catch _ { print("diffuseTexture assignment failed") }
							}
						}
					}
				}
				
				else if let property = material.propertyNamed("specularColor") {
					if property.type == MDLMaterialPropertyType.Float4 {
						matUni.specularColor = property.float4Value
					}
					else if property.type == MDLMaterialPropertyType.Float3 {
						let color3 = property.float3Value
						matUni.specularColor = float4(color3.x, color3.y, color3.z, 1)
					}
				}
				
				else if let property = material.propertyNamed("emission") {
					if property.type == MDLMaterialPropertyType.Float4 {
                      //  matUni.specularColor = float4(0.4, 1, 1, 1)

                        matUni.emissiveColor = float4(0.3, 0.3, 0.3, 1)
                       // matUni.emissiveColor = property.float4Value
					}
					else if property.type == MDLMaterialPropertyType.Float3 {
						let color3 = property.float3Value
						matUni.emissiveColor = float4(color3.x, color3.y, color3.z, 1)
					}
				}
                matUniPtr.memory = matUni

			}
		}
	}
	
	func renderWithEncoder(encoder: MTLRenderCommandEncoder) {
		if let dt = diffuseTexture {
			encoder.setFragmentTexture(dt, atIndex: AAPLTextureIndex.Diffuse.rawValue)
		}
		
		if let mat = materialUniforms {
			let index = AAPLBufferIndex.MaterialUniform.rawValue
            
			encoder.setFragmentBuffer(mat, offset: 0, atIndex: index)
			encoder.setVertexBuffer(mat, offset: 0, atIndex: index)
		}
		
		if let sub = submesh {
			encoder.drawIndexedPrimitives(sub.primitiveType,
				indexCount: sub.indexCount,
				indexType: sub.indexType,
				indexBuffer: sub.indexBuffer.buffer,
				indexBufferOffset: sub.indexBuffer.offset)
		}
	}
    
    
}