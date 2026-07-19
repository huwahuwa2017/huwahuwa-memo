// v12.5 2026-07-19 19:45

#include "HuwaLib/HuwaRandomFunction.hlsl"
#include "HuwaLib/HuwaCascadeShadow.hlsl"
#include "HuwaLib/HuwaStandardLit.hlsl"

Texture2D _MainTex;
SamplerState sampler_MainTex;
float4 _MainTex_TexelSize;

Texture2D _BumpMap;
SamplerState sampler_BumpMap;
float4 _BumpMap_TexelSize;

Texture2D _MetallicGlossMap;
SamplerState sampler_MetallicGlossMap;
float4 _MetallicGlossMap_TexelSize;

Texture2D _OcclusionMap;
SamplerState sampler_OcclusionMap;
float4 _OcclusionMap_TexelSize;
half _OcclusionStrength;

Texture2D _EmissionMap;
SamplerState sampler_EmissionMap;
float4 _EmissionMap_TexelSize;
half3 _EmissionStrength;

Texture2D _FurOcclusionTex;
SamplerState sampler_FurOcclusionTex;
float4 _FurOcclusionTex_TexelSize;
half _FurOcclusionStrength;

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

Texture2D _BayerMatrixTex;

float _FurLength;
float _FurX;
float _FurY;
float _FurSink;

float _FurRandomLength;
float _FurRandomDirectionXY;
float _FurRandomDirectionZ;
float _FurDensity;
float _FurAlphaMul;
float _FurAlphaAdd;
float _FurAlphaCutoff;

static float _FurCulling = 0.5;
static float _LOD = 15.0;

// サンプラーを無視して処理速度を優先する
#define TEX2D_LOAD_REPEAT(tex, uv) tex[uint2(frac(uv) * tex##_TexelSize.zw)]

// HuwaTexelReadWrite の一部
static uint2 _HTRW_ReadTextureSize = 0;

#define HTRW_TEXEL_READ(tex, id, result)\
_HTRW_ReadTextureSize = uint2(tex##_TexelSize.zw);\
result = tex[uint2((id) % _HTRW_ReadTextureSize.x, ((id) / _HTRW_ReadTextureSize.x) % _HTRW_ReadTextureSize.y)];

// cPos_W = UnityWorldToClipPos(wPos).w
// cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0))
float CameraOcclusion(float cPos_W)
{
    float cameraOcclusion = 1.0 - saturate(cPos_W);
    cameraOcclusion = cameraOcclusion * cameraOcclusion;
    cameraOcclusion = cameraOcclusion * cameraOcclusion;
    cameraOcclusion = cameraOcclusion * cameraOcclusion;
    cameraOcclusion = cameraOcclusion * cameraOcclusion;
    cameraOcclusion = 1.0 - cameraOcclusion;
    return cameraOcclusion;
}

// 1メートルあたりのピクセル数
// cPos_W = UnityWorldToClipPos(wPos).w
// cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0))
float2 PixelPerMeter(float cPos_W)
{
    return (_ScreenParams.xy * abs(UNITY_MATRIX_P._m00_m11)) / (cPos_W * 2.0);
}

// 1ピクセルあたりのメートル数
// cPos_W = UnityWorldToClipPos(wPos).w
// cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0))
float2 MeterPerPixel(float cPos_W)
{
    return (cPos_W * 2.0) / (_ScreenParams.xy * abs(UNITY_MATRIX_P._m00_m11));
}





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
    
    float3 unpackNormal = UnpackNormal(_BumpMap.Sample(sampler_BumpMap, uv));
    unpackNormal = wTangent * unpackNormal.x + wBinormal * unpackNormal.y + wNormal * unpackNormal.z;
    
    float3 wRayStartPos = _WorldSpaceCameraPos;
    
    half4 mainColor = _MainTex.Sample(sampler_MainTex, uv);
    half3 emissionColor = _EmissionMap.Sample(sampler_EmissionMap, uv).rgb * _EmissionStrength;
    half4 mg = _MetallicGlossMap.Sample(sampler_MetallicGlossMap, uv);
    half occlusion = _OcclusionMap.Sample(sampler_OcclusionMap, uv).g;
    occlusion = lerp(1.0, occlusion, _OcclusionStrength);
    
    half cascadeShadow = HuwaCascadeShadow(input.cPos.xy);
    
    half4 result = BRDF(input.wPos, unpackNormal, wRayStartPos, mainColor, emissionColor, input.ambient, mg.r, mg.a, occlusion, cascadeShadow);
    
    //half3 temp0 = TEXTURE_READ_REPEAT(_FurOcclusionTex, uv).rgb;
    half3 temp0 = _FurOcclusionTex.Sample(sampler_FurOcclusionTex, uv);
    half furOcclusion = max(max(temp0.r, temp0.g), temp0.b);
    
    // furOcclusion = lerp(1.0 - _FurOcclusionStrength, 1.0, furOcclusion);
    // ↓
    furOcclusion = lerp(1.0, furOcclusion, _FurOcclusionStrength);
    
    result.rgb *= furOcclusion * CameraOcclusion(input.cPos.w);
    return result;
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
    uint seed : TEXCOORD6;
};

struct G2F_Fur
{
    float4 cPos : SV_POSITION;
    half3 color : TEXCOORD0;
    half3 data : TEXCOORD1;
    uint2 random : TEXCOORD2;
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
    output.seed = input.id;
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
    
    float furCountLod;
    {
        float lodStart = 9.0;
        float lodEnd = 1.0;
        
        float cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0));
        float2 pixelPerMeter = PixelPerMeter(cPos_W);
        furCountLod = _FurLength * max(pixelPerMeter.x, pixelPerMeter.y);
        furCountLod = (furCountLod - lodEnd) / (lodStart - lodEnd);
        furCountLod = saturate(furCountLod);
    }
    
    float furCount;
    HTRW_TEXEL_READ(_FurCountTex, primitiveID, furCount);
    furCount = furCount * furCountLod * _FurDensity;
    
    bool noTess = furCount <= 1.0;
    float requiredTessFactor = ceil(furCount / 3.0); // 64が最大?
    float polygonCount = noTess ? 1.0 : requiredTessFactor * 3.0;
    
    TessellationFactor_Fur output = (TessellationFactor_Fur) 0;
    output.tessFactor[0] = requiredTessFactor;
    output.tessFactor[1] = requiredTessFactor;
    output.tessFactor[2] = requiredTessFactor;
    output.insideTessFactor = noTess ? 1.0 : 2.0;
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
    output.seed = ValueToRandom(uint4(input[0].seed, input[1].seed, input[2].seed, ValueToRandom(bary)));
    output.furCount = tf.furCount;
    return output;
}

[maxvertexcount(4)]
void GeometryShaderStage_Fur(triangle V2G_Fur input[3], inout TriangleStream<G2F_Fur> stream)
{
    uint seed = ValueToRandom(uint3(input[0].seed, input[1].seed, input[2].seed));
    
    if (input[0].furCount + UpdateRandomToFloatAbs(seed) < 1.0)
        return;
    
    half3 ambient;
    float2 uv;
    float3 wPosition, wNormal, wTangent, wBinormal;
    {
        half3 ambient_Origin = input[0].ambient;
        half3 ambient_0 = input[1].ambient - ambient_Origin;
        half3 ambient_1 = input[2].ambient - ambient_Origin;
        
        float2 uv_Origin = input[0].uv;
        float2 uv_0 = input[1].uv - uv_Origin;
        float2 uv_1 = input[2].uv - uv_Origin;
        
        float3 wPosition_Origin = input[0].wPos;
        float3 wPosition_0 = input[1].wPos - wPosition_Origin;
        float3 wPosition_1 = input[2].wPos - wPosition_Origin;
        
        float3 wNormal_Origin = input[0].wNormal;
        float3 wNormal_0 = input[1].wNormal - wNormal_Origin;
        float3 wNormal_1 = input[2].wNormal - wNormal_Origin;
        
        float3 wTangent_Origin = input[0].wTangent.xyz;
        float3 wTangent_0 = input[1].wTangent.xyz - wTangent_Origin;
        float3 wTangent_1 = input[2].wTangent.xyz - wTangent_Origin;
        
        float tangentW = input[0].wTangent.w;
        
        float2 moveFactor = float2(UpdateRandomToFloatAbs(seed), UpdateRandomToFloatAbs(seed));
        moveFactor = float2(1.0 - max(moveFactor.x, moveFactor.y), min(moveFactor.x, moveFactor.y));
        
        ambient = ambient_Origin + ambient_0 * moveFactor.x + ambient_1 * moveFactor.y;
        uv = uv_Origin + uv_0 * moveFactor.x + uv_1 * moveFactor.y;
        wPosition = wPosition_Origin + wPosition_0 * moveFactor.x + wPosition_1 * moveFactor.y;
        wNormal = normalize(wNormal_Origin + wNormal_0 * moveFactor.x + wNormal_1 * moveFactor.y);
        wTangent = normalize(wTangent_Origin + wTangent_0 * moveFactor.x + wTangent_1 * moveFactor.y);
        wBinormal = normalize(cross(wNormal, wTangent) * tangentW);
    }
    
    float3 lengthAndSink = TEX2D_LOAD_REPEAT(_FurLengthTex, uv).rgb;
    
    bool2 flag;
    flag.x = dot(normalize(wPosition - _WorldSpaceCameraPos), wNormal) > _FurCulling;
    flag.y = lengthAndSink.r < 0.01;
    
    if (flag.x || flag.y)
        return;
    
    float furLength = lengthAndSink.r * _FurLength * (1.0 - UpdateRandomToFloatAbs(seed) * _FurRandomLength);
    float furSink = lengthAndSink.g * _FurSink;
    
    half3 color;
    {
        float3 unpackNormal = UnpackNormal(TEX2D_LOAD_REPEAT(_BumpMap, uv));
        unpackNormal = wTangent * unpackNormal.x + wBinormal * unpackNormal.y + wNormal * unpackNormal.z;
        
        float3 wRayStartPos = _WorldSpaceCameraPos;
        
        half4 mainColor = TEX2D_LOAD_REPEAT(_FurColorTex, uv);
        half3 emissionColor = TEX2D_LOAD_REPEAT(_EmissionMap, uv).rgb * _EmissionStrength;
        half4 mg = TEX2D_LOAD_REPEAT(_MetallicGlossMap, uv);
        half occlusion = lerp(1.0, TEX2D_LOAD_REPEAT(_OcclusionMap, uv).g, _OcclusionStrength);
        
        float cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPosition, 1.0));
        
        float cascadeShadow = 1.0;
        
#if defined(HUWA_CASCADE_SHADOW_IS_AVAILABLE)
        float2 meterPerPixel = MeterPerPixel(cPos_W);
        float3 offset = wNormal * (max(meterPerPixel.x, meterPerPixel.y) * 0.707107);
        float4 cPosShadow = UnityWorldToClipPos(wPosition - offset);
        cascadeShadow = HuwaCascadeShadow_cPos(cPosShadow.xyw);
#endif
        
        color = BRDF(wPosition, unpackNormal, wRayStartPos, mainColor, emissionColor, ambient, mg.r, mg.a, occlusion, cascadeShadow).rgb;
        color *= CameraOcclusion(cPos_W);
    }
    
    float3 furX, furY, furZ;
    {
        float3 randomDirection = float3(UpdateRandomToFloat(seed), UpdateRandomToFloat(seed), UpdateRandomToFloatAbs(seed));
        
        furZ = UnpackNormal(TEX2D_LOAD_REPEAT(_FurDirectionTex, uv));
        furZ.z = lerp(furZ.z, randomDirection.z, _FurRandomDirectionZ * lengthAndSink.g);
        furZ.xy = lerp(furZ.xy, randomDirection.xy, _FurRandomDirectionXY);
        furZ.xy = normalize(furZ.xy) * sqrt(1.0 - furZ.z * furZ.z);
        furZ = wTangent * furZ.x + wBinormal * furZ.y + wNormal * furZ.z;
        
        furX = normalize(cross(wNormal, furZ)) * furLength;
        furY = cross(furZ, furX);
        
        furX *= _FurX;
        furY *= _FurY;
        furZ *= furLength;
    }
    
    //              (furZ - furZ * furSink) * 0.5 + furY;
    float3 temp30 = furZ * (0.5 - furSink * 0.5) + furY;
    
    half temp40 = lerp(1.0 - _FurOcclusionStrength, 1.0, -furSink);
    half temp41 = (temp40 + 1.0) * 0.5;
    
    
    
    // output.data.xy is uv
    // output.data.z  is Occlusion
    G2F_Fur output = (G2F_Fur) 0;
    output.color = color;
    output.random = uint2(UpdateRandom(seed), UpdateRandom(seed));
    
    output.cPos = UnityWorldToClipPos(wPosition + temp30 + furX);
    output.data = half3(1.0, 0.0, temp41);
    stream.Append(output);
    
    output.cPos = UnityWorldToClipPos(wPosition + furZ * -furSink);
    output.data = half3(0.0, 0.0, temp40);
    stream.Append(output);
    
    output.cPos = UnityWorldToClipPos(wPosition + furZ);
    output.data = half3(1.0, 1.0, 1.0);
    stream.Append(output);
    
    output.cPos = UnityWorldToClipPos(wPosition + temp30 - furX);
    output.data = half3(0.0, 1.0, temp41);
    stream.Append(output);
    
    stream.RestartStrip();
}

half4 FragmentShaderStage_Fur(G2F_Fur input) : SV_Target
{
    half4 color = TEX2D_LOAD_REPEAT(_FurBundleColorTex, input.data.xy);
    float alpha = mad(color.a, _FurAlphaMul, _FurAlphaAdd);
    
#if defined(_FUR_DITHERING)
    uint2 index = (uint2(input.cPos.xy) + input.random) & 15;
    clip(-(alpha <= (_BayerMatrixTex[index].r * asfloat(0x3F7F0000)))); // asfloat(0x3F7F0000) = 255.0 / 256.0
#else
    clip(-(alpha <= _FurAlphaCutoff));
#endif
    
    float furOcclusion = max(input.data.z, 1.0 - _FurOcclusionStrength);
    
    color.rgb = input.color * color.rgb * furOcclusion;
    color.a = 1.0;
    return color;
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
