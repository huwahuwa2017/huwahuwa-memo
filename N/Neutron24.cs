using UnityEngine;

public class Neutron24 : MonoBehaviour
{
    [SerializeField]
    private bool _next = false;

    [SerializeField]
    float _debugReactorPeriod = 0f;

    [SerializeField]
    float _debugThermalPower = 0f;

    [SerializeField]
    Vector3 _debugA = Vector3.zero;

    [SerializeField]
    Vector3 _debugB = Vector3.zero;

    [SerializeField]
    Vector3 _debugC = Vector3.zero;




    // cm
    float _cellSize = 78f;
    float _cellSizePow2 = -1f;
    float _cellSizePow3 = -1f;

    // 熱中性子の速度 (cm/s)
    float _thermalNeutronVelocity = 220000f;

    // 中性子拡散係数 (cm)
    // https://www.nuclear-power.com/nuclear-power/reactor-physics/neutron-diffusion-theory/diffusion-coefficient
    // H2O (軽水) の中性子拡散係数を使用
    float _diffusionCoefficient = 0.142f;

    // U235 核分裂エネルギー (J)
    // 200 MeV を J に変換した値
    float _fissionEnergy = 3.20436e-11f;

    // U235 の核分裂の平均中性子生成数
    // https://en.wikipedia.org/wiki/Uranium-235
    float _neutronYield = 2.43f;

    // 巨視的熱中性子核分裂断面積
    // 二酸化ウラン・燃料ペレットの密度・U235の濃度から計算
    float _macroscopicThermalNeutronFissionCrossSection = 0.524704607f * 0.1f;

    // 巨視的熱中性子吸収断面積
    // Start()で計算する
    [SerializeField]
    float _macroscopicThermalNeutronAbsorptionCrossSection = 1f;


    // セル内の 1cm^3 の U238 の平均質量 (g/cm^3)
    float _averageMassU238 = 8.81978176f * 0.1f;

    // 1g の U238 から1秒間に何個の中性子が生成されるか
    // https://pages.mtu.edu/~jstallen/courses/MEEM4200/lectures/nuclear/DOE-HDBK-1019v1.pdf
    // 106 ページから引用
    float _spontaneousFissionNeutronSourceU238 = 0.016f;

    // Start()で計算
    float _spontaneousFissionNeutronSource = -1f;


    // 遅発中性子割合 (β)
    // https://www.engr.psu.edu/conedmat/courses/nuce497a/lamarsh_baratta-introduction_to_nuclear_engineering_textbook_3rd_edition.pdf
    // 106 ページから引用
    float _delayedFraction = 0.006502f;

    // 崩壊定数 (λ)
    // 6群遅発中性子モデルの半減期や濃度から計算
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

    float _fixedDeltaTime = -1f;

    private void Start()
    {
        _fixedDeltaTime = Time.fixedDeltaTime;
        Debug.Log("Time.fixedDeltaTime : " + _fixedDeltaTime.ToString());


        _macroscopicThermalNeutronAbsorptionCrossSection = _neutronYield * _macroscopicThermalNeutronFissionCrossSection;


        _cellSizePow2 = _cellSize * _cellSize;
        _cellSizePow3 = _cellSizePow2 * _cellSize;


        // セル内の 1cm^3 あたりの U238 の自発核分裂による中性子生成数
        _spontaneousFissionNeutronSource = _averageMassU238 * _spontaneousFissionNeutronSourceU238;




    }

    private void Step(float dt)
    {
        // 1群エネルギー 1群遅発中性子 時間依存中性子拡散方程式

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
                float nf_N = (temp10 + _decayConstant * pc + _spontaneousFissionNeutronSource) * _thermalNeutronVelocity;
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


        float temp30 = _cellSizePow3 * _macroscopicThermalNeutronFissionCrossSection * _fissionEnergy;
        _debugThermalPower = 0f;

        for (int xyIndex = 0; xyIndex < _xyIndexCount; ++xyIndex)
        {
            int x = xIndexs[xyIndex];
            int y = yIndexs[xyIndex];

            for (int z = _zStartIndex; z < _zEndIndex; ++z)
            {
                float newNF = _neutronFluxCache[x, y, z];
                _debugThermalPower = _debugThermalPower + newNF * temp30;

                _neutronFlux[x, y, z] = newNF;
                _precursor[x, y, z] = _precursorCache[x, y, z];
            }
        }

        // MW に変換
        _debugThermalPower = _debugThermalPower / 1000000f;
    }

    private void FixedUpdate()
    {
        /*
        if (!_next)
            return;
        */

        _next = false;

        Step(_fixedDeltaTime);

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
