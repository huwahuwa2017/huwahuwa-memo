Shader "Custom/Mandelbox2"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
		}

		Pass
		{
			ZWrite ON
			Cull Off
			ColorMask 0

			CGPROGRAM

			#include "Mandelbox2.hlsl"
			#pragma require geometry
			#pragma vertex VertexStage
			#pragma geometry GeometryStage
			#pragma fragment FragmentStage_Depth

			ENDCG
		}

		Pass
		{
			ZWrite Off
			Cull Off

			Tags
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#include "Mandelbox2.hlsl"
			#pragma require geometry
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadow
			#pragma vertex VertexStage
			#pragma geometry GeometryStage
			#pragma fragment FragmentStage

			ENDCG
		}
	}
}
