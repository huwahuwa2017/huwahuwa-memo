using UnityEngine;

public class Neutron23 : MonoBehaviour
{
    [SerializeField]
    private bool _next = false;

    [SerializeField]
    float _debugReactorPeriod = 0;

    [SerializeField]
    Vector3 _debugA = Vector3.zero;

    [SerializeField]
    Vector3 _debugB = Vector3.zero;

    [SerializeField]
    Vector3 _debugC = Vector3.zero;




    // cm
    float _cellSize = 78f;
    float _cellSizePow2 = -1f;

    // 熱中性子の速度 (cm/s)
    float _thermalNeutronVelocity = 220000f;

    // https://www.nuclear-power.com/nuclear-power/reactor-physics/neutron-diffusion-theory/diffusion-coefficient
    // H2O : D = 0.142
    // 中性子拡散係数 (cm)
    float _diffusionCoefficient = 0.142f;

    // https://en.wikipedia.org/wiki/Uranium-235
    // U235 の核分裂の中性子生成数
    float _neutronYield = 2.43f;

    // 巨視的熱中性子吸収断面積 (Start()で計算する)
    [SerializeField]
    float _macroscopicThermalNeutronAbsorptionCrossSection = 1f;

    // 巨視的熱中性子核分裂断面積
    float _macroscopicThermalNeutronFissionCrossSection = 0.5245f * 0.1f;




    // 遅発中性子割合 (β)
    float _delayedFraction = 0.006502f;

    // 崩壊定数 (λ)
    float _decayConstant = 0.0768f;




    // 中性子束
    float[,,] _neutronFlux = new float[8, 8, 8];
    float[,,] _neutronFluxCache = new float[8, 8, 8];

    // 遅発中性子先行核の濃度 (C)
    float[,,] _precursor = new float[8, 8, 8];
    float[,,] _precursorCache = new float[8, 8, 8];


    int _xyIndexCount = 24;

    int[] xIndexs = new[]
    {
              3, 4,
           2, 3, 4, 5,
        1, 2, 3, 4, 5, 6,
        1, 2, 3, 4, 5, 6,
           2, 3, 4, 5,
              3, 4,
    };

    int[] yIndexs = new[]
    {
              1, 1,
           2, 2, 2, 2,
        3, 3, 3, 3, 3, 3,
        4, 4, 4, 4, 4, 4,
           5, 5, 5, 5,
              6, 6,
    };

    int _zStartIndex = 1;
    int _zEndIndex = 7;

    private void Start()
    {
        float fdt = Time.fixedDeltaTime;
        Debug.Log("Time.fixedDeltaTime : " + fdt.ToString());


        _macroscopicThermalNeutronAbsorptionCrossSection = _neutronYield * _macroscopicThermalNeutronFissionCrossSection;


        _cellSizePow2 = _cellSize * _cellSize;


        for (int xyIndex = 0; xyIndex < _xyIndexCount; ++xyIndex)
        {
            int x = xIndexs[xyIndex];
            int y = yIndexs[xyIndex];

            for (int z = _zStartIndex; z < _zEndIndex; ++z)
            {
                // 中性子束の初期化
                float nf = 10f;
                _neutronFlux[x, y, z] = nf;

                // 遅発中性子先行核の濃度の初期化
                // βνΣf​ϕ
                float temp1 = _delayedFraction * _neutronYield * _macroscopicThermalNeutronFissionCrossSection * nf;

                // (βνΣf​ϕ)/λ
                _precursor[x, y, z] = temp1 / _decayConstant;
            }
        }
    }

    private void Step(float dt)
    {
        float promptNeutronGrowthRate = (1f - _delayedFraction) * _neutronYield * _macroscopicThermalNeutronFissionCrossSection;
        promptNeutronGrowthRate = (promptNeutronGrowthRate - _macroscopicThermalNeutronAbsorptionCrossSection) * _thermalNeutronVelocity;

        for (int xyIndex = 0; xyIndex < _xyIndexCount; ++xyIndex)
        {
            int x = xIndexs[xyIndex];
            int y = yIndexs[xyIndex];

            // 指数型オイラー法で _neutronFluxCache と _precursorCache を計算する

            for (int z = _zStartIndex; z < _zEndIndex; ++z)
            {
                float nf = _neutronFlux[x, y, z];
                float pc = _precursor[x, y, z];

                // 拡散から nf の掛け算を含む項を省いた式
                float temp10 = _neutronFlux[x - 1, y, z] + _neutronFlux[x + 1, y, z] + _neutronFlux[x, y - 1, z] + _neutronFlux[x, y + 1, z] + _neutronFlux[x, y, z - 1] + _neutronFlux[x, y, z + 1];
                temp10 = temp10 * _diffusionCoefficient / _cellSizePow2;

                // あとで nf_L, nf_exp, nf_integral を for の外に出す
                float nf_L = promptNeutronGrowthRate - 6f * _thermalNeutronVelocity * _diffusionCoefficient / _cellSizePow2;
                float nf_N = (temp10 + _decayConstant * pc) * _thermalNeutronVelocity;
                float nf_exp = Mathf.Exp(nf_L * dt);
                float nf_integral;

                if (Mathf.Abs(nf_L) < 0.000001f)
                    nf_integral = dt;
                else
                    nf_integral = (nf_exp - 1f) / nf_L;

                _neutronFluxCache[x, y, z] = nf_exp * nf + nf_integral * nf_N;

                // あとで pc_L, pc_exp, pc_integral を for の外に出す
                float pc_L = -_decayConstant;
                float pc_N = _delayedFraction * _neutronYield * _macroscopicThermalNeutronFissionCrossSection * nf;
                float pc_exp = Mathf.Exp(pc_L * dt);
                float pc_integral;

                if (Mathf.Abs(pc_L) < 0.000001f)
                    pc_integral = dt;
                else
                    pc_integral = (pc_exp - 1f) / pc_L;

                _precursorCache[x, y, z] = pc_exp * pc + pc_integral * pc_N;
            }
        }


        _debugReactorPeriod = dt / Mathf.Log(_neutronFluxCache[3, 3, 1] / _neutronFlux[3, 3, 1]);


        for (int xyIndex = 0; xyIndex < _xyIndexCount; ++xyIndex)
        {
            int x = xIndexs[xyIndex];
            int y = yIndexs[xyIndex];

            for (int z = _zStartIndex; z < _zEndIndex; ++z)
            {
                _neutronFlux[x, y, z] = _neutronFluxCache[x, y, z];
                _precursor[x, y, z] = _precursorCache[x, y, z];
            }
        }
    }

    private void FixedUpdate()
    {
        /*
        if (!_next)
            return;
        */

        _next = false;

        Step(Time.fixedDeltaTime);

        _debugA.x = _neutronFlux[1, 1, 1];
        _debugA.y = _neutronFlux[2, 1, 1];
        _debugA.z = _neutronFlux[3, 1, 1];

        _debugB.x = _neutronFlux[1, 2, 1];
        _debugB.y = _neutronFlux[2, 2, 1];
        _debugB.z = _neutronFlux[3, 2, 1];

        _debugC.x = _neutronFlux[1, 3, 1];
        _debugC.y = _neutronFlux[2, 3, 1];
        _debugC.z = _neutronFlux[3, 3, 1];
    }
}
