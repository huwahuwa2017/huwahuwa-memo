// Ver1 2024-09-16 17:28

#define UNITY_MATRIX_I_M unity_WorldToObject

#include "HuwaLib/HuwaRandomFunction.hlsl"
#include "HuwaLib/HuwaTexelReadWrite.hlsl"
#include "HuwaLib/HuwaCascadeShadow.hlsl"
#include "HuwaSimpleLit.hlsl"

SamplerState sampler_MainTex;
SamplerState sampler_BumpMap;

Texture2D _MainTex;
float4 _MainTex_TexelSize;

Texture2D _BumpMap;
float4 _BumpMap_TexelSize;

Texture2D _MetallicGlossMap;
float4 _MetallicGlossMap_TexelSize;

half _OcclusionStrength;
Texture2D _OcclusionMap;
float4 _OcclusionMap_TexelSize;

float3 _EmissionColor;
Texture2D _EmissionMap;
float4 _EmissionMap_TexelSize;

float _FurOcclusionStrength;
Texture2D _FurOcclusionTex;
float4 _FurOcclusionTex_TexelSize;

Texture2D _FurColorTex;
float4 _FurColorTex_TexelSize;

Texture2D _FurDirectionTex;
float4 _FurDirectionTex_TexelSize;

Texture2D _FurLengthTex;
float4 _FurLengthTex_TexelSize;

Texture2D _FurCountTex;
float4 _FurCountTex_TexelSize;

Texture2D _FurBundleColorTex;
float4 _FurBundleColorTex_TexelSize;

float _FurLength;
float _FurX;
float _FurY;
float _FurSink;

float _FurRandomLength;
float _FurRandomDirectionXY;
float _FurRandomDirectionZ;
float _FurDensity;
float _FurAlphaCutoff;

static int _MaxFurCount = 25;
static int _MaxVertexCount = _MaxFurCount * 4;

static float _ShadowNormalOffset = 0.002;
static float _FurCulling = 0.5;
static float _LOD = 15.0;

// サンプラーを無視して処理速度を優先する
#define TEXTURE_READ(tex, uv) tex[uint2(frac(uv) * tex##_TexelSize.zw)]

struct I2V_Skin
{
    float4 lPos : POSITION;
    float3 lNormal : NORMAL;
    float4 lTangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct V2F_Skin
{
    float4 cPos : SV_POSITION;
    float3 wPos : TEXCOORD0;
    float3 wNormal : TEXCOORD1;
    float4 wTangent : TEXCOORD2;
    float2 uv : TEXCOORD3;
    half3 ambient : TEXCOORD4;
};

V2F_Skin VertexShaderStage_Skin(I2V_Skin input)
{
    float3 wPos = mul(UNITY_MATRIX_M, input.lPos);
    float4 cPos = UnityWorldToClipPos(wPos);
    float3 wNormal = UnityObjectToWorldNormal(input.lNormal);
    float3 wTangent = UnityObjectToWorldDir(input.lTangent.xyz);
    
    V2F_Skin output = (V2F_Skin) 0;
    output.cPos = cPos;
    output.wPos = wPos;
    output.wNormal = wNormal;
    output.wTangent = float4(wTangent, input.lTangent.w * unity_WorldTransformParams.w);
    output.uv = input.uv;
    output.ambient = max(0.0, ShadeSH9(half4(wNormal, 1.0)));
    return output;
}

half4 FragmentShaderStage_Skin(V2F_Skin input) : SV_Target
{
    float2 uv = input.uv;
    float3 wNormal = normalize(input.wNormal);
    float3 wTangent = normalize(input.wTangent.xyz);
    float3 wBinormal = cross(wNormal, wTangent) * input.wTangent.w;
    
    //float3 unpackNormal = UnpackScaleNormalRGorAG(TEXTURE_READ(_BumpMap, uv), _BumpScale);
    //unpackNormal = normalize(wTangent * unpackNormal.x + wBinormal * unpackNormal.y + wNormal * unpackNormal.z);
    
    float3 unpackNormal = UnpackNormal(_BumpMap.SampleLevel(sampler_BumpMap, uv, 0));
    unpackNormal = wTangent * unpackNormal.x + wBinormal * unpackNormal.y + wNormal * unpackNormal.z;
    
    half4 mainColor = _MainTex.Sample(sampler_MainTex, uv);
    half3 emissionColor = TEXTURE_READ(_EmissionMap, uv).rgb * _EmissionColor;
    half4 mg = TEXTURE_READ(_MetallicGlossMap, uv);
    half occlusion = lerp(1.0, TEXTURE_READ(_OcclusionMap, uv).g, _OcclusionStrength);
    
    half cascadeShadow = HuwaCascadeShadow(input.cPos.xy);
    
    half4 result = BRDF(input.wPos, unpackNormal, uv, mainColor, emissionColor, input.ambient, mg.r, mg.a, occlusion, cascadeShadow);
    
    float3 temp0 = TEXTURE_READ(_FurOcclusionTex, input.uv).rgb;
    float furOcclusion = max(max(temp0.r, temp0.g), temp0.b);
    furOcclusion = lerp(1.0, furOcclusion, _FurOcclusionStrength);
    
    return result * furOcclusion;
}



struct TessellationFactor_Fur
{
    float tessFactor[3] : SV_TessFactor;
    float insideTessFactor : SV_InsideTessFactor;
    float furCount : TEXCOORD0;
};

struct I2V_Fur
{
    float4 lPos : POSITION;
    float3 lNormal : NORMAL;
    float4 lTangent : TANGENT;
    float2 uv : TEXCOORD0;
    uint id : SV_VertexID;
};

struct V2G_Fur
{
    float3 wPos : TEXCOORD0;
    float3 wNormal : TEXCOORD1;
    float4 wTangent : TEXCOORD2;
    float2 uv : TEXCOORD3;
    half3 ambient : TEXCOORD4;
    float furCount : TEXCOORD5;
    uint random : TEXCOORD6;
};

struct G2F_Fur
{
    float4 cPos : SV_POSITION;
    half3 color : TEXCOORD0;
    half2 uv : TEXCOORD1;
    half furOcclusion : TEXCOORD2;
};

V2G_Fur VertexShaderStage_Fur(I2V_Fur input)
{
    float3 wPos = mul(UNITY_MATRIX_M, input.lPos);
    float3 wNormal = UnityObjectToWorldNormal(input.lNormal);
    float3 wTangent = UnityObjectToWorldDir(input.lTangent.xyz);
    half3 ambient = max(0.0, ShadeSH9(half4(wNormal, 1.0)));
    
    V2G_Fur output = (V2G_Fur) 0;
    output.wPos = wPos;
    output.wNormal = wNormal;
    output.wTangent = float4(wTangent, input.lTangent.w * unity_WorldTransformParams.w);
    output.uv = input.uv;
    output.ambient = ambient;
    output.random = input.id;
    return output;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("PatchConstantFunction_Fur")]
[outputcontrolpoints(3)]
V2G_Fur HullShaderStage_Fur(InputPatch<V2G_Fur, 3> input, uint id : SV_OutputControlPointID)
{
    return input[id];
}

TessellationFactor_Fur PatchConstantFunction_Fur(InputPatch<V2G_Fur, 3> input, uint primitiveID : SV_PrimitiveID)
{
    float3 wPos = (input[0].wPos + input[1].wPos + input[2].wPos) / 3.0;
    //            UnityWorldToClipPos(wPos).w;
    float cPosW = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0));
    float2 temp0 = _ScreenParams.xy * (abs(UNITY_MATRIX_P._m00_m11) / cPosW);
    float meterPerPixel = 1.0 / max(temp0.x, temp0.y);
    float temp1 = (_FurLength / meterPerPixel - 1.0) / (_LOD - 1.0);
    temp1 = isnan(temp1) ? 0.0 : temp1;
    temp1 = saturate(temp1);
    
    float furCount;
    HTRW_TEXEL_READ(_FurCountTex, primitiveID, furCount);
    furCount = furCount * _FurDensity * temp1;
    
    bool noTess = furCount <= _MaxFurCount;
    float requiredTessFactor = min(ceil(furCount / (_MaxFurCount * 3.0)), 64.0);
    float polygonCount = noTess ? 1.0 : requiredTessFactor * 3.0;
    
    TessellationFactor_Fur output = (TessellationFactor_Fur) 0;
    output.tessFactor[0] = requiredTessFactor;
    output.tessFactor[1] = requiredTessFactor;
    output.tessFactor[2] = requiredTessFactor;
    output.insideTessFactor = 2.0 - noTess;
    output.furCount = furCount / polygonCount;
    return output;
}

[domain("tri")]
V2G_Fur DomainShaderStage_Fur(TessellationFactor_Fur tf, const OutputPatch<V2G_Fur, 3> input, float3 bary : SV_DomainLocation)
{
    V2G_Fur output = (V2G_Fur) 0;
    output.wPos = bary.x * input[0].wPos + bary.y * input[1].wPos + bary.z * input[2].wPos;
    output.wNormal = bary.x * input[0].wNormal + bary.y * input[1].wNormal + bary.z * input[2].wNormal;
    output.wTangent = float4(bary.x * input[0].wTangent.xyz + bary.y * input[1].wTangent.xyz + bary.z * input[2].wTangent.xyz, input[0].wTangent.w);
    output.uv = bary.x * input[0].uv + bary.y * input[1].uv + bary.z * input[2].uv;
    output.ambient = bary.x * input[0].ambient + bary.y * input[1].ambient + bary.z * input[2].ambient;
    output.random = ValueToRandom(uint4(input[0].random, input[1].random, input[2].random, ValueToRandom(bary)));
    output.furCount = tf.furCount;
    return output;
}

[maxvertexcount(_MaxVertexCount)]
void GeometryShaderStage_Fur(triangle V2G_Fur input[3], inout TriangleStream<G2F_Fur> stream)
{
    float3 wPosition_Origin = input[0].wPos;
    float3 wPosition_0 = input[1].wPos - wPosition_Origin;
    float3 wPosition_1 = input[2].wPos - wPosition_Origin;
    
    float3 wNormal_Origin = input[0].wNormal;
    float3 wNormal_0 = input[1].wNormal - wNormal_Origin;
    float3 wNormal_1 = input[2].wNormal - wNormal_Origin;
    
    float3 wTangent_Origin = input[0].wTangent.xyz;
    float3 wTangent_0 = input[1].wTangent.xyz - wTangent_Origin;
    float3 wTangent_1 = input[2].wTangent.xyz - wTangent_Origin;
    
    float2 uv_Origin = input[0].uv;
    float2 uv_0 = input[1].uv - uv_Origin;
    float2 uv_1 = input[2].uv - uv_Origin;
    
    half3 ambient_Origin = input[0].ambient;
    half3 ambient_0 = input[1].ambient - ambient_Origin;
    half3 ambient_1 = input[2].ambient - ambient_Origin;
    
    float tangentW = input[0].wTangent.w;
    //float3 trueNormal = normalize(cross(wPosition_0, wPosition_1));
    
    uint random = ValueToRandom(uint3(input[0].random, input[1].random, input[2].random));
    int targetFurCount = input[0].furCount + RandomToFloatAbs(random);
    
    for (int count = 0; count < targetFurCount; ++count)
    {
        float2 moveFactor = float2(UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        moveFactor = float2(1.0 - max(moveFactor.x, moveFactor.y), min(moveFactor.x, moveFactor.y));
        
        float3 wPosition = wPosition_Origin + wPosition_0 * moveFactor.x + wPosition_1 * moveFactor.y;
        float3 wNormal = normalize(wNormal_Origin + wNormal_0 * moveFactor.x + wNormal_1 * moveFactor.y);
        
        if (dot(normalize(wPosition - _WorldSpaceCameraPos), wNormal) > _FurCulling)
            continue;
        
        float2 uv = uv_Origin + uv_0 * moveFactor.x + uv_1 * moveFactor.y;
        
        float3 lengthAndSink = TEXTURE_READ(_FurLengthTex, uv).rgb;
        float furLength = lengthAndSink.r;
        //float density = lengthAndSink.g;
        float sink = lengthAndSink.b;
        
        if (furLength < 0.01)
            continue;
        
        half3 ambient = ambient_Origin + ambient_0 * moveFactor.x + ambient_1 * moveFactor.y;
        float3 wTangent = normalize(wTangent_Origin + wTangent_0 * moveFactor.x + wTangent_1 * moveFactor.y);
        float3 wBinormal = cross(wNormal, wTangent) * tangentW;
        
        float furRandomLength = UpdateRandomToFloatAbs(random);
        furLength *= _FurLength * (1.0 - furRandomLength * _FurRandomLength);
        
        float3 randomDirection = float3(UpdateRandomToFloat(random), UpdateRandomToFloat(random), UpdateRandomToFloatAbs(random));
        randomDirection = normalize(randomDirection);
        
        float3 furZ = UnpackNormal(TEXTURE_READ(_FurDirectionTex, uv));
        furZ = lerp(furZ, randomDirection, float3(_FurRandomDirectionXY.xx, _FurRandomDirectionZ));
        // furZ = lerp(float3(0.0, 0.0, 1.0), furZ, saturate(dot(wNormal, trueNormal)));
        furZ = normalize(wTangent * furZ.x + wBinormal * furZ.y + wNormal * furZ.z);
        
        float3 furX = normalize(cross(wNormal, furZ)) * furLength;
        float3 furY = cross(furZ, furX);
        
        furX *= _FurX;
        furY *= _FurY;
        furZ *= furLength;
        
        float furSink = _FurSink * sink;
        
        //              (furZ - furZ * furSink) * 0.5 + furY;
        float3 temp30 = furZ * (0.5 - furSink * 0.5) + furY;
        
        half temp40 = lerp(1.0 - _FurOcclusionStrength, 1.0, -furSink);
        half temp41 = (temp40 + 1.0) * 0.5;
        
        
        
        //float3 unpackNormal = UnpackScaleNormalRGorAG(TEXTURE_READ(_BumpMap, uv), _BumpScale);
        //unpackNormal = normalize(wTangent * unpackNormal.x + wBinormal * unpackNormal.y + wNormal * unpackNormal.z);
        
        float3 unpackNormal = UnpackNormal(_BumpMap.SampleLevel(sampler_BumpMap, uv, 0));
        unpackNormal = wTangent * unpackNormal.x + wBinormal * unpackNormal.y + wNormal * unpackNormal.z;
        
        half4 mainColor = TEXTURE_READ(_FurColorTex, uv);
        half3 emissionColor = TEXTURE_READ(_EmissionMap, uv).rgb * _EmissionColor;
        half4 mg = TEXTURE_READ(_MetallicGlossMap, uv);
        half occlusion = lerp(1.0, TEXTURE_READ(_OcclusionMap, uv).g, _OcclusionStrength);
        
        float cascadeShadow = 1.0;
        
#if defined(HUWA_CASCADE_SHADOW_IS_AVAILABLE)
        float vz = abs(dot(UNITY_MATRIX_V._m20_m21_m22, wPosition - _WorldSpaceCameraPos));
        float4 shadow_cPos = UnityWorldToClipPos(wPosition - wNormal * vz * _ShadowNormalOffset);
        cascadeShadow = HuwaCascadeShadow_cPos(shadow_cPos.xyw);
#endif
        
        G2F_Fur output = (G2F_Fur) 0;
        output.color = BRDF(wPosition, unpackNormal, uv, mainColor, emissionColor, ambient, mg.r, mg.a, occlusion, cascadeShadow).rgb;
        
        output.cPos = UnityWorldToClipPos(wPosition + temp30 + furX);
        output.uv = half2(1.0, 0.0);
        output.furOcclusion = temp41;
        stream.Append(output);
        
        output.cPos = UnityWorldToClipPos(wPosition + furZ * -furSink);
        output.uv = half2(0.0, 0.0);
        output.furOcclusion = temp40;
        stream.Append(output);
        
        output.cPos = UnityWorldToClipPos(wPosition + furZ);
        output.uv = half2(1.0, 1.0);
        output.furOcclusion = 1.0;
        stream.Append(output);
        
        output.cPos = UnityWorldToClipPos(wPosition + temp30 - furX);
        output.uv = half2(0.0, 1.0);
        output.furOcclusion = temp41;
        stream.Append(output);
        
        stream.RestartStrip();
    }
}

half4 FragmentShaderStage_Fur(G2F_Fur input) : SV_Target
{
    half4 color = TEXTURE_READ(_FurBundleColorTex, input.uv);
    
#if defined(TRANSPARENT_PASS)
    clip(-(color.a <= 0.0));
    color.a = saturate(color.a / _FurAlphaCutoff);
#else
    clip(-(color.a < _FurAlphaCutoff));
#endif
    
    float furOcclusion = max(input.furOcclusion, 1.0 - _FurOcclusionStrength);
    return half4(input.color * color.rgb * furOcclusion, color.a);
}



struct I2V_ShadowCaster
{
    float4 lPos : POSITION;
    float3 lNormal : NORMAL;
};

struct V2F_ShadowCaster
{
    float4 cPos : SV_POSITION;
};

V2F_ShadowCaster VertexShaderStage_ShadowCaster(I2V_ShadowCaster input)
{
    float3 lNormal = input.lNormal;
    
    float4 opos = UnityClipSpaceShadowCasterPos(input.lPos, input.lNormal);
    opos = UnityApplyLinearShadowBias(opos);
    
    V2F_ShadowCaster output = (V2F_ShadowCaster) 0;
    output.cPos = opos;
    return output;
}

half4 FragmentShaderStage_ShadowCaster() : SV_Target
{
    return 0.0;
}
