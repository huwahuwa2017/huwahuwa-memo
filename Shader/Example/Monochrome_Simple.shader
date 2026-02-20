Shader "HuwaExample/Monochrome_Simple"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+1"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }

        GrabPass
        {
            "_MonochromeShader_Background_67913547"
        }

        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "UnityCG.cginc"

            struct I2V
            {
                float2 uv : TEXCOORD0;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
            };

            // sampler2D ではなく Texture2D で宣言
            Texture2D _MonochromeShader_Background_67913547;

            V2F VertexShaderStage(I2V input)
            {
                float4 cPos = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
                cPos.y *= _ProjectionParams.x;

                V2F output = (V2F)0;
                output.cPos = cPos;
                return output;
            }

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                // GrabPass から配列のように色を取得する
                float3 color = _MonochromeShader_Background_67913547[uint2(input.cPos.xy)];
                float monochrome = (color.r + color.g + color.b) / 3.0;
                return float4(monochrome.xxx, 1.0);
            }

            ENDCG
        }
    }
}
