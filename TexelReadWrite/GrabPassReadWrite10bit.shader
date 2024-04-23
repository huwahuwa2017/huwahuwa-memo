Shader "TexelReadWrite/GrabPassReadWrite10bit"
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

			[maxvertexcount(36)]
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
				float4 data2;
				uint3 temp0;
				uint vid;

				temp0 = asuint(input[0].data.xyz);
				vid = input[0].vertexID * 3;

				data0 = R10bitToFP16(uint4(temp0.x, temp0.x >> 10, temp0.x >> 20, temp0.x >> 30));
				data1 = R10bitToFP16(uint4(temp0.y, temp0.y >> 10, temp0.y >> 20, temp0.y >> 30));
				data2 = R10bitToFP16(uint4(temp0.z, temp0.z >> 10, temp0.z >> 20, temp0.z >> 30));

				output.data = data0;
				HPRW_TEXEL_WRITE(vid, output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_WRITE(vid + 1, output.cPos, stream);
				output.data = data2;
				HPRW_TEXEL_WRITE(vid + 2, output.cPos, stream);

				temp0 = asuint(input[1].data.xyz);
				vid = input[1].vertexID * 3;
				
				data0 = R10bitToFP16(uint4(temp0.x, temp0.x >> 10, temp0.x >> 20, temp0.x >> 30));
				data1 = R10bitToFP16(uint4(temp0.y, temp0.y >> 10, temp0.y >> 20, temp0.y >> 30));
				data2 = R10bitToFP16(uint4(temp0.z, temp0.z >> 10, temp0.z >> 20, temp0.z >> 30));

				output.data = data0;
				HPRW_TEXEL_WRITE(vid, output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_WRITE(vid + 1, output.cPos, stream);
				output.data = data2;
				HPRW_TEXEL_WRITE(vid + 2, output.cPos, stream);

				temp0 = asuint(input[2].data.xyz);
				vid = input[2].vertexID * 3;
				
				data0 = R10bitToFP16(uint4(temp0.x, temp0.x >> 10, temp0.x >> 20, temp0.x >> 30));
				data1 = R10bitToFP16(uint4(temp0.y, temp0.y >> 10, temp0.y >> 20, temp0.y >> 30));
				data2 = R10bitToFP16(uint4(temp0.z, temp0.z >> 10, temp0.z >> 20, temp0.z >> 30));

				output.data = data0;
				HPRW_TEXEL_WRITE(vid, output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_WRITE(vid + 1, output.cPos, stream);
				output.data = data2;
				HPRW_TEXEL_WRITE(vid + 2, output.cPos, stream);
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

				uint vid = input.vertexID * 3;

				float4 data0, data1, data2;
				HPRW_GRAB_PASS_TEXEL_READ(_HuwaGrabPass_27349865, vid, data0);
				HPRW_GRAB_PASS_TEXEL_READ(_HuwaGrabPass_27349865, vid + 1, data1);
				HPRW_GRAB_PASS_TEXEL_READ(_HuwaGrabPass_27349865, vid + 2, data2);

				uint4 data3 = FP16ToR10bit(data0);
				uint4 data4 = FP16ToR10bit(data1);
				uint4 data5 = FP16ToR10bit(data2);

				uint3 data6 = 0;
				data6.x = data3.x | (data3.y << 10) | (data3.z << 20) | (data3.w << 30);
				data6.y = data4.x | (data4.y << 10) | (data4.z << 20) | (data4.w << 30);
				data6.z = data5.x | (data5.y << 10) | (data5.z << 20) | (data5.w << 30);

				float3 wPos = asfloat(data6);

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
