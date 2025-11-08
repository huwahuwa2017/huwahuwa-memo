Shader "HuwaExample/FullScreen_(Geometry)"
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
                float2 uv : TEXCOORD0;
            };

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
                output.uv = float2(0.0, 0.0);
                stream.Append(output);
    
                output.cPos.xy = float2(-1.0, _ProjectionParams.x);
                output.uv = float2(0.0, 1.0);
                stream.Append(output);
    
                output.cPos.xy = float2(1.0, -_ProjectionParams.x);
                output.uv = float2(1.0, 0.0);
                stream.Append(output);
    
                output.cPos.xy = float2(1.0, _ProjectionParams.x);
                output.uv = float2(1.0, 1.0);
                stream.Append(output);
            }

            half4 FragmentShaderStage(G2F input) : SV_Target
            {
                return half4(input.uv, 0.0, 1.0);
            }

			ENDCG
		}
	}
}
