Shader "HuwaShader/HuwaFurV9-1"
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
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Geometry"
			"RenderType" = "Opaque"
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
