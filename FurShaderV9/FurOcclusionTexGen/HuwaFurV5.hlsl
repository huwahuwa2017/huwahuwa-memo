// v2 2025-01-05 16:11

#include "UnityCG.cginc"
#include "HuwaCellularNoise.hlsl"

struct I2V
{
    float4 lPos : POSITION;
    float3 lNormal : NORMAL;
    float4 lTangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float3 wPos : TEXCOORD0;
    float3 wTangent : TEXCOORD1;
    float3 wBinormal : TEXCOORD2;
    float2 uv : TEXCOORD3;
};

struct F2O
{
    float4 target0 : SV_Target0;
    float4 target1 : SV_Target1;
};

sampler2D _FurDirectionTex;
float4 _FurDirectionTex_TexelSize;

float _FurLength;
float _FurDensity;
int _BakeMode;

V2F VertexShaderStage_Skin(I2V input)
{
    float3 wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;
    
    float3 lNormal = input.lNormal;
    float3 lTangent = input.lTangent.xyz;
    float3 lBinormal = cross(lNormal, lTangent) * input.lTangent.w;
    
    float3 wNormal = UnityObjectToWorldNormal(lNormal);
    float3 wTangent = UnityObjectToWorldDir(lTangent);
    float3 wBinormal = cross(wNormal, wTangent) * (input.lTangent.w * unity_WorldTransformParams.w);
    
    float4 cPos1 = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
    cPos1.y *= _ProjectionParams.x;
    
    float4 cPos0 = UnityWorldToClipPos(wPos);
    
    float4 cPos = _BakeMode ? cPos1 : cPos0;
    
    V2F output = (V2F) 0;
    output.cPos = cPos;
    output.wPos = wPos;
    output.wTangent = wTangent;
    output.wBinormal = wBinormal;
    output.uv = input.uv;
    return output;
}

F2O FragmentShaderStage_Skin(V2F input)
{
    float3 wPos = input.wPos;
    float3 wTangent = input.wTangent;
    float3 wBinormal = input.wBinormal;
    
    float3 furDir = UnpackNormal(tex2Dlod(_FurDirectionTex, float4(input.uv, 0.0, 0.0)));
    furDir = normalize(wTangent * furDir.x + wBinormal * furDir.y);
    
    float d0;
    float d1;
    float3 c;
    float3 rp;
    
    float3 rayDir = -furDir;
    float3 rayPos = input.wPos * _FurDensity;
    
    float div = 64.0;
    float rcpDiv = rcp(div);
    
    float temp9 = _FurLength * _FurDensity;
    float temp1 = 0.0;
    
    for (float moving = rcpDiv; moving < 1.0; moving += rcpDiv)
    {
        CellularNoise(3, rayPos + rayDir * (moving * temp9), 0, d0, d1, c, rp);
        
        float val = saturate(1.0 - d0);
    
        val = val * val;
        val = val * val;
        val = val * val;
        val = val * val;
        val = val * val;
        
        val = val * sin(moving * UNITY_PI);
        
        temp1 = max(val, temp1);
    }
    
    F2O output = (F2O) 0;
    output.target0 = float4(temp1.xxx, 1.0);
    output.target1 = 1.0;
    return output;
}
