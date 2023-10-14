Shader "PolygonDataMemory/Read"
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

			struct I2V
			{
				float4 lPos : POSITION;
			};

			struct V2G
			{
				float4 cPos : TEXCOORD0;
			};

			struct G2F
			{
				float4 cPos : SV_POSITION;
				float3 wPos : TEXCOORD0;
			};

			Texture2D _DataTex;
			float4 _DataTex_TexelSize;

			#define SetDataTextureTexelSize _DataTex_TexelSize
			#include "HuwaPixcelReadWrite.hlsl"

			V2G VertexShaderStage(I2V input)
			{
				V2G output = (V2G)0;
				output.cPos = UnityObjectToClipPos(input.lPos);
				return output;
			}

			[maxvertexcount(3)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
			{
				// VDM_Writeが生成したRenderTextureの情報を読み取り、
				// ポリゴンの中心のワールド座標を取得
				
				float4 data = GetPixcelData(_DataTex, primitiveID);

				G2F output = (G2F)0;
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
