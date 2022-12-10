#define UNITY_MATRIX_I_M unity_WorldToObject

#include "UnityCG.cginc"

struct VertexData
{
    float4 pos : POSITION;
};

struct FragmentData
{
    float4 pos : SV_POSITION;
    float4 sPos : TEXCOORD0;
    float3 wPos : TEXCOORD1;
};

float4 _MainTex_ST;

sampler2D _MainTex;
sampler2D_float _CameraDepthTexture;

VertexData VertexStage(VertexData input)
{
    return input;
}

[maxvertexcount(3)]
void GeometryStage(point VertexData input[1], inout TriangleStream<FragmentData> stream)
{
    float posZ = -_ProjectionParams.y * 1.001;
    
    float4 pos0 = float4(40.0, -10.0, posZ, 1.0);
    float4 pos1 = float4(-40.0, -10.0, posZ, 1.0);
    float4 pos2 = float4(0.0, 30.0, posZ, 1.0);
    
    FragmentData output = (FragmentData) 0;
    
    output.pos = mul(UNITY_MATRIX_P, pos0);
    output.sPos = ComputeScreenPos(output.pos);
    output.wPos = mul(UNITY_MATRIX_I_V, pos0);
    stream.Append(output);
    
    output.pos = mul(UNITY_MATRIX_P, pos1);
    output.sPos = ComputeScreenPos(output.pos);
    output.wPos = mul(UNITY_MATRIX_I_V, pos1);
    stream.Append(output);
    
    output.pos = mul(UNITY_MATRIX_P, pos2);
    output.sPos = ComputeScreenPos(output.pos);
    output.wPos = mul(UNITY_MATRIX_I_V, pos2);
    stream.Append(output);
}

half4 FragmentStage(FragmentData input) : SV_Target
{
    float3 cameraViewDir = -UNITY_MATRIX_V._m20_m21_m22;
    float3 worldViewDir = normalize(_WorldSpaceCameraPos - input.wPos);
    float eyeDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, input.sPos).r);
    float3 wpos = worldViewDir * (eyeDepth / dot(cameraViewDir, worldViewDir)) + _WorldSpaceCameraPos;
    
    float3 lpos = mul(UNITY_MATRIX_I_M, float4(wpos, 1.0));
    
    float2 uv = lpos.xy + 0.5;
    half4 color = tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex));
    
    bool flag0 = uv.x < 0.0 | uv.x > 1.0 | uv.y < 0.0 | uv.y > 1.0;
    flag0 = flag0 | lpos.z < 0.0 | lpos.z > 1.0 | color.a == 0.0;
    
    clip(-flag0);
    
    return color;
}
