Shader "HuwaShader/HuwaFurV9-3"
{
	Properties
	{
		[NoScaleOffset]
		_MainTex("Skin Color Texture", 2D) = "white" {}
		[NoScaleOffset][Normal]
		_BumpMap("Normal Texture", 2D) = "bump" {}
		[NoScaleOffset]
		_MetallicGlossMap("Metallic Gloss Map", 2D) = "black" {}
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 0.0
		[NoScaleOffset]
		_OcclusionMap("Occlusion Map", 2D) = "black" {}
        _EmissionColor("Emission Strength", Vector) = (0.0, 0.0, 0.0)
		[NoScaleOffset]
		_EmissionMap("Emission Map", 2D) = "white" {}
		_FurOcclusionStrength("Fur Occlusion Strength", Range(0.0, 1.0)) = 0.5
		[NoScaleOffset]
		_FurOcclusionTex("Fur Occlusion Texture", 2D) = "black" {}
		
		[Space(24)]

		[NoScaleOffset]
		_FurColorTex("Fur Color Texture", 2D) = "white" {}
		[NoScaleOffset][Normal]
		_FurDirectionTex("Fur Direction Texture", 2D) = "bump" {}
		[NoScaleOffset]
		_FurLengthTex("Fur Length Texture", 2D) = "white" {}
		[NoScaleOffset]
		_FurCountTex("Fur Count Texture", 2D) = "white" {}
		[NoScaleOffset]
		_FurBundleColorTex("Fur Bundle Color", 2D) = "white" {}
		
		[Space(24)]

		_FurLength("Fur Length", Float) = 0.05
		_FurX("Fur X", Range(0, 1)) = 0.1
		_FurY("Fur Y", Range(0, 1)) = 0.1
		//_FurDirectionZ("Fur Direction Z", Range(0, 1)) = 1.0
		_FurSink("Fur Sink", Range(0, 1)) = 0.0
		_FurRandomLength("Fur Random Length", Range(0, 1)) = 0.25
		_FurRandomDirectionXY("Fur Random Direction XY", Range(0, 1)) = 0.25
		_FurRandomDirectionZ("Fur Random Direction Z", Range(0, 1)) = 0.25
		_FurDensity("Fur Density", Float) = 200.0
		_FurAlphaCutoff("Fur Alpha Cutoff", Range(0, 1)) = 0.5
	}

	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest"
			"RenderType" = "TransparentCutout"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Cull Off

			CGPROGRAM

			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap

			#pragma vertex VertexShaderStage_Skin
			#pragma fragment FragmentShaderStage_Skin
			
			#include "HuwaFurV9.hlsl"

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Cull Off

			CGPROGRAM

			#pragma require tessellation
			#pragma require geometry
			
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap

			#pragma vertex VertexShaderStage_Fur
			#pragma hull HullShaderStage_Fur
			#pragma domain DomainShaderStage_Fur
			#pragma geometry GeometryShaderStage_Fur
			#pragma fragment FragmentShaderStage_Fur
			
			#include "HuwaFurV9.hlsl"

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Cull Off
			ZTest Less
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma require tessellation
			#pragma require geometry
			
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap

			#pragma vertex VertexShaderStage_Fur
			#pragma hull HullShaderStage_Fur
			#pragma domain DomainShaderStage_Fur
			#pragma geometry GeometryShaderStage_Fur
			#pragma fragment FragmentShaderStage_Fur
			
			#define TRANSPARENT_PASS

			#include "HuwaFurV9.hlsl"

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}
			
			CGPROGRAM
			
			#pragma vertex VertexShaderStage_ShadowCaster
			#pragma fragment FragmentShaderStage_ShadowCaster
			
			#include "HuwaFurV9.hlsl"

			ENDCG
		}
	}

	FallBack Off
}
