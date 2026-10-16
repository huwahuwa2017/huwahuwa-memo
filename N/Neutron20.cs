
using UnityEngine;

public class Neutron20 : MonoBehaviour
{
    [SerializeField]
    private bool _next = false;

    [SerializeField]
    Vector3 _debugA = Vector3.zero;

    [SerializeField]
    Vector3 _debugB = Vector3.zero;

    [SerializeField]
    Vector3 _debugC = Vector3.zero;




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




    // 中性子束
    float[,] _neutronFlux = new float[8, 8];
    float[,] _neutronFluxCache = new float[8, 8];

    int _startIndex = 1;
    int _endIndex = 7;

    private void Start()
    {
        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                _neutronFlux[x, y] = 10f;
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

        float dt = Time.fixedDeltaTime;




        // 即発中性子のみ

        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                float nf = _neutronFlux[x, y];

                // ∇⋅(D∇ϕ) = D∇^2ϕ
                float temp0 = _neutronFlux[x - 1, y] + _neutronFlux[x + 1, y] + _neutronFlux[x, y - 1] + _neutronFlux[x, y + 1] - 4f * nf;
                temp0 = temp0 * _diffusionCoefficient / (_cellSize * _cellSize);

                // νΣf​ϕ
                float temp1 = _neutronYield * _macroscopicThermalNeutronFissionCrossSection * nf;

                // Σa​ϕ
                float temp2 = _macroscopicThermalNeutronAbsorptionCrossSection * nf;

                float dnf = (temp0 + temp1 - temp2) * _thermalNeutronVelocity;

                _neutronFluxCache[x, y] = nf + dnf * dt;
            }
        }

        for (int x = _startIndex; x < _endIndex; ++x)
        {
            for (int y = _startIndex; y < _endIndex; ++y)
            {
                _neutronFlux[x, y] = _neutronFluxCache[x, y];
            }
        }




        _debugA.x = _neutronFlux[1, 1];
        _debugA.y = _neutronFlux[2, 1];
        _debugA.z = _neutronFlux[3, 1];

        _debugB.x = _neutronFlux[1, 2];
        _debugB.y = _neutronFlux[2, 2];
        _debugB.z = _neutronFlux[3, 2];

        _debugC.x = _neutronFlux[1, 3];
        _debugC.y = _neutronFlux[2, 3];
        _debugC.z = _neutronFlux[3, 3];
    }
}
