### **COGO 유니버설 UI 스키마(UUIS) 기술 명세서 (v2.0 \- 이벤트 시스템 강화)**

이 명세서는 이전 버전을 기반으로, 플랫폼 중립적인 이벤트 처리와 프로그램적 로직 표현을 구체화하고 제한하는 데 중점을 둡니다.

#### **1\. 스키마 계층 구조 재정의**

1. **Single Widget JSON**: UI의 가장 기본적인 기능적 단위입니다. (이전과 동일)  
2. **Component JSON**: Single Widget 또는 다른 Component들을 구조화하고 레이아웃을 정의하는 재사용 가능한 복합 단위입니다.  
3. **Page JSON**: 애플리케이션의 한 화면을 구성하는 최상위 문서입니다.

children 속성 구체화:  
Component JSON과 Page JSON의 root에 포함되는 children 속성은 Array\<SingleWidgetJSON | ComponentJSON\> 타입의 배열입니다. 즉, 자식 요소는 반드시 Single Widget 또는 Component 스키마를 준수해야 합니다.

#### **2\. 이벤트 및 액션 시스템 명세**

UUIS의 프로그램적 요소를 정의하는 핵심 부분입니다. 이 시스템은 임의의 코드 실행을 허용하지 않고, 미리 정의된 명령어 집합을 통해 UI의 동적 행동을 선언합니다.

**events 객체 상세 스키마:**

| 속성 | 타입 | 필수 여부 | 설명 |
| :---- | :---- | :---- | :---- |
| on | String | 예 | 이벤트 트리거의 이름입니다. 플랫폼 공통으로 해석 가능한 표준 이벤트 집합으로 제한됩니다. (예: "click", "submit", "change", "mount") |
| action | Object | 예 | on 이벤트가 발생했을 때 실행될 단일 액션을 정의합니다. |

**action 객체 상세 스키마:**

| 속성 | 타입 | 필수 여부 | 설명 |
| :---- | :---- | :---- | :---- |
| type | String | 예 | 실행할 액션의 종류를 나타내는 **미리 정의된 심볼**입니다. 렌더러는 이 type에 따라 내장된 로직을 수행합니다. |
| payload | Object | 아니요 | 액션 실행에 필요한 매개변수(parameters)를 담는 객체입니다. |

#### **3\. 핵심 액션 타입(action.type) 정의**

다음은 UUIS 렌더러가 기본적으로 지원해야 하는 핵심 액션 타입의 목록입니다. 이 목록은 확장될 수 있지만, 각 타입은 명확하게 정의되어야 합니다.

| action.type | 설명 | payload 예시 |
| :---- | :---- | :---- |
| NAVIGATE | 다른 페이지로 이동합니다. | { "route": "/profile" } |
| UPDATE\_STATE | UI 내부 상태 관리 시스템의 특정 값을 변경합니다. | { "key": "formData.email", "value": "${event.value}" } |
| DISPATCH\_EVENT | COGO 에이전트나 네이티브 애플리케이션의 비즈니스 로직을 호출하는 범용 후크(hook)입니다. | { "eventName": "SUBMIT\_LOGIN\_FORM", "data": "${state.formData}" } |
| FOCUS\_ELEMENT | 특정 id를 가진 다른 위젯에 포커스를 줍니다. | { "targetId": "password\_input" } |
| VALIDATE | 특정 상태 값에 대한 유효성 검사를 트리거합니다. | { "key": "formData.email" } |
| CONDITION | 조건에 따라 두 개의 다른 액션을 실행합니다. (분기 처리) | { "if": "${state.isLoggedIn}", "then": {...action... }, "else": {...action... } } |

동적 값 참조:  
payload 내에서 ${...} 구문을 사용하여 동적인 값을 참조할 수 있습니다.1

* ${event.value}: 이벤트 핸들러에서 직접 전달되는 값 (예: 텍스트 필드의 입력값).  
* ${state.variableName}: UI 내부 상태 관리 시스템에 저장된 값.

#### **4\. 업데이트된 예제**

예제 1: 아이콘이 포함된 검색창 (Component JSON)  
이전 예제를 새로운 이벤트 시스템으로 업데이트했습니다. 컨테이너 클릭 시 입력 필드에 포커스를 주는 로직이 명확하게 선언되었습니다.

JSON

{  
  "id": "main\_search\_bar",  
  "type": "cogo:search-bar",  
  "props": {  
    "variant": "outline",  
    "cornerRadius": "full"  
  },  
  "events":,  
  "children": \[  
    {  
      "id": "search\_icon",  
      "type": "cogo:icon",  
      "props": { "name": "search", "color": "text.secondary" }  
    },  
    {  
      "id": "main\_search\_input",  
      "type": "cogo:textfield",  
      "props": {  
        "placeholder": "무엇을 찾고 계신가요?",  
        "variant": "ghost"  
      },  
      "events":  
    }  
  \]  
}

예제 2: 로그인 폼 (Page JSON의 root 부분)  
상태 업데이트(UPDATE\_STATE)와 비즈니스 로직 호출(DISPATCH\_EVENT)을 포함하는 완전한 로그인 폼 예제입니다.

JSON

{  
  "id": "login\_page\_root",  
  "type": "cogo:stack",  
  "props": {  
    "layout": {  
      "direction": "vertical",  
      "gap": "medium",  
      "padding": "large"  
    }  
  },  
  "children":  
}

### **결론**

이 업데이트된 스키마는 events와 actions를 통해 **무엇을(What) 할지**를 명확하게 선언하며, **어떻게(How) 할지**는 각 플랫폼의 렌더러와 COGO 에이전트의 구현에 위임합니다. 이 엄격한 분리 원칙은 임의의 코드 주입을 방지하여 시스템의 보안과 안정성을 보장하며, React와 Flutter 등 어떤 타겟 플랫폼으로도 일관되게 변환될 수 있는 진정한 플랫폼 중립적 UI 스키마를 완성합니다.