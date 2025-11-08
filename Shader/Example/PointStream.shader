Shader "HuwaExample/PointStream"
{
	Properties
    {
		[IntRange]
        _Subdivision("Subdivision", Range (0, 10)) = 6
    }

	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

			#include "PointStream.hlsl"

			ENDCG
		}
	}
}
