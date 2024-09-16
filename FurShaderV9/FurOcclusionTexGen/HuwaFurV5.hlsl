// Ver? 2023/11/18 12:34

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
sampler2D _FurLengthTex;

float4 _FurDirectionTex_TexelSize;
float4 _FurLengthTex_TexelSize;

float _FurLength;
float _FurDensity;
float _ColorPow;
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
    
    float furLength = tex2Dlod(_FurLengthTex, float4(input.uv, 0.0, 0.0)).r;
    furLength *= _FurLength;
    
    float d0;
    float d1;
    float3 c;
    float3 rp;
    
    float m = 9.9;
    
    float3 rayDir = -furDir;
    float3 rayPos = input.wPos * _FurDensity;
    
    float moving = 0.0;
    
    while (moving < (furLength * _FurDensity))
    {
        CellularNoise(1, rayPos, 0, d0, d1, c, rp);
        
        float temp0 = abs(dot(rayDir, rp));
        temp0 = (temp0 < 0.001) ? 0.01 : temp0;
        
        rayPos += rayDir * temp0;
        moving += temp0;
        
        m = min(m, d0);
    }
    
    float temp1 = pow(1.0 - saturate(m), _ColorPow);
    
    F2O output = (F2O) 0;
    output.target0 = float4(temp1.xxx, 1.0);
    output.target1 = 1.0;
    return output;
}
