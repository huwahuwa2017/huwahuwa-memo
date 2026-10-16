using UnityEngine;

public class Neutron22 : MonoBehaviour
{
    [SerializeField]
    private bool _next = false;

    [SerializeField]
    private float _debugKInfinite = -1f;

    [SerializeField]
    float _debugReactivity = 0f;

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

    // 巨視的熱中性子吸収断面積
    [SerializeField]
    float _macroscopicThermalNeutronAbsorptionCrossSection = -1f;

    // 巨視的熱中性子核分裂断面積
    float _macroscopicThermalNeutronFissionCrossSection = 0.5245f * 0.1f;




    // 遅発中性子割合 (β)
    float _delayedFraction = 0.006502f;

    // 崩壊定数 (λ)
    float _decayConstant = 0.0768f;





    // ReactorPeriod の逆数
    float _invReactorPeriod = 0f;


    // 中性子束
    float[,,] _neutronFlux = new float[8, 8, 8];
    float[,,] _neutronFluxCache = new float[8, 8, 8];

    // 遅発中性子先行核の濃度 (C)
    float[,,] _precursor = new float[8, 8, 8];
    float[,,] _precursorCache = new float[8, 8, 8];


    int _startIndex = 1;
    int _endIndex = 7;

    private void Start()
    {
        float fdt = Time.fixedDeltaTime;
        Debug.Log("Time.fixedDeltaTime : " + fdt.ToString());


        _macroscopicThermalNeutronAbsorptionCrossSection = _neutronYield * _macroscopicThermalNeutronFissionCrossSection;


        _cellSizePow2 = _cellSize * _cellSize;


        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                for (int z = _startIndex; z < _endIndex; ++z)
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
    }

    private void Step(float dt)
    {
        float promptNeutronGrowthRate = (1f - _delayedFraction) * _neutronYield * _macroscopicThermalNeutronFissionCrossSection;
        promptNeutronGrowthRate = (promptNeutronGrowthRate - _macroscopicThermalNeutronAbsorptionCrossSection) * _thermalNeutronVelocity;

        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                for (int z = _startIndex; z < _endIndex; ++z)
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
        }

        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                for (int z = _startIndex; z < _endIndex; ++z)
                {
                    _neutronFlux[x, y, z] = _neutronFluxCache[x, y, z];
                    _precursor[x, y, z] = _precursorCache[x, y, z];
                }
            }
        }




        // 漏洩を考慮していない Keffective
        _debugKInfinite = _neutronYield * _macroscopicThermalNeutronFissionCrossSection / _macroscopicThermalNeutronAbsorptionCrossSection;

        // 漏洩を考慮していない Reactivity
        _debugReactivity = (_debugKInfinite - 1f) / _debugKInfinite;

        // 即発中性子寿命
        float promptNeutronLifetime = 1f / (_thermalNeutronVelocity * _macroscopicThermalNeutronAbsorptionCrossSection);

        // 即発中性子世代時間
        float promptNeutronGenerationTime = promptNeutronLifetime / _debugKInfinite;

        // インアワー方程式をニュートン法で解いて _invReactorPeriod を求める

        // 通常のインアワー方程式
        float inhour = (_invReactorPeriod * promptNeutronGenerationTime - _debugReactivity) + (_invReactorPeriod * _delayedFraction) / (_invReactorPeriod + _decayConstant);

        // 微分したインアワー方程式
        float temp = _invReactorPeriod + _decayConstant;
        float derivativeInhour = promptNeutronGenerationTime + (_delayedFraction * _decayConstant) / (temp * temp);

        // ニュートン法
        _invReactorPeriod = _invReactorPeriod - inhour / derivativeInhour;

        if (_debugReactivity < 0f)
        {
            // 反応度が負の場合
            float epsilon = 0.0001f;
            _invReactorPeriod = Mathf.Clamp(_invReactorPeriod, -_decayConstant + epsilon, 0f);
        }
        else
        {
            // 反応度が正の場合
            _invReactorPeriod = Mathf.Max(_invReactorPeriod, 0f);
        }

        _debugReactorPeriod = 1f / _invReactorPeriod;
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
