// Ver6 2023/10/31 08:41

Shader "HuwaShader/FurPostEffect"
{
	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest+2"
			"RenderType" = "Overlay"
		}

		GrabPass
		{
			"_FurPostEffect46390557"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Stencil
			{  
				Ref 226
				Comp equal
			}

			ZWrite Off
			ZTest Always

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

			Texture2D _FurPostEffect46390557;

			// ■■■
			// ■■■
			// ■■■

			/*
			static int _SampleCount = 9;
			
			static int2 _Offset[] =
			{
				int2(-1, -1),
				int2( 0, -1),
				int2( 1, -1),

				int2(-1,  0),
				int2( 0,  0),
				int2( 1,  0),

				int2(-1,  1),
				int2( 0,  1),
				int2( 1,  1)
			};
			*/

			//   ■■■
			// ■■■■■
			// ■■■■■
			// ■■■■■
			//   ■■■

			static int _SampleCount = 21;
			
			static int2 _Offset[] =
			{
				int2(-1, -2),
				int2( 0, -2),
				int2( 1, -2),

				int2(-2, -1),
				int2(-1, -1),
				int2( 0, -1),
				int2( 1, -1),
				int2( 2, -1),

				int2(-2,  0),
				int2(-1,  0),
				int2( 0,  0),
				int2( 1,  0),
				int2( 2,  0),

				int2(-2,  1),
				int2(-1,  1),
				int2( 0,  1),
				int2( 1,  1),
				int2( 2,  1),
				
				int2(-1,  2),
				int2( 0,  2),
				int2( 1,  2)
			};
			
			V2F VertexShaderStage(I2V input)
			{
				float4 lPos = input.lPos;
				lPos.x = -lPos.x;

				V2F output = (V2F)0;
				output.cPos = UnityObjectToClipPos(lPos);;
				return output;
			}

			half4 FragmentShaderStage(V2F input) : SV_Target
			{
				int2 target = int2(input.cPos.xy);
				float3 color = 0.0;

				for (int index = 0; index < _SampleCount; ++index)
				{
					float2 screenSize = _ScreenParams.xy;

					#if UNITY_SINGLE_PASS_STEREO
						screenSize.x += screenSize.x;
					#endif

					int2 temp0 = clamp(_Offset[index] + target, 0, screenSize);
					color += _FurPostEffect46390557[temp0].rgb;
				}

				color /= float(_SampleCount);
				return half4(color, 1.0);
			}

			ENDCG
		}
	}
}
