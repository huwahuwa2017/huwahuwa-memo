Shader "HuwaPortal/StencilDepthWrite"
{
    Properties
    {
        _StencilRef("Stencil Ref", Float) = 0
    }

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
            ColorMask 0

            Stencil
            {
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            CGPROGRAM
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "UnityCG.cginc"

            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
            };
            
            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F) 0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                return 1.0;
            }

            ENDCG
        }
    }
}
