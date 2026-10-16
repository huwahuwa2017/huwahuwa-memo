
using UnityEngine;

public class Neutron21 : MonoBehaviour
{
    [SerializeField]
    private bool _next = false;

    [SerializeField]
    Vector3 _debugA = Vector3.zero;

    [SerializeField]
    Vector3 _debugB = Vector3.zero;

    [SerializeField]
    Vector3 _debugC = Vector3.zero;




    float _maximumDeltaTime = 0.005f;

    float _simulationDeltaTime = -1f;

    int _targetStepCount = -1;


    // 即発中性子の世代時間 (Λ) (中性子が発生してから吸収・核分裂を経て次の中性子が発生するまでの平均時間)
    // float _generationTime = 0.0001f;




    // cm
    float _cellSize = 78f;

    // 熱中性子の速度 (cm/s)
    float _thermalNeutronVelocity = 220000f;//220000f;

    // https://www.nuclear-power.com/nuclear-power/reactor-physics/neutron-diffusion-theory/diffusion-coefficient
    // H2O : D = 0.142
    // 中性子拡散係数 (cm)
    float _diffusionCoefficient = 0.142f;

    // https://en.wikipedia.org/wiki/Uranium-235
    // U235 の核分裂の中性子生成数
    float _neutronYield = 2.43f;

    // 巨視的熱中性子吸収断面積
    float _macroscopicThermalNeutronAbsorptionCrossSection = 0.63193f * 0.201674f;

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


    int _startIndex = 1;
    int _endIndex = 7;

    private void Start()
    {
        float fdt = Time.fixedDeltaTime;

        _targetStepCount = (int)Mathf.Ceil(fdt / _maximumDeltaTime);
        _simulationDeltaTime = fdt / _targetStepCount;

        Debug.Log("Time.fixedDeltaTime : " + fdt.ToString());
        Debug.Log("_simulationDeltaTime : " + _simulationDeltaTime.ToString());


        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                for (int z = _startIndex; z < _endIndex; ++z)
                {
                    float nf = 10f;

                    _neutronFlux[x, y, z] = nf;

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
        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                for (int z = _startIndex; z < _endIndex; ++z)
                {
                    float nf = _neutronFlux[x, y, z];
                    float pc = _precursor[x, y, z];

                    // νΣf​ϕ
                    float temp0 = _neutronYield * _macroscopicThermalNeutronFissionCrossSection * nf;

                    // 拡散
                    // ∇⋅(D∇ϕ) = D∇^2ϕ
                    float temp1 = _neutronFlux[x - 1, y, z] + _neutronFlux[x + 1, y, z] + _neutronFlux[x, y - 1, z] + _neutronFlux[x, y + 1, z] + _neutronFlux[x, y, z - 1] + _neutronFlux[x, y, z + 1] - 6f * nf;
                    temp1 = temp1 * _diffusionCoefficient / (_cellSize * _cellSize);

                    // 核分裂
                    // (1-β)νΣf​ϕ
                    float temp2 = (1f - _delayedFraction) * temp0;

                    // 中性子吸収
                    // Σa​ϕ
                    float temp3 = _macroscopicThermalNeutronAbsorptionCrossSection * nf;

                    // 遅発中性子
                    // λC
                    float temp4 = _decayConstant * pc;

                    // (∇⋅(D∇ϕ) + (1-β)νΣf​ϕ - Σa​ϕ + λC)V
                    float dnf = (temp1 + temp2 - temp3 + temp4) * _thermalNeutronVelocity;

                    _neutronFluxCache[x, y, z] = nf + dnf * dt;

                    // βνΣf​ϕ
                    float temp5 = _delayedFraction * temp0;

                    // βνΣf​ϕ - λC
                    float dpc = temp5 - temp4;

                    _precursorCache[x, y, z] = pc + dpc * dt;
                }
            }
        }

        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                for (int z = _startIndex; z < _endIndex; ++z)
                {
                    float temp0 = _neutronFluxCache[x, y, z] / _neutronFlux[x, y, z];

                    if (temp0 < -1f)
                        Debug.Log("nf 発散する！ : " + temp0.ToString());

                    _neutronFlux[x, y, z] = _neutronFluxCache[x, y, z];
                    _precursor[x, y, z] = _precursorCache[x, y, z];
                }
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

        for (int count = 0; count < _targetStepCount; ++count)
        {
            Step(_simulationDeltaTime);
        }

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
