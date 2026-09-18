Shader "HuwaPortal/PreProcess"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry-1999"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }
        
        Pass
        {
            ColorMask 0
            ZTest Always
            ZWrite On

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "UnityCG.cginc"

            struct I2V
            {
                float2 uv : TEXCOORD0;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
            };
            
            Texture2D<uint> _MainTex;

            uint _StencilA;

            V2F VertexShaderStage(I2V input)
            {
                float4 cPos = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
                cPos.y *= _ProjectionParams.x;

                V2F output = (V2F)0;
                output.cPos = cPos;
                return output;
            }

            float FragmentShaderStage(V2F input) : SV_Depth
            {
                #if defined(UNITY_REVERSED_Z)
                    // DirectX
                    float nearDepth = 1.0;
                    float farDepth = 0.0;
                #else
                    // OpenGL
                    float nearDepth = 0.0;
                    float farDepth = 1.0;
                #endif

                uint data = _MainTex[uint2(input.cPos.xy)].x;
                float depth = (data == _StencilA) ? farDepth : nearDepth;
                depth = (_StencilA > 255) ? farDepth : depth;
                return depth;
            }

            ENDCG
        }
    }
}
