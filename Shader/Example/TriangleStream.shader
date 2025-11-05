Shader "Custom/TriangleStream"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

			#include "TriangleStream.hlsl"

			ENDCG
		}
	}
}
