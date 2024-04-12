// Ver3 2024-04-13 07:43

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Created based on Unity 2022.3.8f1 UnityGlobalIllumination.cginc UnityImageBasedLighting.cginc UnityStandardUtils.cginc

#if !defined(REWRITE_GLOBAL_ILLUMINATION)
#define REWRITE_GLOBAL_ILLUMINATION

#include "UnityCG.cginc"

half3 Shade4PointLights(float3 wPos, half3 wNormal)
{
	return Shade4PointLights
	(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, wPos, wNormal
	);
}

half3 ShadeSHPerVertex(half3 wNormal, half3 ambient)
{
#ifdef UNITY_COLORSPACE_GAMMA
	ambient = GammaToLinearSpace(ambient);
#endif
	
	ambient += SHEvalLinearL2(half4(wNormal, 1.0));
	
	return ambient;
}

half3 ShadeSHPerPixel(half3 wNormal, half3 ambient, float3 wPos)
{
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
	if (unity_ProbeVolumeParams.x == 1.0)
		ambient += SHEvalLinearL0L1_SampleProbeVolume(half4(wNormal, 1.0), wPos);
	else
		ambient += SHEvalLinearL0L1(half4(wNormal, 1.0));
#else
	ambient += SHEvalLinearL0L1(half4(wNormal, 1.0));
#endif

	ambient = max(0.0, ambient);

#ifdef UNITY_COLORSPACE_GAMMA
	ambient = LinearToGammaSpace(ambient);
#endif
	
	return ambient;
}



float3 BoxProjectedCubemapDirection(float3 wPos, float3 wReflectDir, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{
	if (cubemapCenter.w > 0.0)
	{
		float3 rbminmax = (wReflectDir > 0.0) ? boxMax.xyz : boxMin.xyz;
		rbminmax = (rbminmax - wPos) / wReflectDir;
		float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);
		wReflectDir = wPos - cubemapCenter.xyz + wReflectDir * fa;
	}
	
	return wReflectDir;
}

half3 Unity_GlossyEnvironment(UNITY_ARGS_TEXCUBE(tex), half4 hdr, half perceptualRoughness, float3 reflUVW)
{
	half mip = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * 6.0;
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, reflUVW, mip);
	return DecodeHDR(rgbm, hdr);
}

half3 Unity_GlossyEnvironment_SC0(float3 wPos, float3 wReflectDir, half perceptualRoughness)
{
#if defined(UNITY_SPECCUBE_BOX_PROJECTION)
	wReflectDir = BoxProjectedCubemapDirection(wPos, wReflectDir, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
#endif
	
	return Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, perceptualRoughness, wReflectDir);
}

half3 Unity_GlossyEnvironment_SC1(float3 wPos, float3 wReflectDir, half perceptualRoughness)
{
#if defined(UNITY_SPECCUBE_BOX_PROJECTION)
	wReflectDir = BoxProjectedCubemapDirection(wPos, wReflectDir, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
#endif
	
	return Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, perceptualRoughness, wReflectDir);
}

half3 UnityGI_IndirectSpecular(float3 wPos, float3 wReflectDir, half perceptualRoughness, half occlusion)
{
	half3 specular = Unity_GlossyEnvironment_SC0(wPos, wReflectDir, perceptualRoughness);
	
#if defined(UNITY_SPECCUBE_BLENDING)
	float blendLerp = unity_SpecCube0_BoxMin.w;
	
	if (blendLerp < 0.99999)
	{
		half3 env1 = Unity_GlossyEnvironment_SC1(wPos, wReflectDir, perceptualRoughness);
		specular = lerp(env1, specular, blendLerp);
	}
#endif

	return specular * occlusion;
}

#endif // !defined(REWRITE_GLOBAL_ILLUMINATION)
