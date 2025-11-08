Shader "HuwaExample/FullScreen_(QuadMesh)"
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
                float2 uv : TEXCOORD0;
            };

            V2F VertexShaderStage(I2V input)
            {
                float4 cPos = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
                cPos.y *= _ProjectionParams.x;

                V2F output = (V2F) 0;
                output.cPos = cPos;
                output.uv = input.uv;
                return output;
            }
            
            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                return half4(input.uv, 0.0, 1.0);
            }

			ENDCG
		}
	}
}
