// Ver3 2024/09/03 20:34

#if !defined(HUWA_INVERSE_MATRIX_INCLUDED)
#define HUWA_INVERSE_MATRIX_INCLUDED

float2x2 Inverse(float2x2 m)
{
    return float2x2(m._22, -m._12, -m._21, m._11) * rcp(determinant(m));
}

float3x3 Inverse(float3x3 m)
{
    float3x3 am;
    am._11_21_31 = mad(m._22_31_21, m._33_23_32, -m._32_21_31 * m._23_33_22);
    am._12_22_32 = mad(m._32_11_31, m._13_33_12, -m._12_31_11 * m._33_13_32);
    am._13_23_33 = mad(m._12_21_11, m._23_13_22, -m._22_11_21 * m._13_23_12);
    
    float invDet = rcp(dot(m[0], am._11_21_31));
    am._11_21_31 *= invDet;
    am._12_22_32 *= invDet;
    am._13_23_33 *= invDet;
    
    return am;
}

float4x4 Inverse(float4x4 m)
{
    float4 det1 = mad(m._33_31_13_11, m._44_42_24_22, -m._34_32_14_12 * m._43_41_23_21);
    float4 det2 = mad(m._23_21_13_11, m._44_42_34_32, -m._24_22_14_12 * m._43_41_33_31);
    float4 det3 = mad(m._23_21_13_11, m._34_32_44_42, -m._24_22_14_12 * m._33_31_43_41);
    
    float4x4 im;
    im._11_21_31_41 = mad(m._22_21_24_23, det1.xxyy, mad(-m._32_31_34_33, det2.xxyy, m._42_41_44_43 * det3.xxyy));
    im._12_22_32_42 = mad(m._12_11_14_13, det1.xxyy, mad(-m._32_31_34_33, det3.zzww, m._42_41_44_43 * det2.zzww));
    im._13_23_33_43 = mad(m._12_11_14_13, det2.xxyy, mad(-m._22_21_24_23, det3.zzww, m._42_41_44_43 * det1.zzww));
    im._14_24_34_44 = mad(m._12_11_14_13, det3.xxyy, mad(-m._22_21_24_23, det2.zzww, m._32_31_34_33 * det1.zzww));
    
    im._21_41 = -im._21_41;
    im._12_32 = -im._12_32;
    im._23_43 = -im._23_43;
    im._14_34 = -im._14_34;
    
    float invDet = rcp(dot(m[0], im._11_21_31_41));
    im._11_21_31_41 *= invDet;
    im._12_22_32_42 *= invDet;
    im._13_23_33_43 *= invDet;
    im._14_24_34_44 *= invDet;
    
    return im;
}

#endif // HUWA_INVERSE_MATRIX_INCLUDED
