Shader "HuwaExample/ExactSphere_QuadMesh"
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

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "ExactSphere_QuadMesh.hlsl"

            ENDCG
        }
    }
}
