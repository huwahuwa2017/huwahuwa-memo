
#include "UnityCG.cginc"

#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

struct I2V
{
    float4 lPos : POSITION;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float3 lPos : TEXCOORD0;
    float3 lCameraPos : TEXCOORD1;
};

struct F2O
{
    half4 color : SV_Target;
    float depth : SV_Depth;
};

half4 _Color;

V2F VertexShaderStage(I2V input)
{
    V2F output = (V2F) 0;
    output.cPos = UnityObjectToClipPos(input.lPos);
    output.lPos = input.lPos.xyz;
    output.lCameraPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    return output;
}

F2O FragmentShaderStage(V2F input)
{
    float3 lCameraPos = input.lCameraPos;
    float3 lRay = normalize(input.lPos - lCameraPos);

    float3 temp0 = -(lCameraPos - 0.5) / lRay;
    float3 temp1 = -(lCameraPos + 0.5) / lRay;
    float3 temp2 = min(temp0, temp1);
    float3 temp3 = max(temp0, temp1);
    
    // https://el-ement.com/blog/2017/08/16/primitives-ray-intersection/
    float temp4 = max(max(temp2.x, temp2.y), max(temp2.z, 0.0));
    float temp5 = min(min(temp3.x, temp3.y), temp3.z);

    clip(-(temp4 > temp5));

    float3 lPos = lCameraPos + lRay * temp4;
    float4 cPos = UnityObjectToClipPos(float4(lPos, 1.0));
    float depth = cPos.z / cPos.w;

#if defined(UNITY_REVERSED_Z)
    depth = (cPos.w <= 0.0) ? 1.0 : depth;
#else
    depth = (cPos.w <= 0.0) ? -1.0 : depth;
    depth = depth * 0.5 + 0.5;
#endif

    F2O output = (F2O) 0;
    output.color = _Color; //half4(lPos, 1.0);
    output.depth = depth;
    return output;
}
