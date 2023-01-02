Shader "FlowPaintTool2/WireFrame"
{
	Properties
	{
		_MainColor("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_WireFrameColor("Wire Frame Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Width("Width", Range(0.0, 2.0)) = 1.0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Geometry"
			"RenderType" = "Opaque"
		}

		Pass
		{
			CGPROGRAM

			#pragma require geometry
			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

			#include "UnityCG.cginc"

			struct IA2VS
			{
				float4 lPos : POSITION;
			};

			struct VS2GS
			{
				float4 cPos : TEXCOORD0;
			};

			struct GS2FS
			{
				float4 cPos : SV_POSITION;
				float3 distance : TEXCOORD0;
			};

			fixed4 _MainColor;
			fixed4 _WireFrameColor;
			float _Width;

			VS2GS VertexShaderStage(IA2VS input)
			{
				VS2GS output = (VS2GS)0;
				output.cPos = UnityObjectToClipPos(input.lPos);
				return output;
			}

			[maxvertexcount(3)]
			void GeometryShaderStage(triangle VS2GS input[3], inout TriangleStream<GS2FS> stream)
			{
				float2 pos0 = input[0].cPos.xy * _ScreenParams.xy / input[0].cPos.w;
				float2 pos1 = input[1].cPos.xy * _ScreenParams.xy / input[1].cPos.w;
				float2 pos2 = input[2].cPos.xy * _ScreenParams.xy / input[2].cPos.w;

				float2 side0 = pos2 - pos1;
				float2 side1 = pos0 - pos2;
				float2 side2 = pos1 - pos0;

				float area = abs(side0.x * side1.y - side0.y * side1.x);

				GS2FS output = (GS2FS)0;

				output.cPos = input[0].cPos;
				output.distance = float3(area / length(side0), 0.0, 0.0);
				stream.Append(output);

				output.cPos = input[1].cPos;
				output.distance = float3(0.0, area / length(side1), 0.0);
				stream.Append(output);

				output.cPos = input[2].cPos;
				output.distance = float3(0.0, 0.0, area / length(side2));
				stream.Append(output);
			}

			half4 FragmentShaderStage(GS2FS input) : SV_Target
			{
				bool flag = (input.distance.x < _Width) || (input.distance.y < _Width) || (input.distance.z < _Width);
				return lerp(_MainColor, _WireFrameColor, flag);
			}

			ENDCG
		}
	}
}
