Shader "VertexDataMemory/VDM_Read"
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

			#include "UnityCG.cginc"

			struct V2F
			{
				float4 cPos : SV_POSITION;
				float3 wPos : TEXCOORD0;
			};

			Texture2D _DataTex;
			float4 _DataTex_TexelSize;

			V2F VertexShaderStage(uint vertexID : SV_VertexID)
			{
				// VDM_Writeが生成したRenderTextureの情報を読み取り、
				// 頂点のワールド座標を取得

				int2 index = int2(vertexID % _DataTex_TexelSize.z, vertexID * _DataTex_TexelSize.x);
				float3 wPos = _DataTex[index];

				V2F output = (V2F)0;
				output.cPos = mul(UNITY_MATRIX_VP, float4(wPos, 1.0));
				output.wPos = wPos;
				return output;
			}

			half4 FragmentShaderStage(V2F input) : SV_Target
			{
				float3 wPos = input.wPos;

				// 座標の可視化
				float3 color = 1.0 - abs(wPos - round(wPos)) * 2.0;
				color = color * color * color * color * color * color * color * color;

				return half4(color, 1.0);
			}

			ENDCG
		}
	}
}
