
Shader "Custom/AntiAliasing_1"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "black" {}

        [Toggle(_)]
        _Difference("Difference", Int) = 0
        
        [Toggle(_)]
        _ViewOriginalColor("ViewOriginalColor", Int) = 0

        _OffsetLOD("OffsetLOD", Range(-4.0, 4.0)) = 0.0
    }

    SubShader
    {
        Pass
        {
            Cull Off

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "AntiAliasing_1.hlsl"

            ENDCG
        }
    }
}
