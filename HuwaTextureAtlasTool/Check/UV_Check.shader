Shader "HuwaTextureAtlasTool/UV_Check"
{
    Properties
    {
        [KeywordEnum(CHANNEL_0, CHANNEL_1, CHANNEL_2, CHANNEL_3, CHANNEL_4, CHANNEL_5, CHANNEL_6, CHANNEL_7)]
        TARGET_UV("UV channel", Int) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+1"
        }

        Pass
        {
            Cull Off
            ZTest Always

            CGPROGRAM
            
            #pragma require geometry

            #pragma multi_compile_local TARGET_UV_CHANNEL_0 TARGET_UV_CHANNEL_1 TARGET_UV_CHANNEL_2 TARGET_UV_CHANNEL_3 TARGET_UV_CHANNEL_4 TARGET_UV_CHANNEL_5 TARGET_UV_CHANNEL_6 TARGET_UV_CHANNEL_7

            #pragma vertex VertexShaderStage
            #pragma geometry GeometryShaderStage
            #pragma fragment FragmentShaderStage

            #if defined(TARGET_UV_CHANNEL_0)
            #define TARGET_UV_CHANNEL TEXCOORD0
            #elif defined(TARGET_UV_CHANNEL_1)
            #define TARGET_UV_CHANNEL TEXCOORD1
            #elif defined(TARGET_UV_CHANNEL_2)
            #define TARGET_UV_CHANNEL TEXCOORD2
            #elif defined(TARGET_UV_CHANNEL_3)
            #define TARGET_UV_CHANNEL TEXCOORD3
            #elif defined(TARGET_UV_CHANNEL_4)
            #define TARGET_UV_CHANNEL TEXCOORD4
            #elif defined(TARGET_UV_CHANNEL_5)
            #define TARGET_UV_CHANNEL TEXCOORD5
            #elif defined(TARGET_UV_CHANNEL_6)
            #define TARGET_UV_CHANNEL TEXCOORD6
            #elif defined(TARGET_UV_CHANNEL_7)
            #define TARGET_UV_CHANNEL TEXCOORD7
            #else
            #define TARGET_UV_CHANNEL TEXCOORD0
            #endif

            struct I2V
            {
                float2 uv : TARGET_UV_CHANNEL;
            };

            struct V2G
            {
                float4 cPos : TEXCOORD0;
            };
            
            struct G2F
            {
                float4 cPos : SV_POSITION;
            };

            V2G VertexShaderStage(I2V input)
            {
                V2G output = (V2G) 0;
                output.cPos = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
                
                #if UNITY_UV_STARTS_AT_TOP
                    output.cPos.y = -output.cPos.y;
                #endif
                
                return output;
            }

            [maxvertexcount(4)]
            void GeometryShaderStage(triangle V2G input[3], inout LineStream<G2F> stream)
            {
                G2F output = (G2F) 0;
                
                output.cPos = input[0].cPos;
                stream.Append(output);
                
                output.cPos = input[1].cPos;
                stream.Append(output);

                output.cPos = input[2].cPos;
                stream.Append(output);
                
                output.cPos = input[0].cPos;
                stream.Append(output);
            }

            float4 FragmentShaderStage(G2F input) : SV_Target
            {
                return 1.0;
            }

            ENDCG
        }
    }
}
