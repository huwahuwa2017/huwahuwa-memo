Shader "HuwaExample/Monochrome_Beginner"
{
    SubShader
    {
        Tags
        {
            // ほかの3Dモデルの描画が終わってから実行したいので、Queueを大きめに設定する
            "Queue" = "Overlay+1"

            // 動的バッチングを無効化
            "DisableBatching" = "True"

            // プロジェクターの影響を無効化
            "IgnoreProjector" = "True"
        }

        GrabPass
        {
            // 背景の色を取得する かぶりにくい名前にしたほうが良い
            "_MonochromeShader_Background_18736944"
        }

        Pass
        {
            // 別のオブジェクトの裏に隠れたとしても強制的に表示する
            ZTest Always

            // Depthの書き込みをしないようにする
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
                float4 cgsPos : TEXCOORD0;
            };

            sampler2D _MonochromeShader_Background_18736944;

            V2F VertexShaderStage(I2V input)
            {
                // Unityに元からあるQuadMeshのuv
                // (0.0, 0.0) (1.0, 0.0) (0.0, 1.0) (1.0, 1.0)
                // を
                // (-1.0, -1.0) (1.0, -1.0) (-1.0, 1.0) (1.0, 1.0)
                // に変化させて、cPosのxyとして扱う
                float2 cPosXY = input.uv * 2.0 - 1.0;

                // ZWrite Off かつ ZTest Always を使用するので、Depthの値は固定しても問題ない
                // というわけでzの値は0.5を入れておく
                float cPosZ = 0.5;

                // FragmentShaderにcPos渡すとき、途中 cPosのX,Y,Z成分をWで割り算する処理が発生する
                // XとY成分が変化すると困るのでw成分は1.0にする
                float cPosW = 1.0;

                float4 cPos = float4(cPosXY, cPosZ, cPosW);

                // DirectXの上下反転する仕様を計算に入れる
                cPos.y *= _ProjectionParams.x;

                V2F output = (V2F)0;
                output.cPos = cPos;
                output.cgsPos = ComputeGrabScreenPos(cPos);
                return output;
            }

            float4 FragmentShaderStage(V2F input) : SV_Target
            {
                float2 uv = input.cgsPos.xy / input.cgsPos.w;

                float3 color = tex2D(_MonochromeShader_Background_18736944, uv);
                float monochrome = (color.r + color.g + color.b) / 3.0;
                return float4(monochrome.xxx, 1.0);
            }

            ENDCG
        }
    }
}
