// v1 2025-04-08 01:59
// ShadeSH9 の再現

Shader "Custom/RecreateShadeSH9"
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
            
            struct I2V
            {
                float4 lPos : POSITION;
                float3 lNormal : NORMAL;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float3 wNormal : TEXCOORD0;
            };

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F) 0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                output.wNormal = UnityObjectToWorldNormal(input.lNormal);
                return output;
            }

            // Light probe のパラメータ (LightProbes.GetInterpolatedProbe) をコピペしただけ
            static float3 _CPU_SH[] =
            {
                float3(0.1482331, 0.2778801, 0.3537944),
                float3(0.02267341, -0.03638067, 0.06334348),
                float3(-0.016587, -0.03298255, -0.0500824),
                float3(0.002779926, 0.005922909, -0.04089936),
                float3(-0.0001510563, -0.001238347, 0.03539551),
                float3(-0.009592066, -0.01019644, -0.02117261),
                float3(0.006561049, 0.005969439, 0.01044528),
                float3(0.001758559, 0.004480661, 0.01089416),
                float3(0.01331608, 0.004302206, 0.01227538)
            };

            static float3 _GPU_SH[] =
            {
                _CPU_SH[0] - _CPU_SH[6],
                _CPU_SH[1],
                _CPU_SH[2],
                _CPU_SH[3],
                _CPU_SH[4],
                _CPU_SH[5],
                _CPU_SH[6] * 3.0,
                _CPU_SH[7],
                _CPU_SH[8]
            };

            half3 FragmentShaderStage(V2F input) : SV_Target
            {
                float3 n = normalize(input.wNormal);
                float x = n.x;
                float y = n.y;
                float z = n.z;
                
                float3 color = 0.0;

                /*
                color += _CPU_SH[0];
                color += _CPU_SH[1] * y;
                color += _CPU_SH[2] * z;
                color += _CPU_SH[3] * x;
                color += _CPU_SH[4] * x * y;
                color += _CPU_SH[5] * y * z;
                color += _CPU_SH[6] * (3.0 * z * z - 1.0);
                color += _CPU_SH[7] * z * x;
                color += _CPU_SH[8] * (x * x - y * y);
                */
                
                color += _GPU_SH[0];
                color += _GPU_SH[1] * y;
                color += _GPU_SH[2] * z;
                color += _GPU_SH[3] * x;
                color += _GPU_SH[4] * x * y;
                color += _GPU_SH[5] * y * z;
                color += _GPU_SH[6] * z * z;
                color += _GPU_SH[7] * z * x;
                color += _GPU_SH[8] * (x * x - y * y);


                //return color;

                float3 originalColor = ShadeSH9(float4(n, 1.0));
                return abs(color - originalColor);
            }

            ENDCG
        }
    }
}
