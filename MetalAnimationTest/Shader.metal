//
//  Shader.metal
//  MetalAnimationTest
//
//  Created by 新川竜司 on 2025/03/29.
//

#include <metal_stdlib>
using namespace metal;

// **シンプルなフラクタルノイズ関数**
float random(float2 uv) {
    return fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
}

float noise(float2 uv) {
    float2 i = floor(uv);
    float2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// **FBM (フラクタルノイズ) を生成**
float fbm(float2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 2.0;
    
    for (int i = 0; i < 5; i++) {  // 5オクターブのノイズを合成
        value += amplitude * noise(uv * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// **頂点シェーダー**
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        {-1.0, -1.0}, {1.0, -1.0}, {-1.0, 1.0},
        {-1.0, 1.0}, {1.0, -1.0}, {1.0, 1.0}
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

// **フラグメントシェーダー**
fragment float4 fragmentShader(VertexOut in [[stage_in]], constant float &time [[buffer(0)]]) {
    // センターからの揺らぎ
    float2 center = float2(0.5, 0.5);
    float dist = distance(in.uv, center);

    // **ノイズを時間と座標に適用**
    float noiseValue = noise(in.uv * 5.0 + time * 0.5) * 0.05;

    // **ノイズを波紋に加える**
    float ripple = sin(dist * 20.0 - time * 4.0 + noiseValue) * 0.1;
    float intensity = smoothstep(0.3, 0.0, dist + ripple);

    // **リラックスできる緑色ベースの色に変更**
    float3 baseColor = float3(0.0, 0.6, 0.3); // 緑系 (R, G, B)
    return float4(baseColor * intensity, 1.0);

    return float4(0.0, 0.4, 1.0, 1.0) * intensity;
}
