
using UnityEngine;

public class Neutron00 : MonoBehaviour
{
    [SerializeField, Range(-1f, 1f)]
    float _reactivitySpeed = 0f;

    // 反応度
    [SerializeField]
    float _reactivity = 0f;

    [SerializeField]
    float _debugKeffective = 1f;

    [SerializeField]
    float _debugNeutronPopulation = 0;

    [SerializeField]
    float _debugReactorPeriod = 0;


    // 中性子の数
    float _neutronPopulation = 100f;

    // 即発中性子の世代時間 (Λ) (中性子が発生してから吸収・核分裂を経て次の中性子が発生するまでの平均時間)
    float _generationTime = 0.0001f;




    private void FixedUpdate()
    {
        float dt = Time.fixedDeltaTime;

        _reactivitySpeed = Mathf.Round(_reactivitySpeed);

        _reactivity = _reactivity + _reactivitySpeed * 0.000001f * dt;

        float k_effective = 1f / (1f - _reactivity);
        _debugKeffective = k_effective;




        // 即発中性子のみ
        float dnp = _neutronPopulation * _reactivity / _generationTime;
        _neutronPopulation = _neutronPopulation + dnp * dt;

        _debugNeutronPopulation = _neutronPopulation;

        _debugReactorPeriod = _generationTime / _reactivity;
    }
}
