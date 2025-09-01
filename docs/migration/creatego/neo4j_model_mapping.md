## Neo4j 모델 매핑(초안)

이 문서는 CreateGo의 그래프 모델을 cogo 표준으로 매핑하기 위한 가이드를 제공합니다. 실제 라벨/관계/프로퍼티는 인벤토리 후 업데이트합니다.

### 인벤토리 템플릿
- 라벨: `UI:Node`, `UI:Screen`, `UI:Component`, `UI:Event`
- 관계: `(:Screen)-[:CONTAINS]->(:Component)`, `(:Component)-[:FIRES]->(:Event)`
- 프로퍼티 예: `{ id, name, type, text, style, bounds, state }`
- 인덱스/제약: `CREATE INDEX ui_node_id IF NOT EXISTS FOR (n:UI:Node) ON (n.id)`

### 매핑 방향
- CreateGo UI DSL → cogo UI DSL 동등성 확보(필드 매핑표 유지)
- 이벤트 흐름 → `actionFlow` 그래프에 투영, 시퀀스/가드/조건 표현

### 마이그레이션 산출물
- `neo4j/migrations/creatego_compat/001_init.cypher`: 인덱스/제약 생성
- `neo4j/migrations/creatego_compat/010_load_ui_graph.cypher`: LOAD CSV/UNWIND 변환 적재

### 검증 쿼리 예
```cypher
MATCH (s:UI:Screen) RETURN count(s) AS screens;
MATCH (c:UI:Component) RETURN count(c) AS components;
MATCH p = (:UI:Screen)-[:CONTAINS*..3]->(:UI:Component) RETURN count(p) AS containmentPaths;
```




### Collected Inventory Snapshot

- Nodes: 10
- Relationships: 74

<details><summary>Raw (truncated)</summary>

```json
{
  "ts": "2025-08-17T10:45:27.676Z",
  "base": "http://121.167.147.128:7475",
  "database": "neo4j",
  "nodes": [
    {
      "indexes": [
        "usedInFlows",
        "label",
        "actionId",
        "actionType"
      ],
      "name": "LoopAction",
      "constraints": [
        "Constraint( id=40, name='constraint_62b2e3f0', type='UNIQUENESS', schema=(:LoopAction {id}), ownedIndex=34 )"
      ]
    },
    {
      "indexes": [
        "actionId",
        "usedInFlows",
        "label",
        "actionType"
      ],
      "name": "SwitchAction",
      "constraints": [
        "Constraint( id=25, name='constraint_5f443da3', type='UNIQUENESS', schema=(:SwitchAction {id}), ownedIndex=9 )"
      ]
    },
    {
      "indexes": [
        "actionType",
        "usedInFlows",
        "label",
        "actionId"
      ],
      "name": "ConditionalAction",
      "constraints": [
        "Constraint( id=31, name='constraint_ac91e0d7', type='UNIQUENESS', schema=(:ConditionalAction {id}), ownedIndex=23 )"
      ]
    },
    {
      "indexes": [
        "usedInFlows",
        "actionId",
        "actionType",
        "label"
      ],
      "name": "BasicAction",
      "constraints": [
        "Constraint( id=75, name='constraint_5bf2ea1d', type='UNIQUENESS', schema=(:BasicAction {id}), ownedIndex=68 )"
      ]
    },
    {
      "indexes": [
        "usedInFlows",
        "actionType",
        "label",
        "actionId"
      ],
      "name": "CallbackAction",
      "constraints": [
        "Constraint( id=32, name='constraint_c2285a96', type='UNIQUENESS', schema=(:CallbackAction {id}), ownedIndex=19 )"
      ]
    },
    {
      "indexes": [
        "actionId",
        "usedInFlows",
        "label",
        "actionType"
      ],
      "name": "ActionFlow",
      "constraints": [
        "Constraint( id=38, name='constraint_f869968e', type='UNIQUENESS', schema=(:ActionFlow {id}), ownedIndex=7 )"
      ]
    },
    {
      "indexes": [
        "actionType",
        "label",
        "actionId",
        "usedInFlows"
      ],
      "name": "BreakAction",
      "constraints": [
        "Constraint( id=24, name='constraint_f7a7dce1', type='UNIQUENESS', schema=(:BreakAction {id}), ownedIndex=37 )"
      ]
    },
    {
      "indexes": [],
      "name": "SubflowNode",
      "constraints": []
    },
    {
      "indexes": [
        "label",
        "actionType",
        "usedInFlows",
        "actionId"
      ],
      "name": "ExpressionAction",
      "constraints": [
        "Constraint( id=14, name='constraint_2bf10488', type='UNIQUENESS', schema=(:ExpressionAction {id}), ownedIndex=20 )"
      ]
    },
    {
      "indexes": [
        "embedding"
      ],
      "name": "Embeddable",
      "constraints": []
    }
  ],
  "relationships": [
    {
      "name": "onBreak"
    },
    {
      "name": "onBreak"
    },
    {
      "name": "onBreak"
    },
    {
      "name": "onBreak"
    },
    {
      "name": "isTrue"
    },
    {
      "name": "isTrue"
    },
    {
      "name": "isTrue"
    },
    {
      "name": "isTrue"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onThen"
    },
    {
      "name": "onError"
    },
    {
      "name": "onError"
    },
    {
      "name": "onError"
    },
    {
      "name": "onError"
    },
    {
      "name": "onEnd"
    },
    {
      "name": "onEnd"
    },
    {
      "name": "onEnd"
    },
    {
      "name": "onEnd"
    },
    {
      "name": "onDrop"
    },
    {
      "name": "onDrop"
    },
    {
      "name": "onDrop"
    },
    {
      "name": "onDrop"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isValid"
    },
    {
      "name": "isFalse"
    },
    {
      "name": "isFalse"
    },
    {
      "name": "isFalse"
    },
    {
      "name": "isFalse"
    },
    {
      "name": "onDefault"
    },
    {
      "name": "onDefault"
    },
    {
      "name": "onDefault"
    },
    {
      "name": "onDefault"
    },
    {
      "name": "onDefault"
    },
    {
      "name": "onDefault"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onSuccess"
    },
    {
      "name": "onLoop"
    },
    {
      "name": "onLoop"
    },
    {
      "name": "onLoop"
    },
    {
      "name": "onLoop"
    }
  ]
}
```

</details>
