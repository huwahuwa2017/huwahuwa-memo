//Ver2 2022/12/19 06:42

Shader "HuwaShader/HuwaFastFur"
{
	Properties
	{
		[NoScaleOffset]
		_MainTex("Main Texture", 2D) = "white" {}
		[NoScaleOffset][Normal]
		_FurDirectionTex("Fur Direction Texture", 2D) = "bump" {}
		[NoScaleOffset]
		_FurLengthTex("Fur Length Texture", 2D) = "white" {}
		[NoScaleOffset]
		_AreaDataTex("Area Data Texture", 2D) = "white" {}

		_FurMaxLength("Fur Max Length", Float) = 0.2
		_FurRandomLength("Fur Random Length", Range(0, 1)) = 0.0
		_FurScaleWidth("Fur Scale Width", Range(0, 1)) = 0.125
		_FurRoughness("Fur Roughness", Range(0, 1)) = 0.0
		_FurDensity("Fur Density", Range(0.01, 9999)) = 20.0
		_FurSplit("Fur Split", Float) = 8.0
		_FurAbsorption("Fur Absorption", Range(0, 1)) = 0.5

		_ColorIntensity("Color intensity", Range(0.0, 1.0)) = 0.0625
		_AmbientColorAdjustment("Ambient color adjustment", Vector) = (0.0, 0.0, 0.0)
	}

	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest"
			"RenderType" = "Opaque"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "Vertex"
			}

			Cull Off

			CGPROGRAM

			#include "HuwaFastFur.hlsl"

			#pragma require tessellation
			#pragma require geometry

			#pragma vertex VertexStage
			#pragma hull HullStage
			#pragma domain DomainStage
			#pragma geometry GeometryStage
			#pragma fragment FragmentStage

			ENDCG
		}
	}
}
