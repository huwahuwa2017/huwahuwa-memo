Shader "HuwaPortal/StencilDepthClear"
{
    Properties
    {
        _StencilRef("Stencil Ref", Float) = 0
    }

    SubShader
    {
        CGINCLUDE
        
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
        
        struct F2O
        {
            float depth : SV_Depth;
        };

        V2F VertexShaderStage(I2V input)
        {
            V2F output = (V2F) 0;
            output.cPos = UnityObjectToClipPos(input.lPos);
            return output;
        }

        ENDCG

        Pass
        {
            ColorMask 0
            ZTest Always

            Stencil
            {
                Ref [_StencilRef]
                Comp Equal
                Pass Keep
            }

            CGPROGRAM

            F2O FragmentShaderStage(V2F input)
            {
                // ç≈âìãóó£Ç DepthBuffer Ç…èëÇ´çûÇﬁ
                float depth;

                #if defined(UNITY_REVERSED_Z)
                    // DirectX
                    depth = 0.0;
                #else
                    // OpenGL
                    depth = 1.0;
                #endif

                F2O output = (F2O) 0;
                output.depth = depth;
                return output;
            }

            ENDCG
        }

        Pass
        {
            ColorMask 0
            ZTest Always

            Stencil
            {
                Ref [_StencilRef]
                Comp NotEqual
                Pass Keep
            }

            CGPROGRAM

            F2O FragmentShaderStage(V2F input)
            {
                // ç≈ãﬂãóó£Ç DepthBuffer Ç…èëÇ´çûÇﬁ
                float depth;

                #if defined(UNITY_REVERSED_Z)
                    // DirectX
                    depth = 1.0;
                #else
                    // OpenGL
                    depth = 0.0;
                #endif

                F2O output = (F2O) 0;
                output.depth = depth;
                return output;
            }

            ENDCG
        }
    }
}
