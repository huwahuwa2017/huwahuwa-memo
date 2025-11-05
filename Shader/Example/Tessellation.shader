Shader "Custom/Tessellation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _InsideTessFactor("Inside Tess Factor", Float) = 1
        _OutsideTessFactor("Outside Tess Factor", Float) = 1
    }

    SubShader
    {
        UsePass "Custom/Unlit/Main"

        Pass
        {
            CGPROGRAM

            #pragma require tessellation
			#pragma require geometry
			
			#pragma vertex VertexShaderStage
			#pragma hull HullShaderStage
			#pragma domain DomainShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

            #include "Tessellation.hlsl"

            ENDCG
        }
    }
}
