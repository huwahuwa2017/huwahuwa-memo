// MIT License
// Copyright (c) 2022 huwahuwa2017
// https://github.com/huwahuwa2017/huwahuwa-memo/blob/main/LICENSE

Shader "Custom/AlexanderHornedSphere"
{
	Properties
    {
        _Thickness("Thickness", Range(0.0, 1.0)) = 0.02
        _Size("Size", Range(0.0, 1.0)) = 0.82
        _Cut("Cut", Range(0.0, 1.0)) = 0.21
    }

	SubShader
	{
		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Cull Front

			CGPROGRAM

			#pragma vertex VertexShaderStage
			#pragma fragment FragmentShaderStage

			#include "AlexanderHornedSphere.hlsl"

			ENDCG
		}
	}
}
