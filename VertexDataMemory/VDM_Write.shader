Shader "VertexDataMemory/VDM_Write"
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

			#include "UnityCG.cginc"

			struct I2V
			{
				float4 lPos : POSITION;
			};

			struct V2G
			{
				uint vertexID : TEXCOORD0;
				float4 data : TEXCOORD1;
			};

			struct G2F
			{
				float4 cPos : SV_POSITION;
				float4 data : TEXCOORD0;
			};

			static float2 _ClipSpacePixcelSize = float2(2.0 / _ScreenParams.x, 2.0 / _ScreenParams.y);

			static float2 _PositionOffset[] =
			{
				float2(0.0, 0.0),
				float2(_ClipSpacePixcelSize.x, 0.0),
				float2(0.0, _ClipSpacePixcelSize.y),
				_ClipSpacePixcelSize
			};

			V2G VertexShaderStage(I2V input, uint vertexID : SV_VertexID)
			{
				// 今回は例として頂点のワールド座標を記憶させたいので、
				// とりあえずここでワールド座標を計算

				V2G output = (V2G)0;
				output.vertexID = vertexID;
				output.data = mul(UNITY_MATRIX_M, input.lPos);
				return output;
			}

			void PixcelGeneration(uint vertexID, float4 data, inout TriangleStream<G2F> stream)
			{
				float2 pos = float2(vertexID % _ScreenParams.x, floor(vertexID / _ScreenParams.x));
				pos = pos * _ClipSpacePixcelSize - 1.0;

				#if UNITY_UV_STARTS_AT_TOP
					pos.y = -pos.y - _ClipSpacePixcelSize.y;
				#endif

				G2F output = (G2F)0;
				output.data = data;

				output.cPos = float4(pos + _PositionOffset[0], 0.0, 1.0);
				stream.Append(output);
				output.cPos = float4(pos + _PositionOffset[1], 0.0, 1.0);
				stream.Append(output);
				output.cPos = float4(pos + _PositionOffset[2], 0.0, 1.0);
				stream.Append(output);
				output.cPos = float4(pos + _PositionOffset[3], 0.0, 1.0);
				stream.Append(output);

				stream.RestartStrip();
			}

			[maxvertexcount(12)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream)
			{
				// ここで保存したい情報をピクセルにする
				// このジオメトリシェーダーは三角ポリゴン単位で処理している

				// 頂点一個づつ(Point)で処理出来そうな気がするかもしれないが、
				// 一部の頂点が消えてしまうのでうまくいかない
				// おそらく同じパラメータを持った頂点が合成されてしまうと予想している

				PixcelGeneration(input[0].vertexID, input[0].data, stream);
				PixcelGeneration(input[1].vertexID, input[1].data, stream);
				PixcelGeneration(input[2].vertexID, input[2].data, stream);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				return input.data;
			}

			ENDCG
		}
	}
}
