Shader "HuwaPortal/StencilReplace"
{
    Properties
    {
        _StencilA("Stencil A", Float) = 0
        _StencilB("Stencil B", Float) = 0
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

        // 最近距離で塗りつぶす
        Pass
        {
            ColorMask 0
            ZTest Always

            CGPROGRAM

            F2O FragmentShaderStage(V2F input)
            {
                // 最近距離を DepthBuffer に書き込む
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

        // Stencil が _StencilA と同じピクセルの Depth を最遠距離にする
        Pass
        {
            ColorMask 0
            ZTest Always

            Stencil
            {
                Ref [_StencilA]
                Comp Equal
                Pass Keep
            }

            CGPROGRAM

            F2O FragmentShaderStage(V2F input)
            {
                // 最遠距離を DepthBuffer に書き込む
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

        // 0.5 より遠い Depth が書き込まれているピクセルの Stencil を _StencilB にする
        Pass
        {
            ColorMask 0
            ZWrite Off

            Stencil
            {
                Ref [_StencilB]
                Comp Always
                Pass Replace
            }

            CGPROGRAM

            F2O FragmentShaderStage(V2F input)
            {
                F2O output = (F2O) 0;
                output.depth = 0.5;
                return output;
            }

            ENDCG
        }
    }
}
