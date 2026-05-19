#define UNITY_PARTICLE_INSTANCE_DATA_NO_COLOR
#define UNITY_PARTICLE_INSTANCE_DATA_NO_ANIM_FRAME
#define UNITY_PARTICLE_INSTANCE_DATA MyParticleInstanceData

struct MyParticleInstanceData
{
    float3x4 transform;
    // uint color;
    // float animFrame;
    float agePercent;
    int particleIndex;
};

#include "UnityCG.cginc"
#include "UnityStandardParticleInstancing.cginc"
#include "HuwaRandomNumberGenerator.hlsl"

struct I2V
{
    float4 lPos : POSITION;
    float3 uv : TEXCOORD0; // uv.z is (height / width)
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float progress : TEXCOORD1;
    int particleIndex : TEXCOORD2;
};

Texture2D _MainTex;
float4 _MainTex_TexelSize;

static const float trailLength = 20.0;

float3x3 LookRotation(float3 fv, float3 uv)
{
    fv = normalize(fv);
    float3 rv = normalize(cross(uv, fv));
    uv = cross(fv, rv);

    return float3x3
    (
        rv.x, uv.x, fv.x,
        rv.y, uv.y, fv.y,
        rv.z, uv.z, fv.z
    );
}

V2F VertexShaderStage(I2V input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_PARTICLE_INSTANCE_DATA data = (UNITY_PARTICLE_INSTANCE_DATA) 0;
    
#if defined(UNITY_PARTICLE_INSTANCING_ENABLED)
    data = unity_ParticleInstanceData[unity_InstanceID];
#endif
    
    // パーティクルの中心座標 (ワールド座標系)
    float3 wCenter = data.transform._14_24_34;

    float3 wDirection = wCenter - _WorldSpaceCameraPos;
    wDirection.y = 0.0;
    float3x3 rot = LookRotation(wDirection, float3(0.0, 1.0, 0.0));
    
    // mul(data.transform, input.lPos) - wCenter
    // ↓
    // mul((float3x3) data.transform, input.lPos.xyz)
    
    float3 wPos = mul((float3x3) data.transform, input.lPos.xyz);
    wPos = mul(rot, wPos) + wCenter;
    
    // input.uv.z is (height / width)
    float progress = (1.0 - data.agePercent) * (input.uv.z + trailLength) - trailLength;

    V2F output = (V2F) 0;
    output.cPos = UnityWorldToClipPos(wPos);
    output.uv = input.uv.xy;
    output.progress = progress;
    output.particleIndex = data.particleIndex;
    return output;
}

half4 FragmentShaderStage(V2F input) : SV_Target
{
    float indexY = floor(input.uv.y);
    float progress = floor(input.progress);
    
    float temp2 = indexY - progress;
    bool temp3 = temp2 == 0.0;
    
    half4 color = half4(temp3, 1.0, temp3, 0.0);
    color.a = 1.0 - temp2 / trailLength;
    color.a = (temp2 < 0.0) ? 0.0 : color.a;
    
    uint seed = GenerateSeed(int2(indexY, input.particleIndex));
    uint random = GenerateUint(seed);
    
    uint2 index = uint2(frac(input.uv.xy) * 16.0);
    index.x += (random % 10) * 16;
    color.a *= _MainTex[index].r;
    
    clip(-(color.a <= 0.0));
    return color;
}
