Shader "PolygonDataMemory/Write"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Overlay+1"
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

			#include "PixcelReadWrite.hlsl"

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

			void PixcelGeneration(uint id, float4 data, inout TriangleStream<G2F> stream)
			{
				float2 cPos = GetPixcelPosition(id);

				G2F output = (G2F)0;
				output.data = data;
				output.cPos.w = 1.0;

				output.cPos.xy = cPos + _ClipSpacePixcelOffset[0];
				stream.Append(output);
				output.cPos.xy = cPos + _ClipSpacePixcelOffset[1];
				stream.Append(output);
				output.cPos.xy = cPos + _ClipSpacePixcelOffset[2];
				stream.Append(output);
				output.cPos.xy = cPos + _ClipSpacePixcelOffset[3];
				stream.Append(output);

				stream.RestartStrip();
			}

			[maxvertexcount(4)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
			{
				// ここで保存したい情報をピクセルにする
				// このジオメトリシェーダーは三角ポリゴン単位で処理している
				
				float4 data = (input[0].data + input[1].data + input[2].data) / 3.0;

				PixcelGeneration(primitiveID, data, stream);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				return input.data;
			}

			ENDCG
		}
	}
}
