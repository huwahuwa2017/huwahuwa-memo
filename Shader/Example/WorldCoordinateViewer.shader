// 注意
// このシェーダーは ShadowCaster を利用しています
// ShadowCaster が動作しない環境では、このシェーダーは動作しません

Shader "HuwaExample/WorldCoordinateViewer"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+1"
        }

        Pass
        {
            Cull Off
            ZTest Always
            ZWrite Off

            CGPROGRAM

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
                float3 wViewDir : TEXCOORD0;
            };

            Texture2D _CameraDepthTexture;

            V2F VertexShaderStage(I2V input)
            {
                float3 wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;
                float3 wViewDir = wPos - _WorldSpaceCameraPos;

                V2F output = (V2F)0;
                output.cPos = UnityWorldToClipPos(wPos);
                output.wViewDir = wViewDir;
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                float depth = _CameraDepthTexture[uint2(input.cPos.xy)].r;
                clip(-(depth == 0.0)); // SkyBoxを無視する (うまくいかない時もある)

                float eyeDepth = LinearEyeDepth(depth);
                float3 wPos = (input.wViewDir / input.cPos.w) * eyeDepth + _WorldSpaceCameraPos;

                float3 temp0 = 1.0 - abs(wPos - round(wPos)) * 2.0;
                temp0 = pow(temp0, 16);

                return half4(temp0, 1.0);
            }

            ENDCG
        }
    }
}
