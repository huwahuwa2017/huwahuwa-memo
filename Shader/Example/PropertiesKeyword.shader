Shader "HuwaExample/PropertiesKeyword"
{
    Properties
    {
        // 変数名は何でもよい
        [Toggle(_KEYWORD_TOGGLE_A)]
        _TempA("Toggle", Int) = 0

        // 変数名 + _ + KeywordEnumの値
        // のキーワードが有効になる
        [KeywordEnum(A, B, C)]
        _KEYWORD_ENUM("KeywordEnum", Int) = 0
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #pragma multi_compile_local _ _KEYWORD_TOGGLE_A
            #pragma multi_compile_local _ _KEYWORD_ENUM_A _KEYWORD_ENUM_B _KEYWORD_ENUM_C

            #include "UnityCG.cginc"

            struct I2V
            {
                float4 lPos : POSITION;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
            };

            V2F VertexShaderStage(I2V input)
            {
                V2F output = (V2F)0;
                output.cPos = UnityObjectToClipPos(input.lPos);
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                half4 color = half4(0.5, 0.5, 0.0, 1.0);

                #if defined(_KEYWORD_TOGGLE_A)
                    color.r = 1.0;
                #else
                    color.r = 0.0;
                #endif

                #if defined(_KEYWORD_ENUM_A)
                    color.g = 0.0;
                #elif defined(_KEYWORD_ENUM_B)
                    color.g = 0.5;
                #elif defined(_KEYWORD_ENUM_C)
                    color.g = 1.0;
                #endif

                return color;
            }

            ENDCG
        }
    }
}
