// Ver1 2023/11/18 12:34

Shader "HuwaShader/HuwaFurV5"
{
	Properties
	{
		[NoScaleOffset][Normal]
		_FurDirectionTex("Fur Direction Texture", 2D) = "bump" {}
		[NoScaleOffset]
		_FurLengthTex("Fur Length Texture", 2D) = "white" {}

		_FurLength("Fur Length", Float) = 0.05
		_FurDensity("Fur Density", Float) = 1024.0
		_ColorPow("Color Pow", Float) = 12.0
		
        [Toggle]
        _BakeMode("BakeMode", Int) = 0
	}

	SubShader
	{
		Pass
		{
			Cull Off

			CGPROGRAM

			#include "HuwaFurV5.hlsl"

			#pragma vertex VertexShaderStage_Skin
			#pragma fragment FragmentShaderStage_Skin

			ENDCG
		}
	}

	FallBack Off
}
