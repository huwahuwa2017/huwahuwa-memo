Shader "TexelReadWrite/VertexDataWrite"
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
				uint vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct V2G
			{
				uint vertexID : TEXCOORD0;
				float4 data : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct G2F
			{
				float4 cPos : SV_POSITION;
				float4 data : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			V2G VertexShaderStage(I2V input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				// 今回は例として頂点のワールド座標を記憶させたいので、
				// とりあえずここでワールド座標を計算

				V2G output = (V2G)0;
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertexID = input.vertexID;
				output.data = mul(UNITY_MATRIX_M, input.lPos);
				return output;
			}

			[maxvertexcount(12)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream)
			{
				UNITY_SETUP_INSTANCE_ID(input[0]);

				// ここで保存したい情報をピクセルにする
				// このジオメトリシェーダーは三角ポリゴン単位で処理している

				// 頂点一個づつ(Point)で処理出来そうな気がするかもしれないが、
				// 一部の頂点が消えてしまうのでうまくいかない
				// おそらく同じパラメータを持った頂点が合成されてしまうと予想している

				G2F output = (G2F)0;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				output.data = input[0].data;
				HTRW_TEXEL_WRITE(input[0].vertexID, output.cPos, stream);
				output.data = input[1].data;
				HTRW_TEXEL_WRITE(input[1].vertexID, output.cPos, stream);
				output.data = input[2].data;
				HTRW_TEXEL_WRITE(input[2].vertexID, output.cPos, stream);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				return input.data;
			}

			ENDCG
		}
	}
}
