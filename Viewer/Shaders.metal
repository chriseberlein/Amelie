/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal shaders
 */

#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_texture>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_graphics>

using namespace simd;

enum AAPLVertexAttributes {
    AAPLVertexAttributePosition = 0,
    AAPLVertexAttributeNormal   = 1,
    AAPLVertexAttributeTexcoord = 2,
};
    
enum AAPLTextureIndex {
    AAPLDiffuseTextureIndex = 0
};
        
enum AAPLBufferIndex  {
    AAPLMeshVertexBuffer      = 0,
    AAPLFrameUniformBuffer    = 1,
    AAPLMaterialUniformBuffer = 2,
};
            
struct AAPLFrameUniforms {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
    float4x4 projectionView;
    float4x4 normal;
    float4x4 rotate;
    float4x4 translate;
};
    
struct AAPLMaterialUniforms {
    float4 emissiveColor;
    float4 diffuseColor;
    float4 specularColor;
                
    float specularIntensity;
    float pad1;
    float pad2;
    float pad3;
};
            
    
// Variables in constant address space.
constant float3 lightPosition = float3(0.0, 4.0, -2.0);
            
            // Per-vertex input structure
            struct VertexInput {
                float3 position [[attribute(AAPLVertexAttributePosition)]];
                float3 normal   [[attribute(AAPLVertexAttributeNormal)]];
                half2  texcoord [[attribute(AAPLVertexAttributeTexcoord)]];
            };
            
            // Per-vertex output and per-fragment input
            typedef struct {
                float4 position [[position]];
                half2  texcoord;
                half4  color;
            } ShaderInOut;
            
            
            // Per-vertex input structure
            struct VertexStlInput {
                float3 position [[attribute(AAPLVertexAttributePosition)]];
                float3 normal   [[attribute(AAPLVertexAttributeNormal)]];
                float4 color    [[attribute(AAPLVertexAttributeTexcoord)]];
            };
            
            // Per-vertex output and per-fragment input
            typedef struct {
                float4 position [[position]];
                float4  color;
            } ShaderStlInOut;
            
            
            
            
            
            
// Vertex shader function
vertex ShaderStlInOut vertexStl(VertexStlInput in [[stage_in]],
                constant AAPLFrameUniforms& frameUniforms [[ buffer(AAPLFrameUniformBuffer) ]],
                constant AAPLMaterialUniforms& materialUniforms [[ buffer(AAPLMaterialUniformBuffer) ]])
{
    
    ShaderStlInOut out;
    
                
    float4x4 mv_Matrix = frameUniforms.view;
                
    float4x4 mv_Matrix2 = frameUniforms.projectionView;
                
    
    // Vertex projection and translation
    float4 in_position = float4(in.position, 1.0);
    float4 in_normal = float4(in.normal, 0.0);
    
    out.position = frameUniforms.translate * frameUniforms.normal * frameUniforms.rotate * frameUniforms.view * in_position ;
    out.position[2] =   out.position[2] * 0.001 + 0.1 ;

    // Per vertex lighting calculations
    float4 eye_normal = normalize(frameUniforms.rotate * in_normal);
    float n_dot_l = dot(eye_normal.rgb, normalize(lightPosition)) * 0.7;
    n_dot_l = fmax(0.0, n_dot_l);
                
    out.color = float4(in.color)+ n_dot_l;
                
    return out;
}
            
// Fragment shader function
fragment half4 fragmentStl(ShaderStlInOut in [[stage_in]]) {
                
    // Blend texture color with input color and output to framebuffer
    half4 color =  half4(in.color[0],in.color[1],in.color[2],in.color[3]);
                
    return color;
}
