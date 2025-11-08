Shader "HuwaExample/LineStream"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

			#include "LineStream.hlsl"

			ENDCG
		}
	}
}
