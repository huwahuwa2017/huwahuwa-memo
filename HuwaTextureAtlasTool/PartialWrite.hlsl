#include "UnityCG.cginc"

struct I2V
{
    float4 lPos : POSITION;
    float2 uv : TEXCOORD0;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

SamplerState sampler_MainTex;
Texture2D _MainTex;
float4 _ScaleAndOffset;

uint _Width;
uint _Height;
uint _Index;
bool _IsNormalMap;
//bool _SRGB;

V2F VertexShaderStage(I2V input)
{
    float4 cPos = UnityObjectToClipPos(input.lPos);
    
    cPos.y *= _ProjectionParams.x;
    cPos.xy = cPos.xy * 0.5 + 0.5;
    cPos.xy = (cPos.xy + float2(_Index % _Width, _Index / _Width)) / float2(_Width, _Height);
    cPos.xy = cPos.xy * 2.0 - 1.0;
    cPos.y *= _ProjectionParams.x;
    
    V2F output = (V2F) 0;
    output.cPos = cPos;
    output.uv = input.uv;
    return output;
}

float4 FragmentShaderStage(V2F input) : SV_Target
{
    float2 uv = input.uv * _ScaleAndOffset.xy + _ScaleAndOffset.zw;
    
    float4 color = _MainTex.Sample(sampler_MainTex, uv);
    float3 normal = UnpackNormal(color) * 0.5 + 0.5;
    color = _IsNormalMap ? float4(normal, 1.0) : color;
    
    /*
#if !defined(UNITY_COLORSPACE_GAMMA)
    color.rgb = _SRGB ? color.rgb : GammaToLinearSpace(color.rgb);
#endif
    */
    
    return color;
}
