// v1 2025-04-08 01:59

Shader "Custom/SH_Output"
{
    SubShader
    {
        Pass
        {
            Cull Off

            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "UnityCG.cginc"

            float3 _SH_Coefficient_0;
            float3 _SH_Coefficient_1;
            float3 _SH_Coefficient_2;
            float3 _SH_Coefficient_3;
            float3 _SH_Coefficient_4;
            float3 _SH_Coefficient_5;
            float3 _SH_Coefficient_6;
            float3 _SH_Coefficient_7;
            float3 _SH_Coefficient_8;



            #define SH_Y0_0 1.0

            #define SH_Y1M1 y
            #define SH_Y1_0 z
            #define SH_Y1P1 x

            #define SH_Y2M2 x * y
            #define SH_Y2M1 y * z
            #define SH_Y2_0 (3.0 * z * z - 1.0)
            #define SH_Y2P1 z * x
            #define SH_Y2P2 (x * x - y * y)



            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float3 lPos : TEXCOORD0;
            };

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F) 0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                output.lPos = input.lPos.xyz;
                return output;
            }

            half3 FragmentShaderStage(V2F input) : SV_Target
            {
                float3 normal = normalize(input.lPos.xyz);
                float x = normal.x;
                float y = normal.y;
                float z = normal.z;

                float3 output = 0.0;

                output += _SH_Coefficient_0 * SH_Y0_0;

                output += _SH_Coefficient_1 * SH_Y1M1;
                output += _SH_Coefficient_2 * SH_Y1_0;
                output += _SH_Coefficient_3 * SH_Y1P1;

                output += _SH_Coefficient_4 * SH_Y2M2;
                output += _SH_Coefficient_5 * SH_Y2M1;
                output += _SH_Coefficient_6 * SH_Y2_0;
                output += _SH_Coefficient_7 * SH_Y2P1;
                output += _SH_Coefficient_8 * SH_Y2P2;
                
                return output;

                float3 originalColor = ShadeSH9(float4(normal, 1.0));

                return uint(_Time.y % 3.0) ? output : originalColor;
            }

            ENDCG
        }
    }
}
