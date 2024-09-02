Shader "Custom/Mandelbox3"
{
	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest"
			"RenderType" = "TransparentCutout"
			"DisableBatching" = "True"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			
			Cull Front

			CGPROGRAM

			#pragma require geometry
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap

			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

			#include "Mandelbox3.hlsl"

			ENDCG
		}
	}
}
