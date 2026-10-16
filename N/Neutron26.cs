using UnityEngine;

public class Neutron26 : MonoBehaviour
{
    [SerializeField]
    private bool _next = false;

    [SerializeField]
    float _debugReactorPeriod = 0f;

    [SerializeField]
    float _debugThermalPower = 0f;

    [SerializeField]
    float _debugControlRod = 0f;

    [Space(12)]

    [SerializeField]
    Vector3 _debugA = Vector3.zero;

    [SerializeField]
    Vector3 _debugB = Vector3.zero;

    [SerializeField]
    Vector3 _debugC = Vector3.zero;

    [Space(12)]

    [SerializeField]
    Vector3 _debugD = Vector3.zero;

    [SerializeField]
    Vector3 _debugE = Vector3.zero;

    [SerializeField]
    Vector3 _debugF = Vector3.zero;




    // セルの大きさ (cm)
    float _cellSize = 78f;
    float _cellSizePow2 = -1f;
    float _cellSizePow3 = -1f;

    // 熱中性子の速度 (cm/s)
    float _thermalNeutronVelocity = 220000f;

    // 中性子拡散係数 (cm)
    // https://www.nuclear-power.com/nuclear-power/reactor-physics/neutron-diffusion-theory/diffusion-coefficient
    // H2O (軽水) の中性子拡散係数を使用
    float _diffusionCoefficient = 0.142f;


    // U235 の核分裂の平均中性子生成数
    // https://en.wikipedia.org/wiki/Uranium-235
    float _neutronYield = 2.43f;

    // 巨視的熱中性子核分裂断面積 (cm^-1)
    // 燃料ペレットの密度やU235の濃度から計算  セル内体積の30%を核燃料とする
    float _macroscopicThermalNeutronFissionCrossSection = 0.530573339f * 0.3f;

    // 巨視的熱中性子吸収断面積 (cm^-1)
    // 燃料ペレットの密度やU235とU238の濃度から計算  セル内体積の30%を核燃料とする
    float _macroscopicThermalNeutronAbsorptionCrossSection = 0.699036798f * 0.3f;




    // 1cm^3 の燃料ペレット内の U238 の重量 8.81912790 g
    // セル内の 1cm^3 の U238 の平均質量 (g/cm^3)  セル内体積の30%を核燃料とする
    float _averageMassU238 = 8.81912790f * 0.3f;

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
    // 6群遅発中性子モデルの濃度と半減期の平均から計算
    float _decayConstant = 0.0768f;




    // U235 核分裂エネルギー (J)
    // https://en.wikipedia.org/wiki/Uranium-235
    // 169.1 + 4.8 + 7.0 + 8.8 = 189.7
    // 189.7 MeV を J に変換した値
    float _fissionEnergy = 3.039329e-11f;

    // 先行核 核分裂エネルギー (J)
    // https://en.wikipedia.org/wiki/Uranium-235
    // 6.5 + 6.3 = 12.8
    // 12.8 Mev を J に変換した値
    float _precursorFissionEnergy = 2.05079e-12f;




    // 比熱
    // https://tec-note.com/1923
    // H2O : 4.180 (30 ℃)
    // UO2 : 0.237 (300 K)

    // 比熱 * 密度 * セル内体積の70%
    float _waterVolumetricHeatCapacity = 4.180f * (1.0f * 0.7f);

    // 比熱 * 密度 * 燃料ペレット内のU2Oの密度 * セル内体積の30%
    float _fuelVolumetricHeatCapacity = 0.237f * (10.97f * 0.95f * 0.3f);




    // セルごとの水位 (m)
    float[] _cacheWaterLevel = new float[8];

    // セルごとの 1cm^3 の比熱*質量  セル内体積の30%を核燃料とする
    //float[] _cacheVolumetricHeatCapacity = new float[8];

    // セルごとの巨視的熱中性子核分裂断面積 (cm^-1)
    float[] _cacheMTNFCS = new float[8];

    // 制御棒
    float[,] _controlRod = new float[8, 8];

    // 中性子束 (cm^-2/s)
    float[,,] _neutronFlux = new float[8, 8, 8];
    float[,,] _neutronFluxCache = new float[8, 8, 8];

    // 遅発中性子先行核の濃度 (C)
    float[,,] _precursor = new float[8, 8, 8];
    float[,,] _precursorCache = new float[8, 8, 8];

    // ジュール
    float[,,] _fuelThermalStorage = new float[8, 8, 8];

    // 崩壊熱 decayHeat
    float[,,] _decayHeat = new float[8, 8, 8];




    // 崩壊熱を再現するための数値 (崩壊定数とは別物なので注意)
    // log_e(2) / 半減期(120秒)
    float _decayHeatConstant = 0.005776226504666f;




    [Space(12)]

    // 原子炉内の水位 燃料棒の天辺を 0m とする
    [SerializeField]
    float _reactorWaterLevel = 1f;



    [SerializeField, Range(-1f, 1f)]
    float _controlRodBar = 0f;

    [SerializeField]
    float _controlRodSpeed = 0.001f;

    // 制御棒が与える巨視的熱中性子吸収断面積 (cm^-1)
    // MTNACS : MacroscopicThermalNeutronAbsorptionCrossSection
    float _controlRodMTNACS = 0.25f;


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


        _cellSizePow2 = _cellSize * _cellSize;
        _cellSizePow3 = _cellSizePow2 * _cellSize;


        float temp0 = _neutronYield * _macroscopicThermalNeutronFissionCrossSection;
        Debug.Log("中性子増加 : " + temp0.ToString());

        float temp1 = _macroscopicThermalNeutronAbsorptionCrossSection;
        Debug.Log("中性子吸収 : " + temp1.ToString());



        // セル内の 1cm^3 あたりの U238 の自発核分裂による中性子生成数
        _spontaneousFissionNeutronSource = _averageMassU238 * _spontaneousFissionNeutronSourceU238;


        for (int xyIndex = 0; xyIndex < _xyIndexCount; ++xyIndex)
        {
            int x = xIndexs[xyIndex];
            int y = yIndexs[xyIndex];

            for (int z = _zStartIndex; z < _zEndIndex; ++z)
            {
                _controlRod[x, y] = 1f;

                _fuelThermalStorage[x, y, z] = 20f * _fuelVolumetricHeatCapacity;
            }
        }
    }

    // 圧力 (kPa) から 水の沸点 (セルシウス温度) を計算する式
    // https://en.wikipedia.org/wiki/Antoine_equation
    private float AntoineEquation(float pressure)
    {
        float pressure_mmhg = pressure * 7.500615f;
        return 1810.94f / (8.14019f - Mathf.Log10(pressure_mmhg)) - 244.485f;
    }




    private void Step(float dt)
    {
        _controlRodBar = Mathf.Round(_controlRodBar);
        float speed = _controlRodBar * _controlRodSpeed;




        for (int z = _zStartIndex; z < _zEndIndex; ++z)
        {
            // セルごとの水位
            float wl = Mathf.Clamp01((float)z + 100f * _reactorWaterLevel / _cellSize);
            _cacheWaterLevel[z] = wl;


            // セルごとの巨視的熱中性子核分裂断面積 (cm^-1)
            _cacheMTNFCS[z] = _macroscopicThermalNeutronFissionCrossSection * wl;
        }




        // 1群エネルギー 1群遅発中性子 時間依存中性子拡散方程式

        float targetTemperature = AntoineEquation(100f);

        _debugThermalPower = 0f;

        for (int xyIndex = 0; xyIndex < _xyIndexCount; ++xyIndex)
        {
            int x = xIndexs[xyIndex];
            int y = yIndexs[xyIndex];

            _controlRod[x, y] = Mathf.Clamp01(_controlRod[x, y] + speed);

            float MTNACS = _macroscopicThermalNeutronAbsorptionCrossSection + _controlRodMTNACS * _controlRod[x, y];

            for (int z = _zStartIndex; z < _zEndIndex; ++z)
            {
                float nf = _neutronFlux[x, y, z];
                float pc = _precursor[x, y, z];

                float MTNFCS = _cacheMTNFCS[z];

                // 指数型オイラー法で _neutronFluxCache を計算する
                // (∇⋅(D∇ϕ) + (1-β)νΣf​ϕ - Σa​ϕ + λC)V
                {
                    float promptNeutronGrowthRate = (1f - _delayedFraction) * _neutronYield * MTNFCS - MTNACS;
                    promptNeutronGrowthRate = promptNeutronGrowthRate * _thermalNeutronVelocity;

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
                }

                // 指数型オイラー法で _precursorCache を計算する
                // βνΣf​ϕ - λC
                {
                    // あとで pc_L, pc_exp, pc_integral を for の外に出す
                    float pc_L = -_decayConstant;
                    float pc_N = _delayedFraction * _neutronYield * MTNFCS * nf;
                    float pc_exp = Mathf.Exp(pc_L * dt);
                    float pc_integral;

                    if (Mathf.Abs(pc_L) < 0.000001f)
                        pc_integral = dt;
                    else
                        pc_integral = (pc_exp - 1f) / pc_L;

                    _precursorCache[x, y, z] = pc_exp * pc + pc_integral * pc_N;
                }

                // 発熱量を計算する
                {
                    float decayHeat = _decayHeat[x, y, z];

                    float feA = MTNFCS * nf * _fissionEnergy;
                    float feB = decayHeat * _decayHeatConstant;
                    float thermalPowerW = feA + feB;

                    _decayHeat[x, y, z] = decayHeat + (MTNFCS * nf * _precursorFissionEnergy - decayHeat * _decayHeatConstant) * dt;

                    if (_next && x == 3 && y == 3 && z == 3)
                    {
                        _next = false;
                        Debug.Log(feA.ToString() + " : " + feB.ToString());
                    }

                    _debugThermalPower = _debugThermalPower + thermalPowerW;

                    // 核分裂による発熱量 (J/cm^3)
                    float thermalPowerJ = thermalPowerW * dt;

                    float th = _fuelThermalStorage[x, y, z] + thermalPowerJ;

                    // セル内に水があれば True
                    if (_cacheWaterLevel[z] > 0f)
                    {
                        float nextTemperature = th / _fuelVolumetricHeatCapacity;

                        float diffThermalPowerJ = Mathf.Max(nextTemperature - targetTemperature, 0f) * _fuelVolumetricHeatCapacity;

                        th = th - diffThermalPowerJ;
                    }

                    _fuelThermalStorage[x, y, z] = th;
                }
            }
        }


        _debugControlRod = _controlRod[3, 3];

        _debugReactorPeriod = dt / Mathf.Log(_neutronFluxCache[3, 3, 6] / _neutronFlux[3, 3, 6]);


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

        // MW に変換
        _debugThermalPower = _debugThermalPower * _cellSizePow3 / 1000000f;
    }

    private void FixedUpdate()
    {
        /*
        if (!_next)
            return;
        
        _next = false;
        */

        Step(_fixedDeltaTime);

        _debugA.x = _neutronFlux[1, 1, 3];
        _debugA.y = _neutronFlux[2, 1, 3];
        _debugA.z = _neutronFlux[3, 1, 3];

        _debugB.x = _neutronFlux[1, 2, 3];
        _debugB.y = _neutronFlux[2, 2, 3];
        _debugB.z = _neutronFlux[3, 2, 3];

        _debugC.x = _neutronFlux[1, 3, 3];
        _debugC.y = _neutronFlux[2, 3, 3];
        _debugC.z = _neutronFlux[3, 3, 3];

        // 燃料部分の温度だけ
        _debugD.x = _fuelThermalStorage[1, 1, 3] / _fuelVolumetricHeatCapacity;
        _debugD.y = _fuelThermalStorage[2, 1, 3] / _fuelVolumetricHeatCapacity;
        _debugD.z = _fuelThermalStorage[3, 1, 3] / _fuelVolumetricHeatCapacity;

        _debugE.x = _fuelThermalStorage[1, 2, 3] / _fuelVolumetricHeatCapacity;
        _debugE.y = _fuelThermalStorage[2, 2, 3] / _fuelVolumetricHeatCapacity;
        _debugE.z = _fuelThermalStorage[3, 2, 3] / _fuelVolumetricHeatCapacity;

        _debugF.x = _fuelThermalStorage[1, 3, 3] / _fuelVolumetricHeatCapacity;
        _debugF.y = _fuelThermalStorage[2, 3, 3] / _fuelVolumetricHeatCapacity;
        _debugF.z = _fuelThermalStorage[3, 3, 3] / _fuelVolumetricHeatCapacity;
    }
}
