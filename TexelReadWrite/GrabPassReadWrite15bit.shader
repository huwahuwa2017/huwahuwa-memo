Shader "TexelReadWrite/GrabPassReadWrite15bit"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Background-1000"
		}

		Pass
		{
			ZTest Always
			ZWrite Off

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

			[maxvertexcount(24)]
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

				float4 data0;
				float4 data1;
				uint3 temp0;

				temp0 = asuint(input[0].data.xyz);

				data0.xyz = R15bitToFP16(temp0);
				data1.xyz = R15bitToFP16(temp0 >> 15);
				temp0 &= 0xC0000000;
				data0.w = R15bitToFP16((temp0.x >> 30) | (temp0.y >> 28) | (temp0.z >> 26));
				data1.w = 0.0;

				output.data = data0;
				HPRW_TEXEL_WRITE(input[0].vertexID * 2, output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_WRITE(input[0].vertexID * 2 + 1, output.cPos, stream);

				temp0 = asuint(input[1].data.xyz);
				
				data0.xyz = R15bitToFP16(temp0);
				data1.xyz = R15bitToFP16(temp0 >> 15);
				temp0 &= 0xC0000000;
				data0.w = R15bitToFP16((temp0.x >> 30) | (temp0.y >> 28) | (temp0.z >> 26));
				data1.w = 0.0;

				output.data = data0;
				HPRW_TEXEL_WRITE(input[1].vertexID * 2, output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_WRITE(input[1].vertexID * 2 + 1, output.cPos, stream);

				temp0 = asuint(input[2].data.xyz);
				
				data0.xyz = R15bitToFP16(temp0);
				data1.xyz = R15bitToFP16(temp0 >> 15);
				temp0 &= 0xC0000000;
				data0.w = R15bitToFP16((temp0.x >> 30) | (temp0.y >> 28) | (temp0.z >> 26));
				data1.w = 0.0;

				output.data = data0;
				HPRW_TEXEL_WRITE(input[2].vertexID * 2, output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_WRITE(input[2].vertexID * 2 + 1, output.cPos, stream);
			}

			float4 FragmentShaderStage(G2F input) : SV_Target
			{
				return input.data;
			}

			ENDCG
		}

		GrabPass
		{
			"_HuwaGrabPass_27349865"
		}

		Pass
		{
			Cull Off

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

			#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
				Texture2DArray _HuwaGrabPass_27349865;
			#else
				Texture2D _HuwaGrabPass_27349865;
			#endif

			V2F VertexShaderStage(I2V input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				// _HuwaGrabPass_27349865 の情報を読み取り、頂点のワールド座標を取得

				uint vid = input.vertexID * 2;
				
				float4 data0, data1;
				HPRW_GRAB_PASS_TEXEL_READ(_HuwaGrabPass_27349865, vid, data0);
				HPRW_GRAB_PASS_TEXEL_READ(_HuwaGrabPass_27349865, vid + 1, data1);

				uint4 data2 = FP16ToR15bit(data0);
				uint4 data3 = FP16ToR15bit(data1);

				uint3 data4 = (data2.xyz | (data3.xyz << 15));
				data4.x |= (data2.w & 0x00000003) << 30;
				data4.y |= (data2.w & 0x0000000C) << 28;
				data4.z |= (data2.w & 0x00000030) << 26;

				float3 wPos = asfloat(data4);

				V2F output = (V2F)0;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				output.cPos = mul(UNITY_MATRIX_VP, float4(wPos, 1.0));
				output.wPos = wPos;
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
