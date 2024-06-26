﻿Shader "TexelReadWrite/VertexDataRead"
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
			#pragma fragment FragmentShaderStage
			
			#include "HuwaTexelReadWrite.hlsl"

			struct I2V
			{
				uint vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct V2F
			{
				float4 cPos : SV_POSITION;
				float3 wPos : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Texture2D _DataTex;
			float4 _DataTex_TexelSize;
			
			V2F VertexShaderStage(I2V input)
			{
				UNITY_SETUP_INSTANCE_ID(input)

				// VDM_Writeが生成したRenderTextureの情報を読み取り、
				// 頂点のワールド座標を取得

				float4 data;
				HTRW_TEXEL_READ(_DataTex, input.vertexID, data);
				data.a = 1.0;

				V2F output = (V2F)0;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				output.cPos = mul(UNITY_MATRIX_VP, data);
				output.wPos = data;
				return output;
			}

			float4 FragmentShaderStage(V2F input) : SV_Target
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
