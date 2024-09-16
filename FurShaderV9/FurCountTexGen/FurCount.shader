Shader "huwahuwa/FurCount"
{
	SubShader
	{
		Pass
		{
			ZTest Always

			CGPROGRAM

			#pragma require geometry
			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage
			
			#include "FurCount.hlsl"

			ENDCG
		}
	}
}
