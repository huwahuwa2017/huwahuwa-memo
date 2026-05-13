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
		
		[Space(48)]

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
		
		[Space(48)]

		_FurLength("Fur Length", Float) = 0.04
		_FurX("Fur X", Range(0, 1)) = 0.25
		_FurY("Fur Y", Range(0, 1)) = 0.25
		_FurSink("Fur Sink", Range(0, 1)) = 0.5
		_FurRandomLength("Fur Random Length", Range(0, 1)) = 0.25
		_FurRandomDirectionXY("Fur Random Direction XY", Range(0, 1)) = 0.25
		_FurRandomDirectionZ("Fur Random Direction Z", Range(0, 1)) = 0.0
		_FurDirectionRandomScale("Fur Direction Random Scale", Range(0, 1)) = 0.5
		_FurDensity("Fur Density", Float) = 30.0
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
			
            ColorMask 0
			Cull Off

			CGPROGRAM

			#pragma require tessellation
			#pragma require geometry
			
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap

			#pragma vertex VertexShaderStage_FurDepth
			#pragma hull HullShaderStage_FurDepth
			#pragma domain DomainShaderStage_FurDepth
			#pragma geometry GeometryShaderStage_FurDepth
			#pragma fragment FragmentShaderStage_FurDepth
			
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
