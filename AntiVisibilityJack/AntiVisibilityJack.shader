Shader "AntiVisibilityJack/AntiVisibilityJack"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Overlay+815199"
			"RenderType" = "Overlay"
		}

		Pass
		{
			ZWrite Off
			ZTest Always

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
				float4 grabPos : TEXCOORD0;
			};

			sampler2D _AVJ_BackgroundTexture;

			V2F VertexShaderStage(I2V input)
			{
				V2F output = (V2F)0;
				output.cPos = float4(input.uv * 2.0 - 1.0, 1.0, 1.0);
				output.cPos.y = output.cPos.y * _ProjectionParams.x;
				output.grabPos = ComputeGrabScreenPos(output.cPos);
				return output;
			}

			fixed4 FragmentShaderStage(V2F input) : SV_Target
			{
				return tex2Dproj(_AVJ_BackgroundTexture, input.grabPos);
			}

			ENDCG
		}
	}
}