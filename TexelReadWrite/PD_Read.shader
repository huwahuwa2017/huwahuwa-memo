Shader "TexelReadWrite/PolygonDataRead"
{
	Properties
	{
		[NoScaleOffset]
		_DataTex("Data Texture", 2D) = "black" {}
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

			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage
			
			#include "HuwaTexelReadWrite.hlsl"

			struct I2V
			{
				float4 lPos : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct V2G
			{
				float4 cPos : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct G2F
			{
				float4 cPos : SV_POSITION;
				float3 wPos : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Texture2D _DataTex;
			float4 _DataTex_TexelSize;

			V2G VertexShaderStage(I2V input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				V2G output = (V2G)0;
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.cPos = UnityObjectToClipPos(input.lPos);
				return output;
			}

			[maxvertexcount(3)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
			{
				UNITY_SETUP_INSTANCE_ID(input[0]);

				// VDM_Writeが生成したRenderTextureの情報を読み取り、
				// ポリゴンの中心のワールド座標を取得
				
				float4 data;
				HPRW_TEXEL_READ(_DataTex, primitiveID, data);

				G2F output = (G2F)0;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				output.wPos = data;

				output.cPos = input[0].cPos;
				stream.Append(output);
				output.cPos = input[1].cPos;
				stream.Append(output);
				output.cPos = input[2].cPos;
				stream.Append(output);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				float3 wPos = input.wPos;

				// 座標の可視化
				float3 color = 1.0 - abs(wPos - round(wPos)) * 2.0;
				color = color * color * color * color * color * color * color * color;

				return float4(color, 1.0);
			}

			ENDCG
		}
	}
}
