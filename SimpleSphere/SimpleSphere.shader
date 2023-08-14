Shader "Custom/SimpleSphere"
{
	SubShader
	{
		Pass
		{
			Cull Front

			CGPROGRAM

			#pragma vertex VertexShaderStage
			#pragma fragment FragmentShaderStage

			#include "SimpleSphere.hlsl"

			ENDCG
		}
	}
}
