﻿Shader "TexelReadWrite/GrabPassReadWrite14bit"
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

			V2G VertexShaderStage(I2V input)
			{
				// 今回は例として頂点のワールド座標を記憶させたいので、
				// とりあえずここでワールド座標を計算

				V2G output = (V2G)0;
				output.vertexID = input.vertexID;
				output.data = mul(UNITY_MATRIX_M, input.lPos);
				return output;
			}

			[maxvertexcount(24)]
			void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream)
			{
				// ここで保存したい情報をピクセルにする
				// このジオメトリシェーダーは三角ポリゴン単位で処理している

				// 頂点一個づつ(Point)で処理出来そうな気がするかもしれないが、
				// 一部の頂点が消えてしまうのでうまくいかない
				// おそらく同じパラメータを持った頂点が合成されてしまうと予想している

				G2F output = (G2F)0;

				float4 data0;
				float4 data1;
				uint3 temp0;

				temp0 = asuint(input[0].data.xyz);

				data0.xyz = L14bitToFP16(temp0);
				data1.xyz = L14bitToFP16(temp0 << 14);
				temp0 &= 0x0000000F;
				data0.w = L14bitToFP16((temp0.x << 28) | (temp0.y << 24) | (temp0.z << 20));
				data1.w = 0.0;

				output.data = data0;
				HPRW_TEXEL_GENERATION((input[0].vertexID * 2), output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_GENERATION((input[0].vertexID * 2 + 1), output.cPos, stream);

				temp0 = asuint(input[1].data.xyz);

				data0.xyz = L14bitToFP16(temp0);
				data1.xyz = L14bitToFP16(temp0 << 14);
				temp0 &= 0x0000000F;
				data0.w = L14bitToFP16((temp0.x << 28) | (temp0.y << 24) | (temp0.z << 20));
				data1.w = 0.0;

				output.data = data0;
				HPRW_TEXEL_GENERATION((input[1].vertexID * 2), output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_GENERATION((input[1].vertexID * 2 + 1), output.cPos, stream);

				temp0 = asuint(input[2].data.xyz);

				data0.xyz = L14bitToFP16(temp0);
				data1.xyz = L14bitToFP16(temp0 << 14);
				temp0 &= 0x0000000F;
				data0.w = L14bitToFP16((temp0.x << 28) | (temp0.y << 24) | (temp0.z << 20));
				data1.w = 0.0;

				output.data = data0;
				HPRW_TEXEL_GENERATION((input[2].vertexID * 2), output.cPos, stream);
				output.data = data1;
				HPRW_TEXEL_GENERATION((input[2].vertexID * 2 + 1), output.cPos, stream);
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

			struct I2V
			{
				uint vertexID : SV_VertexID;
			};

			struct V2F
			{
				float4 cPos : SV_POSITION;
				float3 wPos : TEXCOORD0;
			};

			Texture2D _HuwaGrabPass_27349865;

			#include "HuwaTexelReadWrite.hlsl"

			V2F VertexShaderStage(I2V input)
			{
				// _HuwaGrabPass_27349865 の情報を読み取り、頂点のワールド座標を取得

				uint vid = input.vertexID * 2;

				float4 data0 = HPRW_GET_TEXEL_DATA(_HuwaGrabPass_27349865, vid);
				float4 data1 = HPRW_GET_TEXEL_DATA(_HuwaGrabPass_27349865, vid + 1);

				uint4 data2 = FP16ToL14bit(data0);
				uint4 data3 = FP16ToL14bit(data1);

				uint3 data4 = (data2.xyz | (data3.xyz >> 14));
				data4.x |= (data2.w & 0xC0000000) >> 28;
				data4.y |= (data2.w & 0x30000000) >> 24;
				data4.z |= (data2.w & 0x0C000000) >> 20;

				float3 wPos = float4(asfloat(data4), 1.0);

				V2F output = (V2F)0;
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
