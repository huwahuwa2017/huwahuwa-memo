Shader "Custom/HuwaDigitalRain"
{
    Properties
    {
        [NoScaleOffset]
        _MainTex("MainTex", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM

            #include "HuwaDigitalRain.hlsl"
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup

            ENDCG
        }
    }
}
