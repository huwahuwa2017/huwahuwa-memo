Shader "TexelReadWrite/PolygonDataWrite"
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
			ZTest Always

			// ステンシルテストを常に失敗するようにする
			// これによりRenderTextureの設定のDepth Bufferが「No depth Buffer」か
			// 「At least 16bits depth (no stencil)」になっているRenderTextureを
			// TargetTextureに設定しているカメラにしか写らなくすることができる
			// (LayerとCullingMaskを設定すれば十分じゃんというツッコミは無しで)
			Stencil
			{
				Comp Never
			}

			CGPROGRAM

			#pragma require geometry
			#pragma vertex VertexShaderStage
			#pragma geometry GeometryShaderStage
			#pragma fragment FragmentShaderStage

			#include "HuwaTexelReadWrite.hlsl"

			struct I2V
			{
				float4 lPos : POSITION;
			};

			struct V2G
			{
				float4 data : TEXCOORD0;
			};

			struct G2F
			{
				float4 cPos : SV_POSITION;
				float4 data : TEXCOORD0;
			};

			V2G VertexShaderStage(I2V input)
			{
				// 今回は例としてポリゴンの中心のワールド座標を記憶させたいので、
				// とりあえずここでワールド座標を計算

				V2G output = (V2G)0;
				output.data = mul(UNITY_MATRIX_M, input.lPos);
				return output;
			}

			[maxvertexcount(4)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
			{
				// ここで保存したい情報をピクセルにする
				// このジオメトリシェーダーは三角ポリゴン単位で処理している
				
				G2F output = (G2F)0;
				output.data = (input[0].data + input[1].data + input[2].data) / 3.0;;
				HPRW_TEXEL_GENERATION(primitiveID, output.cPos, stream);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				return input.data;
			}

			ENDCG
		}
	}
}
