// Ver2 2024-04-02 20:09

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Created based on Unity 2022.3.8f1 UnityStandardUtils.cginc UnityStandardCore.cginc UnityStandardShadow.cginc

#include "UnityCG.cginc"
#include "AutoLight.cginc"

#include "RewriteGlobalIllumination.hlsl"
#include "RewriteBRDF.hlsl"

#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

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
	float4x3 data : TEXCOORD0;
	float2 uv : TEXCOORD3;
	half3 ambient : TEXCOORD4;
	float4 sPos : TEXCOORD5;
	float3 tViewDir : TEXCOORD6;
};

int _UseMetallicGlossMap;

half4 _Color;
sampler2D _MainTex;

half _Metallic;
sampler2D _MetallicGlossMap;

half _BumpScale;
sampler2D _BumpMap;

half _Parallax;
sampler2D _ParallaxMap;

half _OcclusionStrength;
sampler2D _OcclusionMap;

half3 _EmissionColor;
sampler2D _EmissionMap;

half _Cutoff;
half _Glossiness;

fixed4 _LightColor0;

half2 ParallaxOffset1Step(half h, half height, half3 tViewDir)
{
	h = h * height - height / 2.0;
	half3 v = normalize(tViewDir);
	v.z += 0.42;
	return h * (v.xy / v.z);
}

half3 UnpackScaleNormalRGorAG(half4 packednormal, half bumpScale)
{
#if defined(UNITY_NO_DXT5nm)
	half3 normal = packednormal.xyz * 2.0 - 1.0;
	normal.xy *= bumpScale;
	return normal;
#elif defined(UNITY_ASTC_NORMALMAP_ENCODING)
	half3 normal;
	normal.xy = (packednormal.wy * 2.0 - 1.0);
	normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	normal.xy *= bumpScale;
	return normal;
#else
	packednormal.x *= packednormal.w;

	half3 normal;
	normal.xy = (packednormal.xy * 2.0 - 1.0);
	normal.xy *= bumpScale;
	normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	return normal;
#endif
}

half2 MetallicGloss(float2 uv)
{
	half2 mg = tex2D(_MetallicGlossMap, uv).ra;
	mg.g *= _Glossiness;
	
	return (_UseMetallicGlossMap) ? mg : half2(_Metallic, _Glossiness);
}

half LightAttenuation(float3 wPos)
{
#if defined(POINT)
	float4 lightCoord = mul(unity_WorldToLight, float4(wPos, 1.0));
	
	return tex2D(_LightTexture0, dot(lightCoord.xyz, lightCoord.xyz).xx).r;
#elif defined(SPOT)
	float4 lightCoord = mul(unity_WorldToLight, float4(wPos, 1.0));
	
	half atten = lightCoord.z > 0.0;
	atten *= tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w;
	atten *= tex2D(_LightTextureB0, dot(lightCoord.xyz, lightCoord.xyz).xx).r;
	return atten;
#else
	return 1.0;
#endif
}

V2F VertexShaderStage(I2V input)
{
	float3 wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;
	
	float3 lNormal = input.lNormal;
	float3 lTangent = input.lTangent.xyz;
	float3 lBinormal = cross(lNormal, lTangent) * input.lTangent.w;
	
	float3 lViewDir = mul((float3x3) UNITY_MATRIX_I_M, _WorldSpaceCameraPos - wPos);
	float3 tViewDir = mul(float3x3(lTangent, lBinormal, lNormal), lViewDir);
	
	float3 wNormal = UnityObjectToWorldNormal(lNormal);
	float3 wTangent = UnityObjectToWorldDir(lTangent);
	float3 wBinormal = cross(wNormal, wTangent) * input.lTangent.w * unity_WorldTransformParams.w;
	
	// 頂点シェーダーからフラグメントシェーダーにデータを渡す場合、
	// float3x4よりfloat4x3の方が裏で発生する変数の数を節約できる
	float4x3 data = float4x3(wTangent, wBinormal, wNormal, wPos);
	
#if defined(VERTEXLIGHT_ON) // 基本的にOff
	half3 ambient = Shade4PointLights(wPos, wNormal);
#else
	half3 ambient = 0.0;
#endif
	
	ambient = ShadeSHPerVertex(wNormal, ambient);
	
	V2F output = (V2F) 0;
	output.cPos = UnityWorldToClipPos(wPos);
	output.data = data;
	output.uv = input.uv;
	output.ambient = ambient;
	output.sPos = ComputeScreenPos(output.cPos); // 影で使う
	output.tViewDir = tViewDir; // 視差マッピングで使う
	return output;
}

half4 FragmentShaderStage(V2F input) : SV_Target
{
	float2 uv = input.uv;
	uv += ParallaxOffset1Step(tex2D(_ParallaxMap, uv).g, _Parallax, input.tViewDir);
	
	half4 colorData = tex2D(_MainTex, uv) * _Color;
	half alpha = colorData.a;
	
#if defined(_MODE_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif
	
	float3 wPos = input.data[3];
	
	float3x3 t2w = transpose((float3x3) input.data);
	float3 wNormal = UnpackScaleNormalRGorAG(tex2D(_BumpMap, uv), _BumpScale);
	wNormal = normalize(mul(t2w, wNormal));
	
	float3 wViewDir = normalize(_WorldSpaceCameraPos - wPos);
	float3 wReflectDir = reflect(-wViewDir, wNormal);
	float3 wLightDir = normalize(_WorldSpaceLightPos0.xyz - wPos * _WorldSpaceLightPos0.w);
	
	half2 mg = MetallicGloss(uv);
	
	half3 albedo = colorData.rgb;
	half metallic = mg.r;
	half smoothness = mg.g;
	half occlusion = lerp(1.0, tex2D(_OcclusionMap, uv).g, _OcclusionStrength);
	
	half oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a - metallic * unity_ColorSpaceDielectricSpec.a;
	half reflectivity = 1.0 - oneMinusReflectivity;
	half perceptualRoughness = 1.0 - smoothness;
	
	half3 lightColor = _LightColor0.rgb;
	lightColor *= LightAttenuation(wPos) * UnityComputeForwardShadows(0.0, wPos, input.sPos);
	
	half3 diffColor = albedo * oneMinusReflectivity;
	
#if defined(_MODE_ALPHAPREMULTIPLY_ON)
	diffColor *= alpha;
	alpha = reflectivity + oneMinusReflectivity * alpha;
#endif
	
	half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	
#if defined(UNITY_PASS_FORWARDBASE)
	half3 giDiffuse = ShadeSHPerPixel(wNormal, input.ambient, wPos);
	half3 giSpecular = UnityGI_IndirectSpecular(wPos, wReflectDir, perceptualRoughness, occlusion);
#else
	half3 giDiffuse = 0.0;
	half3 giSpecular = 0.0;
#endif
	
	half3 color = BRDF(lightColor, diffColor, specColor, reflectivity, smoothness, giDiffuse, giSpecular, wNormal, wViewDir, wLightDir);
	color += tex2D(_EmissionMap, uv).rgb * _EmissionColor;
	
#if !(defined(_MODE_ALPHABLEND_ON) || defined(_MODE_ALPHAPREMULTIPLY_ON))
	alpha = 1.0;
#endif
	
	return half4(color, alpha);
}



// ---- ShadowCaster ----



#if (defined(_MODE_ALPHABLEND_ON) || defined(_MODE_ALPHAPREMULTIPLY_ON)) && defined(UNITY_USE_DITHER_MASK_FOR_ALPHABLENDED_SHADOWS)
#define UNITY_STANDARD_USE_DITHER_MASK 1
#endif

#if defined(UNITY_STANDARD_USE_DITHER_MASK)
sampler3D _DitherMaskLOD;
#endif

void DitherMask(half alpha, half cutoff, float4 cPos)
{
#if defined(UNITY_STANDARD_USE_DITHER_MASK)
	alpha = tex3D(_DitherMaskLOD, float3(cPos.xy * 0.25, alpha * 0.9375)).a;
	clip(alpha - 0.01);
#else
	clip(alpha - cutoff);
#endif
}

V2F VertexShaderStage_ShadowCaster(I2V input)
{
	float3 wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;
	
	float3 lNormal = input.lNormal;
	float3 lTangent = input.lTangent.xyz;
	float3 lBinormal = cross(lNormal, lTangent) * input.lTangent.w;
	
	float3 lViewDir = mul((float3x3) UNITY_MATRIX_I_M, _WorldSpaceCameraPos - wPos);
	float3 tViewDir = mul(float3x3(lTangent, lBinormal, lNormal), lViewDir);
	
	float4 opos = UnityClipSpaceShadowCasterPos(input.lPos, input.lNormal);
	opos = UnityApplyLinearShadowBias(opos);
	
	V2F output = (V2F) 0;
	output.cPos = opos;
	output.uv = input.uv;
	output.tViewDir = tViewDir;
	return output;
}

half4 FragmentShaderStage_ShadowCaster(V2F input) : SV_Target
{
	float2 uv = input.uv;
	uv += ParallaxOffset1Step(tex2D(_ParallaxMap, uv).g, _Parallax, input.tViewDir);
	
	half alpha = tex2D(_MainTex, uv).a * _Color.a;
	
#if defined(_MODE_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#elif defined(_MODE_ALPHABLEND_ON)
	DitherMask(alpha, _Cutoff, input.cPos);
#elif defined(_MODE_ALPHAPREMULTIPLY_ON)
	half2 mg = MetallicGloss(uv);
	
	half metallic = mg.r;
	half oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a - metallic * unity_ColorSpaceDielectricSpec.a;
	half reflectivity = 1.0 - oneMinusReflectivity;
	
	alpha = reflectivity + oneMinusReflectivity * alpha;
	
	DitherMask(alpha, _Cutoff, input.cPos);
#endif
	
	return 0.0;
}
