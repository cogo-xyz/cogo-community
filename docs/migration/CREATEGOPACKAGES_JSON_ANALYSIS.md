# CreateGo Packages Source Analysis - COGO JSON Schema Perspective

**Purpose**: Analyze creatego-packages source code structure based on COGO's core JSON schemas to identify mapping and migration points.

**Analysis Date**: 2025-08-31
**Source Location**: /Users/hyunsuklee/Desktop/Dev/cogo-project/creatego-packages
**Project Type**: Flutter Package (Dart/Flutter)
**COGO JSON Focus**: UI JSON, Symbol JSON, Variable JSON, ActionFlow JSON, Data Action JSON

---

## 1) Overall Architecture Mapping

### COGO JSON Schema → CreateGo Package Mapping

| COGO JSON Schema | Primary Package | Key Files/Components | Description |
|------------------|-----------------|---------------------|-------------|
| **UI JSON** | creatego_interface | `lib/src/widgets/interfaces/cg_widget.dart`<br>`lib/src/widgets/interfaces/cg_page.dart`<br>`lib/src/widgets/core_widgets/` | UI 컴포넌트 트리 구조, 위젯 인터페이스 |
| **Symbol JSON** | creatego_store | `lib/src/managers/action_manager/expression/src/symbol_store.dart`<br>`lib/src/managers/action_manager/expression/src/_Symbol` | 디자인 시스템 심볼 정의, 변수 바인딩 |
| **Variable JSON** | creatego_interface | `lib/src/models/variable/`<br>`lib/src/models/variable/variable.dart`<br>`lib/src/models/variable/types/` | 디자인 토큰/변수, 타입 시스템 |
| **ActionFlow JSON** | creatego_store | `lib/src/managers/action_manager/action_base/action_flow.dart`<br>`lib/src/managers/action_manager/action_base/action_step.dart`<br>`lib/src/managers/action_manager/builtin_actions/` | 사용자 상호작용 플로우, 액션 체인 |
| **Data Action JSON** | creatego_store | `lib/src/managers/action_manager/builtin_actions/restful_data_action.dart`<br>`lib/src/managers/action_manager/builtin_actions/sqlite_data_action.dart`<br>`lib/src/managers/action_manager/builtin_actions/rest_with_cache_action.dart` | 데이터 처리 액션, API 호출, DB 연산 |

---

## 2) Detailed Schema Analysis

### 2.1 UI JSON → creatego_interface Analysis

**Primary Components**:
```dart
// UI 컴포넌트 인터페이스
abstract class CgWidget<T> extends StatelessWidget {
  final T option;
  final String id;
  final String name;
  final String pagePath;
  final bool? isViewMode;
}

// 페이지 인터페이스
abstract class CgPage extends StatefulWidget {
  final PageMd page;
  final AppDp? appDp;
}
```

**Key Features**:
- 위젯 트리 구조 지원
- 옵션 기반 컴포넌트 설정
- 페이지 단위 구성
- 뷰모드/편집모드 지원

**COGO Mapping**:
- UI JSON의 `tree` 구조 ↔ 위젯 트리
- UI JSON의 `meta` ↔ pagePath, id 등 메타데이터
- UI JSON의 `props` ↔ option 객체

---

### 2.2 Symbol JSON → creatego_store Analysis

**Primary Components**:
```dart
class SymbolStore {
  Map<String, _Symbol> _symbols = {};
  
  // 심볼 관리
  void addSymbol(String key, {String? boundVariable});
  dynamic getValue(String key);
  bool setValue(String key, dynamic value);
}

class _Symbol {
  final int id;
  final String name;
  final List<_Variable> variables;
  
  factory _Symbol.fromJson(Map<String, dynamic> json) {
    // 심볼 JSON 파싱
  }
}
```

**Key Features**:
- 심볼 기반 변수 바인딩 (`#symbolName`)
- 동적 변수 관리 (`#_scope.variable`)
- JSON 직렬화 지원
- 스코프 기반 네임스페이스

**COGO Mapping**:
- Symbol JSON의 `name` ↔ 심볼 키
- Symbol JSON의 `data.boundVariables` ↔ 변수 바인딩
- Symbol JSON의 `id` ↔ 심볼 식별자

---

### 2.3 Variable JSON → creatego_interface Analysis

**Primary Components**:
```dart
class DataModelVar<T> extends Equatable {
  final String key;
  final VarType<T> type;
  
  static DataModelVar fromJson(Map<String, dynamic> json) {
    return DataModelVar(
      key: json['key'],
      type: parseType(json['type']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'type': type.toJson(),
    };
  }
}

abstract class VarType<T> {
  final String name;
  final T defaultValue;
  
  Map<String, dynamic> toJson();
}
```

**Key Features**:
- 타입 안전한 변수 시스템
- JSON 직렬화/역직렬화
- 기본값 지원
- 제네릭 타입 지원 (`StringVarType`, `NumVarType`, `BooleanVarType`)

**COGO Mapping**:
- Variable JSON의 `key` ↔ 변수 키
- Variable JSON의 `type` ↔ VarType 시스템
- Variable JSON의 `value` ↔ 기본값/현재값

---

### 2.4 ActionFlow JSON → creatego_store Analysis

**Primary Components**:
```dart
class ActionFlow {
  final String id;
  final String label;
  final String actionId;
  final String description;
  final ExecutionMode executionMode;
  List<ActionStep> steps;
  final Map<String, dynamic>? params;
  final String flowId;
  final Map<String, List<Map<String, dynamic>>>? customCallbacks;
  
  factory ActionFlow.fromJson(Map<String, dynamic> json) {
    return ActionFlow(
      id: json['id'],
      label: json['label'],
      actionId: json['actionId'],
      description: json['description'],
      executionMode: _parseExecutionMode(json['executionMode']),
      steps: (json['steps'] as List)
          .map((step) => ActionStep.fromJson(step))
          .toList(),
      // ... 기타 필드
    );
  }
}

class ActionStep {
  final String id;
  final String type;
  final Map<String, dynamic> params;
  final List<String> nextSteps;
}
```

**Key Features**:
- 액션 체인 기반 플로우
- 실행 모드 지원 (sync, async, isolate, parallel)
- 파라미터 시스템
- 커스텀 콜백 지원
- JSON 직렬화 완전 지원

**COGO Mapping**:
- ActionFlow JSON의 `id`/`label`/`description` ↔ 메타데이터
- ActionFlow JSON의 `steps` ↔ 액션 체인
- ActionFlow JSON의 `executionMode` ↔ 실행 모드
- ActionFlow JSON의 `params` ↔ 파라미터 시스템

---

### 2.5 Data Action JSON → creatego_store Analysis

**Primary Components**:
```dart
class RestfulDataAction implements ActBase {
  final String? baseUrl;
  final String? path;
  final String? method;
  final Map<String, String>? headers;
  final String? authJwt;
  final Map<String, dynamic>? pathParams;
  final Map<String, dynamic>? queryParams;
  final dynamic body;
  final Map<String, dynamic>? dataActionJSON;
  
  // DSL 기반 파라미터 검증
  Either<String, Map<String, dynamic>> _validateValuesWithSpec(
    Map<String, dynamic> dataActionJson,
    Map<String, dynamic> params,
  ) {
    // 타입 검증, 기본값 적용, 필수 파라미터 체크
  }
}

class SqliteDataAction implements ActBase {
  // SQLite 기반 데이터 액션
}
```

**Key Features**:
- RESTful API 호출
- DSL 기반 파라미터 검증
- 타입 안전성 보장
- SQLite 로컬 데이터베이스 지원
- 캐시 지원 (`RestWithCacheAction`)

**COGO Mapping**:
- Data Action JSON의 `endpoint` ↔ baseUrl + path
- Data Action JSON의 `method` ↔ HTTP 메소드
- Data Action JSON의 `values` ↔ 파라미터 스펙 (타입, 필수여부, 기본값)
- Data Action JSON의 `saveTo` ↔ 결과 저장 위치

---

## 3) Cross-Schema Integration Points

### 3.1 Variable ↔ Symbol Integration
```dart
// SymbolStore에서 Variable 참조
dynamic getValue(String key) {
  if (key.startsWith('#_')) {
    // Variable 참조
    ProjectVariableMd? v = CreategoStore.state.projectState.get(scope, key);
    return v.parsedValue;
  } else {
    // Symbol을 통한 Variable 참조
    List<_Variable> variables = _symbols[key]?.variables;
    ProjectVariableMd? v = CreategoStore.state.projectState
        .get(variables.first.scope, variables.first.key);
    return v.parsedValue;
  }
}
```

### 3.2 ActionFlow ↔ Data Action Integration
```dart
// ActionFlow에서 Data Action 실행
class RestfulDataAction implements ActBase {
  @override
  Future<Either<String, ApiResponse>> execute(
    BuildContext? context,
    String methodName, 
    Map<String, dynamic> params
  ) async {
    // ActionFlow 파라미터를 사용한 API 호출
  }
}
```

### 3.3 UI ↔ Variable/Symbol Integration
```dart
// 위젯에서 Variable/Symbol 바인딩
class SomeWidget extends CgWidget<SomeOption> {
  @override
  Widget build(BuildContext context) {
    // SymbolStore를 통한 데이터 바인딩
    final variables = SymbolStore.instance.getVariables(option.bindingMap);
    return Container(/* 변수 값 사용 */);
  }
}
```

---

## 4) Migration Strategy by Schema

### 4.1 UI JSON Migration
**Current → COGO**:
- `CgWidget`/`CgPage` 인터페이스 유지
- 옵션 시스템 → COGO UI JSON props 매핑
- 트리 구조 → COGO tree 구조 변환
- **Effort**: Medium (매핑 로직 추가)

### 4.2 Symbol JSON Migration
**Current → COGO**:
- `SymbolStore` → COGO Symbol JSON 구조로 변환
- `#symbol`/`#_variable` 구문 유지
- 바인딩 시스템 → COGO boundVariables 매핑
- **Effort**: Low (JSON 구조 변환만 필요)

### 4.3 Variable JSON Migration
**Current → COGO**:
- `DataModelVar<T>` → COGO Variable JSON 구조로 변환
- `VarType` 시스템 → COGO type 시스템 매핑
- JSON 직렬화 유지
- **Effort**: Low (구조 매핑만 필요)

### 4.4 ActionFlow JSON Migration
**Current → COGO**:
- `ActionFlow` 클래스 → COGO ActionFlow JSON 구조로 변환
- `ActionStep` → steps 배열 매핑
- 실행 모드/콜백 시스템 유지
- **Effort**: Low (JSON 구조 변환만 필요)

### 4.5 Data Action JSON Migration
**Current → COGO**:
- `RestfulDataAction` → COGO Data Action JSON 구조로 변환
- DSL 파라미터 검증 유지
- 타입 안전성 보장
- **Effort**: Medium (API 엔드포인트 매핑 필요)

---

## 5) Implementation Priority

### Phase 1 (High Priority - Core Infrastructure)
1. **Variable JSON**: 가장 단순한 구조, 다른 스키마의 기반
2. **Symbol JSON**: Variable에 의존, 바인딩 시스템
3. **Data Action JSON**: API 호출 패턴 표준화

### Phase 2 (Medium Priority - UI/Interaction)
4. **UI JSON**: 컴포넌트 트리 구조
5. **ActionFlow JSON**: 사용자 상호작용 플로우

### Phase 3 (Integration & Testing)
6. Cross-schema 통합 포인트 검증
7. End-to-end 테스트
8. Performance 벤치마크

---

## 6) Key Migration Benefits

### Schema Consistency
- 모든 JSON 스키마가 COGO 표준 구조 준수
- 타입 안전성과 직렬화 일관성 확보

### Interoperability
- COGO 플랫폼 다른 컴포넌트와 seamless 통합
- 공유 SDK 활용 가능

### Future-Proofing
- COGO 플랫폼 발전에 자동 대응
- 새로운 기능 즉시 활용 가능

---

## 7) Technical Considerations

### Breaking Changes
- JSON 구조 변경으로 기존 데이터 migration 필요
- API 엔드포인트 변경에 따른 클라이언트 업데이트

### Backward Compatibility
- Feature flag 기반 점진적 전환
- Legacy 모드 유지 기간 설정

### Testing Strategy
- Unit tests: 각 스키마 변환 로직
- Integration tests: Cross-schema 상호작용
- E2E tests: 완전한 워크플로우

---

## 8) Conclusion

creatego-packages는 COGO의 5개 핵심 JSON 스키마를 이미 구현하고 있으며, 구조적으로 잘 설계되어 있습니다. 마이그레이션은 주로 JSON 구조 매핑과 API 엔드포인트 변경에 집중하면 됩니다.

**Migration Readiness**: High (기존 구조가 COGO 스키마와 conceptual alignment가 좋음)

**Estimated Effort**: 2-3 weeks for full migration with testing

**Risk Level**: Medium (API 변경에 따른 integration impact)
