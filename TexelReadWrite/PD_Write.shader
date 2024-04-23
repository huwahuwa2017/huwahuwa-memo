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
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct V2G
			{
				float4 data : TEXCOORD0;
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

				// 今回は例としてポリゴンの中心のワールド座標を記憶させたいので、
				// とりあえずここでワールド座標を計算

				V2G output = (V2G)0;
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.data = mul(UNITY_MATRIX_M, input.lPos);
				return output;
			}

			[maxvertexcount(4)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
			{
				UNITY_SETUP_INSTANCE_ID(input[0]);

				// ここで保存したい情報をピクセルにする
				// このジオメトリシェーダーは三角ポリゴン単位で処理している
				
				G2F output = (G2F)0;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				output.data = (input[0].data + input[1].data + input[2].data) / 3.0;
				HPRW_TEXEL_WRITE(primitiveID, output.cPos, stream);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				return input.data;
			}

			ENDCG
		}
	}
}
