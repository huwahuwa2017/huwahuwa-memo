Shader "huwahuwa/Normalize"
{
	Properties
	{
		// Input from Blit
		[HideInInspector]
		_MainTex("Main Texture", 2D) = "white" {}
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex VertexShaderStage
			#pragma fragment FragmentShaderStage

			#include "UnityCG.cginc"

			struct I2V
			{
				float4 lPos : POSITION;
			};

			struct V2F
			{
			    float4 cPos : SV_POSITION;
			};

			Texture2D _MainTex;
			float _MaximumValue;

			V2F VertexShaderStage(I2V input)
			{
				V2F output = (V2F) 0;
				output.cPos = UnityObjectToClipPos(input.lPos);
				return output;
			}

			float4 FragmentShaderStage(V2F input) : SV_Target
			{
				float data = _MainTex[uint2(input.cPos.xy)].r / _MaximumValue;

				return float4(data, 0.0, 0.0, 1.0);
			}

			ENDCG
		}
	}
}
