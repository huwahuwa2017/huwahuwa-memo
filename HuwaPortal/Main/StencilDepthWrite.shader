Shader "HuwaPortal/StencilDepthWrite"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            CGPROGRAM
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "Common.hlsl"

            uint FragmentShaderStage(V2F input) : SV_Target
            {
                return _StencilRef;
            }

            ENDCG
        }
    }
}
