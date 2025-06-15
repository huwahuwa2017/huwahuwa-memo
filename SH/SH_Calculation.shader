// v2 2025-06-16 00:55

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

            float3 Test1(float3 direction)
            {
                float x = direction.x;
                float y = direction.y;
                float z = direction.z;
                float sh = TARGET_SH;
                return _CubeMap.SampleLevel(_InlineSampler_Point_Clamp, direction, 0.0).rgb * sh;
            }

            float3 Test0(float3 direction)
            {
                // 立方体を構成する6つの面を積分する

                float3 output = 0.0;
                output += Test1(direction); // normalize(float3(x, y,  1.0))

                direction.z = -direction.z;
                output += Test1(direction); // normalize(float3(x, y, -1.0))

                direction = direction.yzx;
                output += Test1(direction); // normalize(float3(y, -1.0, x))

                direction.y = -direction.y;
                output += Test1(direction); // normalize(float3(y,  1.0, x))

                direction = direction.yzx;
                output += Test1(direction); // normalize(float3( 1.0, x, y))

                direction.x = -direction.x;
                output += Test1(direction); // normalize(float3(-1.0, x, y))

                return output;
            }

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                float2 uv = input.uv;

                // キューブマップを2x2x2の立方体とする
                // このときキューブマップを構成するピクセルを、半径が1の球体に投影した時のおおまかな面積は
                // (キューブマップの一辺の解像度 / 2)^2 * dot(ピクセルの重心の方向, 法線) / ピクセルの重心の距離^2
                // となる

                // このシェーダーでは(キューブマップの一辺の解像度 / 2)^2部分を省いている
                // これは次の工程でmipmapを利用して、
                // ピクセルごとの計算結果の合計と(キューブマップの一辺の解像度 / 2)^2を同時に計算するからである

                /*
                float3 vec = float3(uv,  1.0);
                float sqrL = dot(vec, vec);
                float3 direction = normalize(vec);
                float area = dot(direction, float3(0.0, 0.0, 1.0)) / sqrL;
                */
                
                float3 vec = float3(uv,  1.0);
                float len = length(vec);
                float3 direction = vec / len;
                float area = 1.0 / (len * len * len);
                
                // 立方体を構成する6つの面をさらに4つに分割して計算する
                float3 output = 0.0;
                output += Test0(float3( direction.x,  direction.y, direction.z)); // 第一象限
                output += Test0(float3(-direction.x,  direction.y, direction.z)); // 第二象限
                output += Test0(float3(-direction.x, -direction.y, direction.z)); // 第三象限
                output += Test0(float3( direction.x, -direction.y, direction.z)); // 第四象限

                return float4(output, 6.0 * 4.0) * area;
            }

            ENDCG
        }
    }
}
