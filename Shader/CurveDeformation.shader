Shader "CDS/CurveDeformation"
{
	Properties
	{
		[NoScaleOffset]
		_MainTex("Texture", 2D) = "white" {}
		_Length("Length", float) = 1.0
		_AttractDistance("Attract distance", float) = 2.0
		_Division("Division", int) = 100
		_ColorIntensity("Color intensity", Range(0.0, 1.0)) = 0.0625
		_AmbientColor("Ambient color", Color) = (0.125, 0.25, 0.25)
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"LightMode" = "Vertex"
		}

		Pass
		{
			CGPROGRAM

			#include "CurveDeformation.hlsl"

			#pragma vertex Vert
			#pragma fragment Frag

			ENDCG
		}
	}
}
