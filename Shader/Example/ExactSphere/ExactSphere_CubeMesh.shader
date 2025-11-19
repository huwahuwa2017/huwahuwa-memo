Shader "HuwaExample/ExactSphere_CubeMesh"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Background"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }

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

            #include "ExactSphere_CubeMesh.hlsl"

            ENDCG
        }
    }
}
