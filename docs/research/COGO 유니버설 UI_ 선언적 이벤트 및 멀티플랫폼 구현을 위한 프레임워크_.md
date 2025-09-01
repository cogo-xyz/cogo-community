# **COGO 유니버설 UI: 선언적 이벤트 및 멀티플랫폼 구현을 위한 프레임워크**

## **제 1부: 서버 주도 UI를 위한 선언적 이벤트 및 액션 모델**

이 섹션에서는 COGO 컴포넌트 모델의 events 배열에 대한 완전하고 공식적인 명세를 제공합니다. 이 모델은 강력하고 안전하며 완전히 선언적으로 설계되어, 사용자의 핵심 질의에 직접적으로 답변합니다.

### **1.1. 기본 원칙: 코드가 아닌 데이터로서의 이벤트**

서버 주도 UI(Server-Driven UI, SDUI) 시스템의 보안과 안정성을 보장하는 핵심 원칙은 사용자 상호작용을 실행할 명령형 코드가 아닌, 해석해야 할 구조화된 데이터로 취급하는 것입니다. 이러한 패러다임의 전환은 모든 로직을 서버와 샌드박스화된 클라이언트 측 인터프리터로 이동시켜, 임의의 코드 주입(예: JavaScript 주입) 위험을 원천적으로 차단하는 기반이 됩니다.1

이러한 접근 방식은 고전적인 이벤트 주도 아키텍처(Event-Driven Architecture, EDA)의 개념과 밀접한 관련이 있습니다.3 COGO의 이벤트 모델을 EDA의 관점에서 재구성하면 다음과 같이 비유할 수 있습니다.

* **이벤트 생산자 (Event Producer):** 서버는 잠재적 상호작용의 "청사진"인 UI JSON을 생성합니다.  
* **이벤트 소비자 (Event Consumer):** 클라이언트는 UI를 렌더링하고 사용자 입력을 수신합니다.  
* **이벤트 메시지 (Event Message):** JSON 내 events 배열은 상호작용을 정의하는 선언적 계약입니다.  
* **이벤트 핸들러/구독자 (Event Handler/Subscriber):** 클라이언트의 ActionHandler는 이 메시지를 수신하고 처리합니다.

본질적으로, 안전한 SDUI 시스템은 UI 계층에 특화된 EDA의 한 형태입니다. 서버가 전송하는 JSON 페이로드는 단순한 데이터 표시 정보를 넘어, 일련의 이벤트 메시지와 명령어 정의를 포함합니다. 이 개념 모델을 채택함으로써, 우리는 이벤트 브로커(클라이언트의 중앙 이벤트 디스패처)나 사가(Saga, 다단계 액션 처리)와 같은 검증된 EDA 패턴을 활용하여 복잡한 UI 상호작용 문제를 구조적이고 선언적인 방식으로 해결할 수 있습니다.4 이는 우리가 설계할 JSON 스키마에 대한 강력한 이론적 토대를 제공합니다.

### **1.2. COGO 이벤트 스키마: 공식 JSON 명세**

모든 이벤트 객체에 대한 명확하고 확장 가능한 스키마를 정의하는 것은 COGO 시스템의 보편적 상호작용 언어를 만드는 것과 같습니다. 이 구조를 공식적으로 정의하고 검증하기 위해 JSON 스키마를 사용하는 것을 강력히 권장합니다.6 이는 서버 응답의 자동화된 테스트를 가능하게 하고 백엔드와 프론트엔드 팀 간의 계약 무결성을 보장합니다.

다음 표는 Event 객체의 구조에 대한 최종 참조 문서 역할을 합니다. 개발자는 JSON에서 event 객체를 발견했을 때 이 표를 참조하여 모든 속성의 목적, 유형 및 필수 여부를 명확히 파악할 수 있으며, 이는 개발 속도를 높이고 버그를 줄이며 살아있는 문서로서 기능합니다.

**표 1: COGO 이벤트 스키마 정의**

| 필드 | 유형 | 필수 여부 | 설명 및 예시 |  |
| :---- | :---- | :---- | :---- | :---- |
| id | String | 아니요 | 이 특정 이벤트 정의를 위한 고유 식별자입니다. 디버깅 및 다른 액션의 대상으로 지정될 때 유용합니다. 예: "card-click-event" |  |
| trigger | String (Enum) | 예 | 이벤트를 발생시키는 사용자 상호작용입니다. 표준 UI 이벤트를 기반으로 합니다.8 예: | "onPress", "onLongPress", "onView", "onSwipe", "onChange" |
| action | Object | 예 | 이벤트가 트리거될 때 실행될 액션입니다. Action 객체 스키마는 1.4절을 참조하십시오. |  |
| propagation | Object | 아니요 | 이벤트가 컴포넌트 트리를 따라 전파되는 방식을 정의합니다 (버블링). 1.3절을 참조하십시오. 예: {"mode": "bubble", "stop": false} |  |
| debounceMs | Integer | 아니요 | 선택 사항. 이 값이 있으면 이벤트 핸들러가 지정된 밀리초만큼 디바운스되어 빠른 연속 발생을 방지합니다. |  |

### **1.3. 이벤트 전파 및 위임: 자식과 컴포넌트 이벤트 연결**

이 섹션은 "자식 위젯의 이벤트와 컴포넌트 위젯의 이벤트 간의 관계를 어떻게 정의하는가"라는 사용자의 핵심적인 기술적 과제를 직접적으로 다룹니다.

이에 대한 해결책으로, 우리는 DOM의 이벤트 버블링 및 위임 패턴을 JSON 내에서 선언적으로 모델링합니다.9 이 방식을 통해 부모 컴포넌트는 자식 컴포넌트와 강하게 결합되지 않으면서도 자식으로부터 발생하는 이벤트를 수신할 수 있습니다.

작동 메커니즘은 다음과 같습니다:

1. 자식 위젯의 이벤트는 propagation 속성을 사용하여 전파되도록 표시할 수 있습니다.  
2. 부모 컴포넌트는 직접적인 사용자 입력이 아닌, 자식으로부터 전파된 이벤트에 의해 트리거되는 event를 정의할 수 있습니다. 이는 trigger 속성값을 리스너 형식으로 변경함으로써 달성됩니다.

다음 표는 이벤트 버블링이라는 복잡하지만 중요한 기능을 위한 명확한 API를 제공합니다. 이는 사용자의 가장 구체적인 기술적 질문에 대한 직접적이고 규범적인 답변을 제공하여, 복잡한 개념을 간단한 선언적 구성으로 전환합니다.

**표 2: 이벤트 전파 및 위임 속성**

| 속성 (Event 객체 내) | 위치 | 설명 및 예시 |
| :---- | :---- | :---- |
| propagation.mode | 자식 이벤트 | Enum: "bubble" 또는 "none" (기본값). "bubble"일 경우, 이벤트가 부모에게 전달됩니다. 예: {"mode": "bubble"} |
| propagation.name | 자식 이벤트 | 선택적 문자열. 버블링되는 이벤트에 특정 이름을 부여하여 부모가 이를 수신할 수 있도록 합니다. 예: {"name": "addToCart"} |
| trigger | 부모 이벤트 | 문자열. 버블링된 이벤트를 수신하기 위해 트리거는 "onChildEvent:\<eventName\>" 형식을 사용합니다. 예: "onChildEvent:addToCart" |

이 개념을 설명하기 위한 구체적인 JSON 예시는 다음과 같습니다. 이 예시는 상품 카드 내의 '장바구니 담기' 버튼 클릭이 카드 전체의 액션을 트리거하는 과정을 보여줍니다.

JSON

// 부모 컴포넌트: 상품 카드  
{  
  "type": "component",  
  "componentId": "productCard",  
  "children":  
    }  
  \],  
  "events":  
}

위 예시에서 버튼 자체는 클릭 시 스피너를 보여주는 것과 같은 작은 시각적 상태 변경(로컬 액션)을 가질 수 있습니다. 그러나 상품을 카트에 추가하는 *비즈니스 로직*은 상품 카드 전체에 속합니다. 명명된 전파("name": "addToCart")를 사용함으로써, 버튼과 카드는 완전히 분리됩니다. 버튼은 단순히 "장바구니 담기 목적으로 내가 눌렸다"고 알릴 뿐입니다. 카드는 이 알림을 수신하고 복잡한 API 요청을 트리거합니다. 이로 인해 버튼을 아이콘이나 다른 탭 가능한 요소로 교체하더라도, 동일한 이름의 이벤트를 발생시키는 한 카드의 로직은 변경되지 않습니다. 이는 재사용성과 관심사 분리(Separation of Concerns)를 위한 강력한 패턴입니다.12

#### **1.3.1. 종합 예제: 상품 카드 컴포넌트 (플랫 구조)**

이 예제는 중첩 구조를 피하고 가독성과 재사용성을 높이기 위해 **플랫(Flat) 구조**로 개선되었습니다. 모든 액션을 actionDefinitions 블록에 중앙 집중식으로 정의하고, 각 이벤트에서는 actionId를 통해 해당 액션을 참조합니다.

JSON

{  
  "type": "component",  
  "componentId": "productCard-12345",  
  "data": {  
    "productId": "prod\_abc\_123",  
    "productName": "프리미엄 유기농 커피 원두",  
    "price": "₩25,000",  
    "imageUrl": "https://example.com/images/coffee-beans.jpg",  
    "detailsRoute": "/product/prod\_abc\_123",  
    "apiEndpoint": "/api/cart/add"  
  },  
  "actionDefinitions": {  
    "navigateToDetails": {  
      "type": "navigate",  
      "payload": {  
        "route": "${data.detailsRoute}"  
      }  
    },  
    "setButtonLoading": {  
      "type": "updateLocalState",  
      "payload": {  
        "key": "isButtonLoading",  
        "value": true  
      }  
    },  
    "addToCartRequest": {  
      "type": "apiRequest",  
      "payload": {  
        "url": "${data.apiEndpoint}",  
        "method": "POST",  
        "body": {  
          "productId": "${data.productId}"  
        },  
        "onSuccessActionId": "showSuccessDialog",  
        "onErrorActionId": "showErrorDialog"  
      }  
    },  
    "showSuccessDialog": {  
      "type": "showDialog",  
      "payload": {  
        "id": "success-dialog",  
        "content": {  
          "type": "text",  
          "text": "장바구니에 추가되었습니다\!"  
        }  
      }  
    },  
    "showErrorDialog": {  
      "type": "showDialog",  
      "payload": {  
        "id": "error-dialog",  
        "content": {  
          "type": "text",  
          "text": "오류가 발생했습니다. 다시 시도해주세요."  
        }  
      }  
    }  
  },  
  "children":  
        }  
      \]  
    }  
  \],  
  "events":  
}

이 플랫 구조의 JSON 예제는 다음과 같은 주요 이점을 보여줍니다.

* **액션의 중앙 관리**: 모든 액션 로직이 actionDefinitions 객체 내에서 고유 ID와 함께 명확하게 정의됩니다. 이를 통해 액션의 재사용이 용이해지고, 전체 컴포넌트의 동작을 한눈에 파악할 수 있습니다.  
* **구조의 단순화 및 가독성 향상**: events 배열 내부에 복잡한 액션 객체를 중첩하는 대신, actionId라는 문자열 참조만 사용하므로 구조가 훨씬 단순하고 평평해졌습니다. 이는 JSON을 읽고 유지보수하기 쉽게 만듭니다.  
* **유지보수성**: UI의 구조(children)와 동작(actionDefinitions)이 명확하게 분리되어, 향후 새로운 액션을 추가하거나 기존 로직을 수정하는 작업이 훨씬 간편해집니다.

### **1.4. COGO 액션 어휘: 표준 작업 집합**

이 시스템의 핵심은 UI가 수행할 수 있는 유한하고 안전하며 확장 가능한 "동사" 집합을 정의하는 것입니다. 이 어휘는 클라이언트 기능의 경계를 설정하여 임의의 코드 실행을 방지합니다. 이 개념은 "액션 인터페이스"나 "선언적 액션"과 같은 아이디어에서 영감을 받았습니다.13

다음 표는 UI의 "동사"(액션 유형)와 그것이 작동하는 "명사"(데이터)를 공식적으로 정의합니다. 이는 샌드박스화된 실행 환경의 핵심이며, 표준화된 어휘 없이는 각 기능 팀이 자체 액션 유형을 만들어 파편화와 복잡성을 초래할 수 있습니다. 이 표는 공통 언어를 확립하고, 재사용을 촉진하며, 클라이언트 애플리케이션의 보안 경계를 명확히 정의합니다.

**표 3: 표준 액션 어휘 및 페이로드 스키마**

| 액션 type | 페이로드 스키마 설명 | 예시 페이로드 |
| :---- | :---- | :---- |
| navigate | 내비게이션 액션을 정의합니다. route는 화면 식별자이며, params는 선택적 키-값 쌍입니다. navigationType은 push, pop, replace가 될 수 있습니다. | {"route": "/product/123", "params": {"from": "home"}} |
| apiRequest | 전체 API 요청을 설명합니다. 클라이언트 핸들러가 이를 실행하며, loading, success, error 상태에 대한 업데이트를 디스패치합니다. onSuccess와 onError는 후속 액션을 포함할 수 있습니다 (Saga 패턴).4 | {"url": "/api/data", "method": "GET", "onSuccess": {"action": {"type": "updateLocalState",...}}} |
| updateLocalState | 클라이언트의 로컬 상태 일부를 직접 변경합니다. key는 상태 조각을 식별하고, value는 새로운 데이터입니다. 간단하고 동기적인 UI 상태 변경에 사용됩니다. | {"key": "isModalVisible", "value": true} |
| showDialog | 모달 또는 다이얼로그를 트리거합니다. content는 다이얼로그 내부에 렌더링될 또 다른 COGO JSON 객체입니다. | {"content": {"type": "text", "text": "성공\!"}} |
| dispatchEvent | 한 컴포넌트의 이벤트가 다른 이벤트를 id를 통해 선언적으로 트리거할 수 있게 합니다. | {"targetEventId": "reload-data-event"} |

## **제 2부: Flutter 및 웹 구현을 위한 시스템 설계**

이 섹션에서는 선언적 JSON을 해석하여 상호작용이 가능한 네이티브 사용자 인터페이스로 변환하는 클라이언트 측 렌더링 엔진 구축을 위한 아키텍처 청사진을 제공합니다.

### **2.1. Flutter 렌더링 엔진**

#### **2.1.1. 아키텍처 개요**

COGO 시스템의 Flutter 클라이언트 아키텍처는 명확한 데이터 흐름을 따릅니다.

1. **Network Service**: 서버로부터 UI를 정의하는 JSON을 가져옵니다.  
2. **UIConfigService**: 가져온 JSON을 캐시하고 상태 관리 계층에 제공하는 역할을 합니다.15  
3. **State Management Layer (예: Riverpod Provider)**: UI 상태와 서버로부터 받은 JSON 데이터를 보관합니다.  
4. **DynamicWidgetRenderer**: 상태 관리 계층의 데이터를 소비하여 동적으로 위젯 트리를 구축합니다.  
5. **ActionHandler Service**: UI에서 발생한 이벤트를 수신하고, 이를 해석하여 새로운 액션을 실행하거나 상태 변경을 디스패치합니다.

이러한 계층 분리는 각 컴포넌트의 책임을 명확히 하여 유지보수성과 확장성을 높입니다.

#### **2.1.2. 컴포넌트 팩토리 및 위젯 매핑**

Flutter 엔진의 심장은 WidgetParser 또는 팩토리 패턴을 구현하는 것입니다.15 핵심적인 구현은 JSON 맵을 입력으로 받는

DynamicWidget 같은 메인 위젯이 될 것입니다. 이 위젯은 JSON의 type 필드를 기반으로 switch 문을 사용하여 Text, Column, ElevatedButton 등 적절한 네이티브 Flutter 위젯을 반환합니다.

수동적이고 오류 발생 가능성이 높은 JSON 파싱을 피하기 위해 17, 코드 생성을 통한 데이터 모델링을 의무화해야 합니다.

* **데이터 모델링 (Type Safety 및 자동화)**: json\_serializable과 freezed 패키지를 사용하여 모든 컴포넌트 스키마(예: TextWidgetModel, ButtonWidgetModel)를 정의합니다.18 각 스키마는  
  @freezed와 @JsonSerializable 어노테이션이 붙은 Dart 클래스로 정의됩니다. 이를 통해 불변 데이터 클래스, copyWith 메소드, 그리고 fromJson/toJson 보일러플레이트 코드가 자동으로 생성됩니다.  
* **팩토리 생성자**: factory YourModel.fromJson(Map\<String, dynamic\> json) \=\> \_$YourModelFromJson(json); 패턴은 이 아키텍처의 중심입니다.17 이 패턴을 통해  
  WidgetParser는 특정 컴포넌트의 JSON을 타입-세이프한 Dart 객체로 깔끔하게 역직렬화한 후, 이를 위젯 생성자에 전달할 수 있습니다.

Column이나 Row와 같은 레이아웃 위젯의 경우, 그들의 children 배열(List\<Map\<String, dynamic\>\>)은 각 자식 요소에 대해 메인 WidgetParser를 재귀적으로 호출하며 전체 위젯 트리를 구축하게 됩니다.15

#### **2.1.3. 이벤트 및 액션 핸들러 구현**

이벤트 처리 로직은 UI 위젯과 분리되어야 합니다. 이를 위해 ActionHandler 클래스를 정의하고, Riverpod나 Provider와 같은 상태 관리 솔루션을 통해 위젯 트리에 제공해야 합니다.22 위젯은 내비게이션이나 API 호출과 같은 비즈니스 로직을 직접 포함해서는 안 됩니다.

ActionHandler는 execute(Map\<String, dynamic\> actionJson)와 같은 메소드를 가집니다. 이 메소드는 입력받은 액션 JSON을 json\_serializable을 사용하여 ActionModel로 파싱한 후, 액션의 type에 따라 switch 문을 사용하여 적절한 앱 서비스(예: NavigationService.push(), ApiService.makeRequest(), StateNotifier.update())로 위임합니다.

#### **2.1.4. 상태 관리 및 UI 업데이트**

Riverpod와 같은 솔루션은 이 아키텍처에 이상적입니다. 앱의 각 화면이나 논리적 단위는 UI 상태를 보유하는 자체 StateNotifierProvider를 갖게 됩니다. updateLocalState 액션이 처리될 때, ActionHandler는 해당 StateNotifier의 메소드를 호출하여 상태를 업데이트합니다. UI가 반응형으로 구축되었기 때문에, Flutter는 해당 상태에 의존하는 위젯만 자동으로 효율적으로 재빌드합니다. apiRequest의 경우, 핸들러는 상태를 loading으로 업데이트한 후, API 응답에 따라 success 또는 error로 상태를 변경하여 각 단계마다 UI 변경을 트리거합니다.

### **2.2. React 및 Tailwind CSS 렌더링 엔진**

#### **2.2.1. 아키텍처 개요**

웹을 위한 아키텍처는 Flutter와 유사한 흐름을 따르지만, React 생태계에 맞는 도구를 사용합니다.

1. **Custom Hook (예: useFetchUI)**: 서버로부터 UI JSON을 가져옵니다.  
2. **State Management (예: Redux, Zustand)**: 전역 UI 상태와 JSON 데이터를 저장합니다.  
3. **JsonRenderer Component**: 상태 저장소의 데이터를 기반으로 UI를 재귀적으로 렌더링합니다.  
4. **useActionHandler Hook**: UI 이벤트를 처리하고 상태 저장소에 업데이트를 디스패치합니다.

#### **2.2.2. 컴포넌트 팩토리 및 동적 렌더링**

주요 렌더링 메커니즘은 재귀적인 React 컴포넌트인 \<JsonRenderer config={jsonNode} /\>가 될 것입니다.23

* **컴포넌트 매핑**: 중앙 componentMap.js 파일이 JSON의 문자열 type을 실제 React 컴포넌트에 매핑합니다. 예를 들어, const componentMap \= { "text": TextComponent, "button": ButtonComponent };와 같이 정의합니다.23  
  \<JsonRenderer\>는 config.type을 이 맵에서 조회하고 React.createElement나 JSX 동적 태그 (const Component \= componentMap\[config.type\]; return \<Component... /\>;)를 사용하여 올바른 컴포넌트를 렌더링합니다.  
* **재귀적 렌더링**: 자식이 있는 컴포넌트의 경우, \<JsonRenderer\>는 자식 배열을 순회하며 각 자식에 대해 재귀적으로 호출됩니다: {config.children.map(child \=\> \<JsonRenderer key={child.id} config={child} /\>)}.

#### **2.2.3. Tailwind CSS를 사용한 스타일링: 시맨틱 매핑 전략**

Tailwind의 JIT(Just-In-Time) 엔진은 최종 CSS를 생성하기 위해 소스 파일에 완전하고 정적인 클래스 이름이 존재해야 합니다. className={\\bg-${color}-500\`}\`과 같이 동적으로 문자열을 연결하는 방식은 빌드 시점에 실패하게 됩니다.26

이 문제를 해결하기 위한 가장 강력한 전략은 **시맨틱 추상화**입니다. JSON 페이로드에는 Tailwind 클래스 이름이 직접 포함되어서는 안 되며, 대신 시맨틱 스타일 토큰이 포함되어야 합니다. 이는 구현의 가장 큰 위험 요소 중 하나인 동적 클래스 문제를 해결하기 위한 구체적이고 강력한 패턴입니다. 단순히 "동적 클래스를 사용하지 말라"고 말하는 것은 불충분하며, 다음 표는 JSON에 시맨틱 API를 정의하고 React 컴포넌트 내에서 명확한 매핑 전략을 제공하여 솔루션을 실체적이고 구현 가능하게 만듭니다.

**표 4: 시맨틱 스타일 API와 Tailwind CSS 클래스 매핑**

| JSON 시맨틱 속성 | 예시 값 | React 컴포넌트 내부 매핑 | 결과적인 Tailwind 클래스 문자열 |
| :---- | :---- | :---- | :---- |
| style.colorScheme | "primary" | const schemes \= { primary: "bg-blue-600 text-white hover:bg-blue-700" } | "bg-blue-600 text-white hover:bg-blue-700" |
| style.size | "large" | const sizes \= { large: "px-6 py-3 text-lg" } | "px-6 py-3 text-lg" |
| style.padding | "medium" | const padding \= { medium: "p-4" } | "p-4" |
| layout.justify | "spaceBetween" | const justify \= { spaceBetween: "justify-between" } | "justify-between" |

각 프리젠테이셔널 React 컴포넌트(예: \<ButtonComponent\>)는 colorScheme, size와 같은 시맨틱 props를 받고, 최종 className 문자열을 생성하기 위한 매핑 로직을 내부에 포함합니다. 이 방식은 스타일링 로직을 중앙 집중화하고 시스템을 견고하게 만듭니다.

#### **2.2.4. 이벤트 및 액션 핸들러 구현**

액션 처리 로직은 useActionHandler()라는 커스텀 훅으로 캡슐화됩니다. 이 훅은 이벤트를 발생시켜야 하는 컴포넌트에서 사용됩니다.

useActionHandler 훅은 Redux의 dispatch 함수 30나 Zustand의

set 함수를 사용합니다. 액션이 트리거되면, 훅은 액션 JSON을 파싱하고 해당 상태 업데이트를 디스패치하거나 API 요청을 위한 비동기 thunk/saga를 트리거합니다. 이는 React 상태 관리 라이브러리의 표준적인 "단방향 데이터 흐름"을 따릅니다.

## **결론 및 전략적 권장사항**

### **통합 COGO 아키텍처 요약**

COGO 시스템의 핵심은 선언적 이벤트/액션 모델과 이를 소비하는 플랫폼별 렌더링 엔진의 조합에 있습니다. 이 렌더링 엔진들은 각기 다른 기술 스택(Flutter, React)을 사용하지만, 아키텍처적으로는 병렬적인 구조(팩토리 패턴, 액션 핸들러, 상태 관리)를 가집니다. 이 통일된 모델은 개발 효율성과 플랫폼 간 일관성을 극대화합니다.

### **주요 전략적 권장사항**

* **스키마 버전 관리**: 모든 JSON 응답의 루트에 schemaVersion 필드를 포함하는 것이 필수적입니다. 클라이언트는 이 버전을 확인하고, 파싱할 수 없는 버전을 만났을 때 "업데이트 필요" 메시지를 표시하는 등 우아한 대체 처리를 제공해야 합니다. 이는 장기적인 유지보수와 하위 호환성을 위해 매우 중요합니다.13  
* **캐싱 및 오프라인 전략**: 마지막으로 유효했던 JSON 응답을 클라이언트 측에 캐싱하여 오프라인 환경에서도 기능적인 경험을 제공하거나 초기 로딩 속도를 개선하는 것이 중요합니다.22  
* **오류 처리**: 클라이언트가 잘못된 형식의 JSON을 받거나 알 수 없는 컴포넌트 type을 마주쳤을 때의 전략을 정의해야 합니다. 렌더러는 충돌하는 대신, 디버깅을 용이하게 하기 위해 눈에 보이는 오류 컴포넌트를 렌더링해야 합니다.

다음 표는 리더와 아키텍트가 두 플랫폼의 구현 접근 방식의 주요 유사점과 차이점을 한눈에 파악할 수 있도록 고수준의 요약을 제공합니다. 이 표는 사용되는 *도구*는 다르지만, 아키텍처 *패턴*은 놀라울 정도로 유사하다는 점을 강조하며, 이는 통합 COGO 모델의 타당성을 강화합니다.

**표 5: 플랫폼 구현 전략 비교**

| 아키텍처 관심사 | Flutter 접근 방식 | React 접근 방식 | 핵심 원리 |
| :---- | :---- | :---- | :---- |
| **컴포넌트 매핑** | switch 문을 사용하는 WidgetParser | 컴포넌트 맵 객체를 사용하는 \<JsonRenderer\> | 동적 인스턴스화를 위한 팩토리 패턴 |
| **데이터 모델링** | freezed / json\_serializable | Plain JavaScript Objects (또는 TypeScript 타입) | Flutter의 정적 타이핑은 코드 생성의 이점을 크게 누림 |
| **이벤트/액션 처리** | 중앙 ActionHandler 서비스 (Riverpod) | useActionHandler 커스텀 훅 (Redux/Zustand) | 비즈니스 로직을 렌더링 컴포넌트로부터 분리 |
| **스타일링** | 위젯의 style 속성 | 정적 Tailwind 클래스에 매핑되는 시맨틱 props | Tailwind JIT 컴파일 제약 조건 해결 |
| **상태 관리** | Riverpod / Provider | Redux / Zustand / Jotai | 상태 변경에 기반한 반응형 UI 업데이트 활성화 |

#### **참고 자료**

1. Server-Driven UI Basics \- Apollo GraphQL Docs, 8월 3, 2025에 액세스, [https://www.apollographql.com/docs/graphos/schema-design/guides/sdui/basics](https://www.apollographql.com/docs/graphos/schema-design/guides/sdui/basics)  
2. Coding a Server-Driven UI \- Adeesh Sharma, 8월 3, 2025에 액세스, [https://blog.adeeshsharma.com/coding-a-server-driven-ui](https://blog.adeeshsharma.com/coding-a-server-driven-ui)  
3. Event-Driven Architecture \- System Design \- GeeksforGeeks, 8월 3, 2025에 액세스, [https://www.geeksforgeeks.org/system-design/event-driven-architecture-system-design/](https://www.geeksforgeeks.org/system-design/event-driven-architecture-system-design/)  
4. Common Design Patterns for Event-Driven Architecture | by Sumit Bhattacharyya | Medium, 8월 3, 2025에 액세스, [https://medium.com/@howtodoml/common-design-patterns-for-event-driven-architecture-918ea9d24ea3](https://medium.com/@howtodoml/common-design-patterns-for-event-driven-architecture-918ea9d24ea3)  
5. The Ultimate Guide to Event-Driven Architecture Patterns \- Solace, 8월 3, 2025에 액세스, [https://solace.com/event-driven-architecture-patterns/](https://solace.com/event-driven-architecture-patterns/)  
6. JSON Schema, 8월 3, 2025에 액세스, [https://json-schema.org/](https://json-schema.org/)  
7. Why You Should Start Adopting JSON Schema Forms in Your Next Project | by Vipin Tanna, 8월 3, 2025에 액세스, [https://betterprogramming.pub/why-you-should-start-adopting-json-schema-forms-in-your-next-project-547dbcbc800a](https://betterprogramming.pub/why-you-should-start-adopting-json-schema-forms-in-your-next-project-547dbcbc800a)  
8. UI Events \- W3C, 8월 3, 2025에 액세스, [https://www.w3.org/TR/uievents/](https://www.w3.org/TR/uievents/)  
9. All about JavaScript DOM event delegation \- GitHub, 8월 3, 2025에 액세스, [https://github.com/shawnbot/event-delegation](https://github.com/shawnbot/event-delegation)  
10. Event delegation \- The Modern JavaScript Tutorial, 8월 3, 2025에 액세스, [https://javascript.info/event-delegation](https://javascript.info/event-delegation)  
11. Event Delegation \- David Walsh Blog, 8월 3, 2025에 액세스, [https://davidwalsh.name/event-delegate](https://davidwalsh.name/event-delegate)  
12. Server-Driven UI Design Patterns: A Professional Guide with Examples \- Dev Cookies, 8월 3, 2025에 액세스, [https://devcookies.medium.com/server-driven-ui-design-patterns-a-professional-guide-with-examples-a536c8f9965f](https://devcookies.medium.com/server-driven-ui-design-patterns-a-professional-guide-with-examples-a536c8f9965f)  
13. Server-driven UI (or Backend driven UI) strategies · MobileNativeFoundation discussions · Discussion \#47 \- GitHub, 8월 3, 2025에 액세스, [https://github.com/MobileNativeFoundation/discussions/discussions/47](https://github.com/MobileNativeFoundation/discussions/discussions/47)  
14. Introduction to Declarative Actions \- ServiceNow Community, 8월 3, 2025에 액세스, [https://www.servicenow.com/community/next-experience-articles/introduction-to-declarative-actions/ta-p/2332003](https://www.servicenow.com/community/next-experience-articles/introduction-to-declarative-actions/ta-p/2332003)  
15. Flutter Server-Driven UI: Building Dynamic Apps with Remote Configuration. \- Medium, 8월 3, 2025에 액세스, [https://medium.com/@mohamedyousufdev/server-driven-ui-in-flutter-43d2b0a35960](https://medium.com/@mohamedyousufdev/server-driven-ui-in-flutter-43d2b0a35960)  
16. Building Server-Driven UI with Flutter: The Future of Dynamic Apps \- Technaureus, 8월 3, 2025에 액세스, [https://www.technaureus.com/blog-detail/building-server-driven-ui-with-flutter-the-future](https://www.technaureus.com/blog-detail/building-server-driven-ui-with-flutter-the-future)  
17. JSON and serialization \- Flutter Documentation, 8월 3, 2025에 액세스, [https://docs.flutter.dev/data-and-backend/serialization/json](https://docs.flutter.dev/data-and-backend/serialization/json)  
18. freezed | Dart package \- Pub.dev, 8월 3, 2025에 액세스, [https://pub.dev/packages/freezed](https://pub.dev/packages/freezed)  
19. json\_serializable | Dart package \- Pub.dev, 8월 3, 2025에 액세스, [https://pub.dev/packages/json\_serializable](https://pub.dev/packages/json_serializable)  
20. Understanding JSON Serialization in Flutter: A Comprehensive Guide | by Kavy mistry, 8월 3, 2025에 액세스, [https://medium.com/@kavyamistry0612/understanding-json-serialization-in-flutter-a-comprehensive-guide-363e99d017bd](https://medium.com/@kavyamistry0612/understanding-json-serialization-in-flutter-a-comprehensive-guide-363e99d017bd)  
21. Factory and named constructor for json mapping in dart \- Stack Overflow, 8월 3, 2025에 액세스, [https://stackoverflow.com/questions/64991010/factory-and-named-constructor-for-json-mapping-in-dart](https://stackoverflow.com/questions/64991010/factory-and-named-constructor-for-json-mapping-in-dart)  
22. Server-Driven UI in Flutter — Build Once, Update Instantly | by Harshit Sachan \- Medium, 8월 3, 2025에 액세스, [https://medium.com/@harshit.26sachan/server-driven-ui-in-flutter-build-once-update-instantly-2854429d9843](https://medium.com/@harshit.26sachan/server-driven-ui-in-flutter-build-once-update-instantly-2854429d9843)  
23. How to render dynamic component defined in JSON using React \- Storyblok, 8월 3, 2025에 액세스, [https://www.storyblok.com/tp/react-dynamic-component-from-json](https://www.storyblok.com/tp/react-dynamic-component-from-json)  
24. How to Render a Component Dynamically Based on a JSON Config \- Pluralsight, 8월 3, 2025에 액세스, [https://www.pluralsight.com/resources/blog/guides/how-to-render-a-component-dynamically-based-on-a-json-config](https://www.pluralsight.com/resources/blog/guides/how-to-render-a-component-dynamically-based-on-a-json-config)  
25. The Component Factory \- Sitecore Documentation, 8월 3, 2025에 액세스, [https://doc.sitecore.com/xp/en/developers/hd/latest/sitecore-headless-development/the-component-factory.html](https://doc.sitecore.com/xp/en/developers/hd/latest/sitecore-headless-development/the-component-factory.html)  
26. Detecting classes in source files \- Core concepts \- Tailwind CSS, 8월 3, 2025에 액세스, [https://tailwindcss.com/docs/detecting-classes-in-source-files](https://tailwindcss.com/docs/detecting-classes-in-source-files)  
27. How load dynamic class · tailwindlabs tailwindcss · Discussion \#10361 \- GitHub, 8월 3, 2025에 액세스, [https://github.com/tailwindlabs/tailwindcss/discussions/10361](https://github.com/tailwindlabs/tailwindcss/discussions/10361)  
28. The One 'GOTCHA' Tailwind Dynamic Class Names \- Medium, 8월 3, 2025에 액세스, [https://medium.com/@amitrockach/the-one-gotcha-of-tailwind-dynamic-class-names-15d7cee5abc5](https://medium.com/@amitrockach/the-one-gotcha-of-tailwind-dynamic-class-names-15d7cee5abc5)  
29. How to change a Tailwind Class based on React State/Props \[duplicate\] \- Stack Overflow, 8월 3, 2025에 액세스, [https://stackoverflow.com/questions/77153821/how-to-change-a-tailwind-class-based-on-react-state-props](https://stackoverflow.com/questions/77153821/how-to-change-a-tailwind-class-based-on-react-state-props)  
30. React redux passing event handler through connect & mapDispatchToProps vs. rendering child with props \- Stack Overflow, 8월 3, 2025에 액세스, [https://stackoverflow.com/questions/39070303/react-redux-passing-event-handler-through-connect-mapdispatchtoprops-vs-rende](https://stackoverflow.com/questions/39070303/react-redux-passing-event-handler-through-connect-mapdispatchtoprops-vs-rende)  
31. Redux Fundamentals, Part 2: Concepts and Data Flow, 8월 3, 2025에 액세스, [https://redux.js.org/tutorials/fundamentals/part-2-concepts-data-flow](https://redux.js.org/tutorials/fundamentals/part-2-concepts-data-flow)  
32. Unlock Dynamic Mobile Experiences with Server-Driven UI | by Cygnis \- Medium, 8월 3, 2025에 액세스, [https://medium.com/cygnis-media/server-driven-ui-redefining-mobile-app-development-for-dynamic-experiences-963fcdcefbc8](https://medium.com/cygnis-media/server-driven-ui-redefining-mobile-app-development-for-dynamic-experiences-963fcdcefbc8)