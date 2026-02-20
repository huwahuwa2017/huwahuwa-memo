Shader "HuwaExample/Monochrome_GeometryShader"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+1"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }
        
        GrabPass
        {
            "_MonochromeShader_Background_49326796"
        }

        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM

            #pragma require geometry

            #pragma vertex VertexShaderStage
            #pragma geometry GeometryShaderStage
            #pragma fragment FragmentShaderStage

            #include "UnityCG.cginc"

            struct Empty
            {
            };
            
            struct G2F
            {
                float4 cPos : SV_POSITION;
            };
            
            Texture2D _MonochromeShader_Background_49326796;

            void VertexShaderStage()
            {
            }
            
            [maxvertexcount(4)]
            void GeometryShaderStage(triangle Empty input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
            {
                if (primitiveID != 0)
                    return;
                
                G2F output = (G2F) 0;
                output.cPos.z = 0.5;
                output.cPos.w = 1.0;
                
                output.cPos.xy = float2(-1.0, -_ProjectionParams.x);
                // uv = float2(0.0, 0.0);
                stream.Append(output);
                
                output.cPos.xy = float2(-1.0, _ProjectionParams.x);
                // uv = float2(0.0, 1.0);
                stream.Append(output);
                
                output.cPos.xy = float2(1.0, -_ProjectionParams.x);
                // uv = float2(1.0, 0.0);
                stream.Append(output);
                
                output.cPos.xy = float2(1.0, _ProjectionParams.x);
                // uv = float2(1.0, 1.0);
                stream.Append(output);
            }

            half4 FragmentShaderStage(G2F input) : SV_Target
            {
                float3 color = _MonochromeShader_Background_49326796[uint2(input.cPos.xy)];
                float monochrome = (color.r + color.g + color.b) / 3.0;
                return float4(monochrome.xxx, 1.0);
            }

            ENDCG
        }
    }
}
