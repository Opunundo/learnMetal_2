//
//  Shader.metal
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/4/25.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
    float animatedBy;
};

struct VertexIn {
    float4 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
    float2 textureCoordinates [[ attribute(2) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
    float2 textureCoordinates;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]]) {
    VertexOut vertexOut;
    vertexOut.position = vertexIn.position;
    vertexOut.color = vertexIn.color;
    vertexOut.textureCoordinates = vertexIn.textureCoordinates;
    
    return vertexOut;
}

fragment half4 fragment_shader(VertexOut vertexIn [[ stage_in ]]) {
    return half4(vertexIn.color);
}

fragment half4 fragment_grayShader(VertexOut vertexIn [[ stage_in ]]) {
    VertexOut vertexOut;
    
    float grayColor = (vertexIn.color.r*0.2126) + (vertexIn.color.g*0.7152) + (vertexIn.color.b*0.0722);
    
    vertexOut.color = float4(grayColor, grayColor, grayColor, vertexIn.color.a);
    
    return half4(vertexOut.color);
}

fragment half4 fragment_textureShader(VertexOut vertexIn [[ stage_in ]],
                                      sampler sampler2d [[ sampler(0)]],
                                      texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    float4 color = texture.sample(defaultSampler, vertexIn.textureCoordinates);
    return half4(color.r, color.g, color.b, vertexIn.color.a);
}

fragment half4 maskedTexture(VertexOut vertexIn [[ stage_in ]],
                            texture2d<float> texture [[ texture(0) ]],
                            texture2d<float> frameTexture [[ texture(1) ]]) {
    //샘플러(sampler)는 Metal에서 텍스처를 읽을 때 "어떻게" 읽을지를 결정
    //texture2d 자체는 이미지 데이터만 가지고 있고, 실제로 어떻게 보이는지는 shader 코드에서 샘플링 방식(sampler)과 좌표에 따라 결정됨
    constexpr sampler defaultSampler;
    float4 baseColor = texture.sample(defaultSampler, vertexIn.textureCoordinates);
    float4 maskColor = frameTexture.sample(defaultSampler, vertexIn.textureCoordinates);
    
    // 마스크 알파가 0이면 baseColor, 0보다 크면 maskColor 사용
    float maskAlpha = maskColor.a;
    float alphaThreshold = (maskAlpha > 0.001) ? 1.0 : 0.0;
    float3 outRGB = baseColor.rgb * (1.0 - alphaThreshold) + maskColor.rgb * alphaThreshold;
    float outAlpha = baseColor.a * (1.0 - alphaThreshold) + maskAlpha * alphaThreshold;
    
    return half4(outRGB.r, outRGB.g, outRGB.b, outAlpha);
}

