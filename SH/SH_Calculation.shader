// v1 2025-04-08 01:59

Shader "Custom/SH_Calculation"
{
    SubShader
    {
        Pass
        {
            ZWrite Off

            CGPROGRAM

            #pragma multi_compile_local SH_0 SH_1 SH_2 SH_3 SH_4 SH_5 SH_6 SH_7 SH_8

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "UnityCG.cginc"
            
            SamplerState _InlineSampler_Point_Clamp;

            TextureCube _CubeMap;
            float4 _CubeMap_TexelSize;



            #define SH_Y0_0 1.0

            #define SH_Y1M1 y
            #define SH_Y1_0 z
            #define SH_Y1P1 x

            #define SH_Y2M2 x * y
            #define SH_Y2M1 y * z
            #define SH_Y2_0 (3.0 * z * z - 1.0)
            #define SH_Y2P1 z * x
            #define SH_Y2P2 (x * x - y * y)



            #if defined(SH_0)
                #define TARGET_SH SH_Y0_0
            #elif defined(SH_1)
                #define TARGET_SH SH_Y1M1
            #elif defined(SH_2)
                #define TARGET_SH SH_Y1_0
            #elif defined(SH_3)
                #define TARGET_SH SH_Y1P1
            #elif defined(SH_4)
                #define TARGET_SH SH_Y2M2
            #elif defined(SH_5)
                #define TARGET_SH SH_Y2M1
            #elif defined(SH_6)
                #define TARGET_SH SH_Y2_0
            #elif defined(SH_7)
                #define TARGET_SH SH_Y2P1
            #elif defined(SH_8)
                #define TARGET_SH SH_Y2P2
            #else
                #define TARGET_SH SH_Y0_0
            #endif

            struct I2V
            {
                float4 lPos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F) 0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                output.uv = input.uv;
                return output;
            }

            float3 Test1(float3 normal)
            {
                float x = normal.x;
                float y = normal.y;
                float z = normal.z;
                float sh = TARGET_SH;
                return _CubeMap.SampleLevel(_InlineSampler_Point_Clamp, normal, 0.0).rgb * sh;
            }

            float3 Test0(float3 normal)
            {
                // 立方体を構成する6つの面を積分する

                float3 output = 0.0;
                output += Test1(normal); // normalize(float3(x, y,  1.0))

                normal.z = -normal.z;
                output += Test1(normal); // normalize(float3(x, y, -1.0))

                normal = normal.yzx;
                output += Test1(normal); // normalize(float3(y, -1.0, x))

                normal.y = -normal.y;
                output += Test1(normal); // normalize(float3(y,  1.0, x))

                normal = normal.yzx;
                output += Test1(normal); // normalize(float3( 1.0, x, y))

                normal.x = -normal.x;
                output += Test1(normal); // normalize(float3(-1.0, x, y))

                return output;
            }

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                float2 uv = input.uv;

                // 正規化と立体角の計算
                /*
                float3 vec = float3(uv,  1.0);
                float sqrL = dot(vec, vec);
                float3 normal = normalize(vec)
                float weight = dot(normal, float3(0.0, 0.0, 1.0)) / sqrL
                */

                float3 vec = float3(uv,  1.0);
                float len = length(vec);
                float3 normal = vec / len;
                float weight = 1.0 / (len * len * len);

                // 立方体を構成する6つの面をさらに4つに分割して計算する
                float3 output = 0.0;
                output += Test0(float3( normal.x,  normal.y, normal.z)); // 第一象限
                output += Test0(float3(-normal.x,  normal.y, normal.z)); // 第二象限
                output += Test0(float3(-normal.x, -normal.y, normal.z)); // 第三象限
                output += Test0(float3( normal.x, -normal.y, normal.z)); // 第四象限

                return float4(output, 6.0 * 4.0) * weight;
            }

            ENDCG
        }
    }
}
