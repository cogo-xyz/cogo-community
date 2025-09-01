# **COGO 유니버설 UI 시스템 아키텍처: Figma 기반 크로스플랫폼 개발 방법론**

## **섹션 1: 아키텍처의 기초: 헤드리스, 토큰 기반 시스템**

본 섹션에서는 제안된 아키텍처의 전략적 당위성을 확립합니다. React와 Flutter라는 이종(異種)의 플랫폼을 목표로 하는 시스템에서, 플랫폼에 구애받지 않는 디자인 로직을 플랫폼별 렌더링 "헤드(Head)"로부터 분리하는 헤드리스 아키텍처가 단순한 선택이 아닌, 확장성과 유지보수성을 위한 전제 조건임을 논증할 것입니다.

### **1.1 헤드리스 디자인 시스템 패러다임 정의**

헤드리스 디자인 시스템의 핵심 개념은 UI의 로직과 구조를 시각적 표현으로부터 분리하는 것입니다.1 이 아키텍처에서 "바디(Body)"는 본 보고서에서 정의할 '유니버설 UI 스키마(Universal UI Schema, UUIS)'가 되며, "헤드(Head)"는 React와 Flutter 렌더러가 됩니다. 이 접근법은 디자인 결정에 대한 단일 진실 공급원(Single Source of Truth)을 제공하고, 디자이너와 개발자 간의 협업을 개선하며, 신속한 디자인 반복과 다중 채널 전송을 가능하게 합니다.1

이 시스템의 가장 기본적인 단위는 디자인 토큰(Design Tokens)입니다. 디자인 토큰은 색상, 간격, 타이포그래피와 같은 원자적 디자인 결정을 나타내며, 특정 구현 기술로부터 완전히 분리된 데이터입니다.1

### **1.2 COGO 시스템에 헤드리스 아키텍처가 필수적인 이유**

헤드리스 아키텍처의 채택은 COGO 시스템의 핵심 요구사항을 직접적으로 해결합니다. 단일 Figma 소스로부터 두 개의 매우 다른 플랫폼(웹용 React와 모바일용 Flutter)을 지원해야 하는 과제는 이 아키텍처의 필요성을 명확히 보여줍니다.

* **유연성과 확장성**: 전통적인 방식의 결합된(coupled) 디자인 시스템은 React용과 Flutter용으로 각각 별도의, 수동으로 동기화되는 구현을 필요로 합니다. 이는 유지보수 비용을 두 배로 증가시킵니다. 반면, 헤드리스 접근법은 개발자들이 공유된 규칙 집합을 사용하여 각 플랫폼에 맞는 맞춤형 사용자 경험을 제작할 수 있게 해줍니다.1  
* **미래 확장성**: 이 아키텍처는 본질적으로 확장이 용이합니다. 미래에 COGO 시스템이 새로운 플랫폼(예: React Native, Swift UI)을 지원하기로 결정한다면, 기존의 디자인 소스나 UUIS 스키마를 변경하지 않고 새로운 "헤드"만 개발하여 추가할 수 있습니다.  
* **디자인-개발 간극 해소**: 디자인 결정을 데이터(토큰 및 JSON 스키마)로 코드화함으로써, 개발 과정에서 발생하는 모호함과 추측을 제거합니다. 패딩, 색상, 간격과 같은 값들은 디자인을 시각적으로 보고 추론하는 것이 아니라, 명시적으로 정의된 토큰을 통해 전달됩니다.4

이러한 구조적 분리는 React와 Flutter가 근본적으로 다른 렌더링 엔진, 컴포넌트 모델, 스타일링 패러다임(CSS 대 위젯 스타일링)을 가지고 있다는 사실에서 비롯됩니다. 두 플랫폼을 위한 별개의 변환기를 구축하는 것은 비효율적이며, 필연적으로 두 시스템 간의 불일치를 초래할 것입니다. 따라서 공통의 중간 계층, 즉 플랫폼에 구애받지 않는 UUIS를 도입하는 것이 논리적 귀결입니다. 이는 프로젝트의 패러다임을 '두 개의 변환기 구축'에서 '하나의 파서(Figma to UUIS)와 두 개의 렌더러(UUIS to React, UUIS to Flutter) 구축'으로 전환시키며, 이는 훨씬 더 견고하고 확장 가능한 아키텍처입니다.

### **1.3 헤드리스 접근법을 촉진하는 Tokens Studio의 역할**

Tokens Studio와 같은 Figma 플러그인은 단순한 도구를 넘어, 헤드리스 철학을 Figma 내에서 구현 가능하게 만드는 핵심 조력자입니다.1 이 플러그인은 디자인 토큰을 생성, 관리하고 구조화하는 데 필요한 인터페이스를 제공하며, 이렇게 구조화된 토큰은 헤드리스 시스템에서 소비될 수 있도록 준비됩니다. 특히, Tokens Studio가 플랫폼에 구애받지 않는 JSON 형식으로 토큰을 내보내는 기능은 디자인 로직을 Figma의 고유 형식에서 분리하는 첫 번째 결정적 단계입니다.10

## **섹션 2: 단일 진실 공급원으로서의 Figma: 디자인 인텔리전스의 구조화 및 추출**

본 섹션에서는 Figma 파일을 기계가 읽을 수 있고 COGO MCP 서버에 의해 자동화된 처리가 가능하도록 만들기 위해 요구되는, 타협 불가능한 디자인 관행과 기술적 추출 전략을 상세히 설명합니다.

### **2.1 자동화를 위한 Figma 구조화: 디자이너를 위한 계약**

성공적인 자동화 파이프라인을 위해서는 디자인 소스 자체가 기계 친화적으로 구성되어야 합니다. 이는 디자이너와 개발자 간의 명확한 계약과 같습니다.

* **Auto Layout의 최우선성**: Auto Layout의 사용은 의무적입니다. Auto Layout의 속성들은 CSS Flexbox나 Flutter의 Row/Column 위젯과 같은 현대적인 레이아웃 모델에 직접적으로 매핑되므로, 반응형 코드 생성을 가능하게 합니다.12 Auto Layout을 사용하지 않은 디자인은 자동화 파이프라인과 호환되지 않는 것으로 간주됩니다.  
* **컴포넌트화 및 Variants**: 반복적으로 사용되는 모든 UI 요소는 반드시 Figma 컴포넌트와 Variants로 정의되어야 합니다. 이를 통해 시스템은 재사용 가능한 요소를 식별하고 이를 props를 가진 코드 컴포넌트로 매핑할 수 있습니다.15  
* **엄격한 네이밍 컨벤션**: 레이어, 스타일, 토큰에 대한 명확하고 일관된 이름 규칙이 중요합니다. 추출 스크립트가 쉽게 파싱할 수 있는 규칙(예: category/group/item/state)을 제안합니다.1 일부 토큰 플러그인에서 지원하는 것처럼, 내보내기에서 제외할 레이어는 밑줄(  
  \_) 접두사를 사용할 수 있습니다.10  
* **토큰 적용**: 디자이너는 모든 색상, 타이포그래피, 간격 등에 대해 (Tokens Studio와 같은 플러그인을 통해 정의된) 디자인 토큰을 적용해야 합니다. 하드코딩된 값은 단일 진실 공급원과의 연결을 끊기 때문에 피해야 합니다.1

### **2.2 데이터 추출 전략: COGO MCP 서버와 Figma API**

시스템의 핵심인 데이터 추출은 두 가지 보완적인 API를 통해 이루어집니다. 하나는 시스템의 자동화를 위한 것이고, 다른 하나는 디자이너의 워크플로우를 위한 것입니다.

* **주요 방법: Figma REST API**: COGO MCP 서버는 Figma REST API를 주요 데이터 소스로 사용합니다. 이는 사용자의 편집기에서 플러그인을 실행할 필요가 없는 서버 대 서버 상호작용입니다. GET /v1/files/:file\_key 엔드포인트는 전체 노드 트리, 컴포넌트 정의, 스타일, 레이아웃 속성을 포함하는 Figma 파일의 완전한 JSON 표현을 반환하는 핵심 요소입니다.17 이것이 우리 시스템이 파싱할 원시 데이터입니다. MCP 서버는 개인용 액세스 토큰(PAT)을 사용하여 인증해야 합니다.17 공식  
  @figma/rest-api-spec 저장소는 API 응답에 대한 TypeScript 타입을 제공하여, 서버에서 타입-안전한 파싱 엔진을 구축하는 데 결정적인 역할을 합니다.18  
* **보조 방법: Figma Plugin API**: REST API가 배치 처리를 위한 것이라면, 동반 Figma 플러그인은 디자이너에게 실시간 피드백과 작업을 제공할 수 있습니다. Plugin API를 사용하는 이 플러그인은 24 다음과 같은 기능을 수행할 수 있습니다:  
  * 디자인이 요구되는 규칙(예: Auto Layout을 사용하지 않는 레이어 확인)에 부합하는지 검증합니다.  
  * 디자이너가 특정 프레임에 대해 MCP 서버로의 "동기화"를 트리거할 수 있게 합니다.  
  * 생성된 JSON의 편집기 내 미리보기를 제공합니다.

이 두 API는 상호 배타적인 선택이 아닙니다. 성숙한 시스템에서는 서로 다른, 보완적인 목적을 수행합니다. REST API는 MCP 서버에 의한 자동화된 서버 측 배치 처리를 위한 '시스템'의 핵심이며, Plugin API는 사용자 주도의 대화형 작업을 위한 '워크플로우'의 핵심입니다. 견고한 솔루션은 두 가지 모두를 필요로 합니다.

### **2.3 Figma 개념과 코드 구조 매핑**

이 하위 섹션은 명확한 변환 가이드를 제공합니다. 핵심은 Figma의 Auto Layout과 그에 상응하는 코드 간의 매핑입니다. 이 매핑을 공식화한 표는 시스템 문서의 참조 가능한 일부가 되며 팀을 위한 학습 도구가 됩니다.

| Figma Auto Layout 속성 | CSS Flexbox 등가물 | Flutter 위젯 및 속성 | 비고 및 구현 세부사항 |
| :---- | :---- | :---- | :---- |
| **Direction** (방향) | flex-direction: row / column | Row / Column 위젯 | Figma의 'Horizontal'은 Row, 'Vertical'은 Column에 해당합니다. |
| **Gap** (간격) | gap: \<value\>px | children 사이에 SizedBox(width/height: \<value\>) 삽입 | itemSpacing 속성에서 파생됩니다. |
| **Padding** (패딩) | padding: \<value\>px | Padding 위젯으로 감싸기 | paddingLeft, paddingRight, paddingTop, paddingBottom 속성에서 파생됩니다. |
| **Distribution** (배분) | justify-content | mainAxisAlignment | 'Packed'는 flex-start, 'Space between'은 space-between에 해당합니다. |
| **Alignment** (정렬) | align-items | crossAxisAlignment | 'Top'은 flex-start, 'Center'는 center, 'Bottom'은 flex-end에 해당합니다. |
| **Resizing (Width/Height)** | width/height, flex-grow | SizedBox, Container, Expanded, Flexible | 'Hug contents'는 내용에 맞는 크기, 'Fill container'는 flex-grow: 1 또는 Expanded에 해당하며, 'Fixed'는 고정 크기를 의미합니다. |

## **섹션 3: COGO 유니버설 UI 스키마(UUIS): UI를 위한 플랫폼 독립적 언어**

본 섹션에서는 디자인과 코드를 분리하는 중추적인 중간 표현인 3계층 JSON 스키마의 공식 사양을 제공합니다.

### **3.1 토큰 레이어 (RAW\_JSON): 디자인 프리미티브의 코드화**

이 스키마는 가장 기본적인, 분할 불가능한 디자인 결정을 정의합니다. W3C 디자인 토큰 커뮤니티 그룹(DTCG) 표준을 준수하는 구조를 강력히 권장합니다. 이는 업계 모범 사례로 부상하고 있으며 Tokens Studio와 같은 도구에서 지원되기 때문입니다.26 스키마는 최상위 키가 토큰 카테고리(예:

color, font, spacing)를 나타내는 중첩된 JSON 객체가 될 것입니다. 각 토큰은 최소한 value와 $type 속성을 포함하는 객체입니다. 값은 원시 값이거나 다른 토큰에 대한 참조(별칭)일 수 있습니다.27 W3C 표준을 채택하면 우리 시스템이 더 넓은 도구 생태계(예: style-dictionary)와 상호 운용 가능하게 되며, 독점 형식보다 미래 지향적인 결정입니다.

### **3.2 컴포넌트 레이어 (Widget/Component\_JSON): 기능적 프리미티브 정의**

이 스키마는 단일하고 독립적인 UI 요소를 설명합니다. 디자인 토큰에 대한 참조와 동작 및 콘텐츠에 대한 속성을 결합합니다. 이 구조는 jsonx 및 react-from-json과 같은 JSON-to-UI 라이브러리에서 볼 수 있는 공통 패턴에서 크게 영감을 받았습니다.29 이 스키마는 시스템의 모든 컴포넌트(간단한 버튼부터 복잡한 카드까지)에 대한 표준 "청사진" 역할을 하며, 렌더러가 개별 UI 요소를 인스턴스화하는 데 사용됩니다.

| 속성 | 타입 | 필수 여부 | 설명 |
| :---- | :---- | :---- | :---- |
| **type** | String | 예 | cogo:button 또는 cogo:textfield와 같은 고유한 문자열 식별자입니다. |
| **id** | String | 아니요 | 위젯의 고유 식별자. 상태 관리 및 이벤트 타겟팅에 사용될 수 있습니다. |
| **props** | Object | 예 | label: "Submit"과 같은 정적 속성의 키-값 맵입니다. |
| **events** | Array\[Object\] | 아니요 | 이벤트 핸들러의 배열입니다. 예: { "on": "click", "action": "SUBMIT\_FORM" }. 상호작용을 스키마의 일급 시민으로 만듭니다. |
| **children** | Array\[Object\] | 아니요 | 이 컴포넌트 내에 중첩될 자식 Widget/Component\_JSON 객체들의 배열입니다. |

### **3.3 컴포지션 레이어 (Page\_JSON): 레이아웃 및 계층 정의**

이 스키마는 전체 뷰 또는 화면을 설명합니다. 이는 루트 레이아웃 컴포넌트(예: type: "cogo:vertical-stack")로 시작하여 children 속성 내에 Widget/Component\_JSON 객체를 중첩하는 트리와 같은 구조입니다. 이 JSON의 구조는 REST API에서 파싱된 Figma 프레임의 노드 트리에서 직접 파생됩니다.18 Auto Layout에서 가져온 레이아웃 관련 속성(예:

gap, padding)은 레이아웃 컴포넌트의 props에 저장됩니다.

Figma 파일 구조 자체가 노드의 트리(FRAME은 다른 FRAME이나 컴포넌트인 자식 노드를 포함)이므로 18, 이 계층 구조는 중첩된 JSON 객체에 완벽하게 매핑됩니다. 따라서

Page\_JSON은 최상위 프레임을 나타내는 단일 Widget/Component\_JSON 객체가 될 것이며, 이 객체의 children 배열에 다른 Widget/Component\_JSON 객체들을 재귀적으로 포함하게 됩니다. 이 우아하고 자기 유사적인 구조는 파싱하기 쉽고 소스 디자인을 직접적으로 반영합니다.

## **섹션 4: 방법론 I: React 및 Tailwind CSS로의 변환**

본 섹션에서는 COGO 시스템의 "React 헤드"를 구축하기 위한 상세하고 단계적인 기술 가이드를 제공합니다.

### **4.1 아키텍처 파이프라인: UUIS에서 렌더링된 React 앱까지**

전체 프로세스는 다음과 같은 흐름을 따릅니다:

1. RAW\_JSON이 스크립트에 입력됩니다.  
2. 스크립트는 tailwind.config.js를 생성합니다.  
3. Page\_JSON은 React 애플리케이션에 의해 런타임(또는 SSG의 경우 빌드 타임)에 가져옵니다.  
4. 루트 \<UIRenderer /\> 컴포넌트가 Page\_JSON을 파싱합니다.  
5. 렌더러는 재귀적으로 type 값을 실제 React 컴포넌트에 매핑하고 props를 전달합니다.

### **4.2 토큰 수집: Tailwind 테마 생성**

RAW\_JSON 파일을 읽는 Node.js 스크립트를 제공할 것입니다. 이 스크립트는 토큰 카테고리(color, spacing, fontSize 등)를 파싱하여 tailwind.config.js의 theme.extend 객체에 필요한 구조로 변환합니다. 이 스크립트는 Tailwind 구성을 Figma 디자인 토큰과 완벽하게 동기화하는 프로세스를 자동화하여 "디자인 토큰을 단일 진실 공급원으로"라는 원칙을 직접 구현합니다.

### **4.3 유니버설 UI 렌더러 (\<UIRenderer /\>)**

이는 런타임의 핵심입니다. Page\_JSON 객체를 prop으로 받는 마스터 React 컴포넌트를 설계할 것입니다. 이 컴포넌트는 const componentMap \= { "cogo:button": Button, "cogo:textfield": TextField };와 같은 매핑 객체를 사용합니다. 컴포넌트는 JSON의 children 배열을 재귀적으로 순회하며, 각 노드에 대해 맵에서 해당하는 React 컴포넌트를 렌더링하고 JSON의 props를 전달합니다. 이 패턴은 react-from-json 30 및

jsonx 29와 같은 기존 라이브러리에 의해 검증되었습니다.

시스템은 "레이아웃" 컴포넌트와 "리프(leaf)" 컴포넌트를 구분해야 합니다. 레이아웃 컴포넌트(예: vertical-stack, grid)는 일반적이며 핵심 렌더러 라이브러리의 일부가 될 수 있습니다. 반면, 리프 컴포넌트(예: product-card, user-avatar)는 애플리케이션에 특화되어 있으며 개발자가 편집 가능한 별도의 파일로 생성되어야 합니다. 이 접근 방식은 렌더링 엔진과 애플리케이션의 비즈니스 로직 간의 명확한 관심사 분리를 만듭니다.

### **4.4 컴포넌트 생성 및 로직**

렌더러가 구조를 처리하는 동안, 실제 React 컴포넌트(Button.jsx 등)가 여전히 필요합니다. Widget/Component\_JSON 정의를 읽고 보일러플레이트 React 컴포넌트 파일을 생성하는 CLI 명령어(예: cogo-cli generate-component \--name button)를 제안합니다. 이 파일은 JSON props에서 파생된 prop 타입으로 미리 채워지지만, 내부 로직과 상태 관리(예: useState, useEffect 사용)는 개발자가 구현합니다. 이는 자동화와 개발자 제어 사이의 균형을 맞추며, 복잡한 로직은 디자인 파일에서 완전히 파생될 수 없다는 점을 인정합니다. 이 접근 방식은 Locofy나 Builder.io와 같은 고급 도구가 개발자를 위한 시작점을 생성하기 위해 AI를 사용하는 방식과 개념적으로 유사합니다.16

### **4.5 구현 예시: 버튼 렌더링**

1. **Widget/Component\_JSON (버튼용):**  
   JSON  
   {  
     "type": "cogo:button",  
     "props": {  
       "label": "Click Me",  
       "variant": "primary"  
     },  
     "events":  
   }

2. **생성된 Button.jsx:**  
   JavaScript  
   import React from 'react';

   const Button \= ({ label, variant, onClick }) \=\> {  
     const baseClasses \= 'font-bold py-2 px-4 rounded';  
     const variantClasses \= variant \=== 'primary'   
      ? 'bg-blue-500 hover:bg-blue-700 text-white'   
       : 'bg-transparent hover:bg-gray-100 text-gray-700';

     return (  
       \<button className\={\`${baseClasses} ${variantClasses}\`} onClick\={onClick}\>  
         {label}  
       \</button\>  
     );  
   };

   export default Button;

3. \<UIRenderer /\>의 사용:  
   \<UIRenderer /\>는 Page\_JSON을 파싱하다가 위 JSON 노드를 만나면, componentMap에서 cogo:button에 해당하는 Button 컴포넌트를 찾아 다음과 같이 렌더링합니다: \<Button label="Click Me" variant="primary" onClick={...} /\>. onClick 핸들러는 events 배열을 기반으로 생성됩니다.

## **섹션 5: 방법론 II: Flutter로의 변환**

본 섹션에서는 UUIS의 유연성을 보여주며 "Flutter 헤드"를 구축하기 위한 병렬 기술 가이드를 제공합니다.

### **5.1 아키텍처 파이프라인: UUIS에서 실행 중인 Flutter 앱까지**

Flutter 특정 흐름은 다음과 같습니다:

1. RAW\_JSON이 Dart 빌드 스크립트에 입력됩니다.  
2. 스크립트는 ThemeData 클래스를 포함하는 cogo\_theme.dart 파일을 생성합니다.  
3. Page\_JSON은 애셋으로 번들링되어 런타임에 Flutter 앱에 의해 로드됩니다.  
4. 중앙 "위젯 팩토리" 함수가 Page\_JSON을 파싱합니다.  
5. 팩토리 함수는 switch 문이나 Map을 사용하여 적절한 Flutter 위젯을 빌드하고 반환합니다.

### **5.2 토큰 수집: Dart에서 ThemeData 생성**

RAW\_JSON을 읽는 Dart 스크립트(예: build\_runner를 통해 실행)를 제공할 것입니다. 이 스크립트는 색상, 텍스트 스타일, 간격 값에 대한 정적 속성을 가진 class CogoTheme을 포함하는 cogo\_theme.dart 파일을 생성합니다 (예: static const Color primary \= Color(0xFF...);). 이 클래스는 MaterialApp을 위한 ThemeData 객체를 구성하는 데 사용될 수 있습니다.

### **5.3 UUIS 위젯 팩토리**

이는 React 렌더러의 Flutter 버전입니다. Widget buildWidget(Map\<String, dynamic\> json)과 같은 함수가 될 것입니다. 이 접근 방식은 Flutter 커뮤니티에서 이 패턴에 대한 견고한 모델을 확립한 json\_dynamic\_widget 패키지에 의해 강력하게 검증되었습니다.32 이 패키지의 존재는 Flutter 부분에 대한 프로젝트의 위험을 크게 줄이고 개발을 가속화하는 요인입니다. 우리는 이 JSON-to-위젯 렌더링 패턴을 처음부터 발명할 필요 없이, 전투적으로 테스트된 오픈 소스 솔루션을 채택하고 조정할 수 있습니다.

함수는 json\['type'\] 값에 대한 큰 switch 문을 가질 것입니다. 각 case는 특정 Flutter 위젯을 구성하고 반환하는 책임을 집니다(예: case 'cogo:button': return ElevatedButton(...)). JSON의 args는 위젯의 생성자에 전달됩니다. 중첩된 children은 배열의 각 자식에 대해 buildWidget을 재귀적으로 호출하여 처리됩니다.

### **5.4 상태 관리 및 액션**

UUIS에 정의된 events는 상태 관리 솔루션(예: BLoC, Provider, Riverpod)에 연결되어야 합니다. buildWidget 팩토리는 BuildContext를 인수로 받아 상태 관리 제공자에 접근할 수 있게 합니다. 버튼과 같은 위젯이 빌드될 때, onPressed 콜백은 JSON에 정의된 action을 사용하여 제공자에서 이벤트 디스패치나 함수 호출에 연결됩니다(예: context.read\<LoginBloc\>().add(SubmitForm())).

### **5.5 구현 예시: 텍스트 필드 렌더링**

1. **Widget/Component\_JSON (텍스트 필드용):**  
   JSON  
   {  
     "type": "cogo:textfield",  
     "id": "username\_field",  
     "props": {  
       "label": "Username",  
       "placeholder": "Enter your username"  
     },  
     "events":  
   }

2. **buildWidget 팩토리 내의 case 블록:**  
   Dart  
   // In buildWidget(Map\<String, dynamic\> json, BuildContext context)  
   case 'cogo:textfield':  
     final props \= json\['props'\] as Map\<String, dynamic\>;  
     return TextFormField(  
       decoration: InputDecoration(  
         labelText: props\['label'\],  
         hintText: props\['placeholder'\],  
       ),  
       onChanged: (value) {  
         // Assuming a BLoC/Cubit pattern  
         context.read\<AuthFormCubit\>().usernameChanged(value);  
       },  
     );

   이 예제에서 TextFormField의 onChanged 이벤트는 AuthFormCubit의 상태를 업데이트하는 데 사용되어, UI와 애플리케이션 상태 간의 연결을 보여줍니다.

## **섹션 6: COGO MCP 서버 통합 및 운영 거버넌스**

마지막 섹션에서는 중앙 서버의 역할을 상세히 설명하고 시스템의 장기적인 성공과 안정성을 보장하기 위해 필요한 거버넌스 모델을 수립합니다.

### **6.1 COGO MCP 서버의 역할**

이 서버는 운영의 두뇌입니다. 주요 책임은 다음과 같이 정의됩니다:

* **Figma API 게이트웨이**: Figma REST API에 대한 보안 연결 및 인증된 요청을 관리합니다.20  
* **변환 엔진**: 원시 Figma 파일 JSON을 파싱하고 18 이를 3계층 UUIS(  
  RAW\_JSON, Widget/Component\_JSON, Page\_JSON)로 변환하는 핵심 로직을 포함합니다. 섹션 2.3의 매핑 로직이 여기서 구현됩니다.  
* **스키마 유효성 검사기**: 출력된 JSON이 섹션 3에서 정의된 UUIS 사양에 부합하는지 검증합니다.  
* **아티팩트 저장소**: 버전 관리되는 UUIS JSON 아티팩트를 데이터베이스나 전용 아티팩트 저장소에 저장하며, 특정 Figma 파일 버전에 연결합니다.  
* **CI/CD 오케스트레이터**: 새롭고 검증된 UUIS 버전이 게시될 때마다 React 및 Flutter 애플리케이션의 빌드 프로세스를 시작할 수 있는 웹훅을 노출합니다.

### **6.2 Mitosis 유추: 전략적 북극성**

우리가 제안하는 아키텍처와 Mitosis 프레임워크를 직접 비교할 것입니다.35 Mitosis는 JSX의 하위 집합으로 작성된 컴포넌트를 가져와 중간 JSON 표현으로 파싱한 다음, 직렬 변환기를 사용하여 여러 프레임워크용 코드를 생성합니다.35 우리 시스템도 동일한 작업을 수행합니다: Figma는 우리의 "소스 언어"이고, UUIS는 우리의 "중간 JSON 표현"이며, React/Flutter 방법론은 "직렬 변환기"입니다. 이 시스템을 이런 방식으로 구성하면 아키텍처의 힘을 전달하는 데 도움이 되며, 최첨단 산업 동향과 일치시킵니다. 이는 우리가 COGO의 특정 요구에 맞춰진 맞춤형, 자체 개발 "무엇이든 컴파일" 프레임워크를 구축하고 있음을 보여줍니다.

### **6.3 디자인 및 개발을 위한 엔드투엔드 워크플로우**

협업 프로세스의 단계별 설명은 다음과 같습니다:

1. **디자이너**: 섹션 2.1의 규칙에 따라 Figma에서 UI를 생성/업데이트합니다.  
2. **디자이너**: 동반 플러그인을 사용하여 디자인을 검증하고 동기화를 트리거합니다.  
3. **MCP 서버**: Figma 파일을 가져와 UUIS로 변환하고, 검증하고, 버전을 매깁니다.  
4. **MCP 서버**: React 및 Flutter CI/CD 파이프라인을 트리거합니다.  
5. **개발자**: 새로운 컴포넌트 타입이 도입된 경우, 개발자는 CLI를 사용하여 보일러플레이트 파일을 생성하고 필요한 비즈니스 로직을 추가합니다.  
6. **CI/CD**: 파이프라인은 최신 토큰과 JSON을 가져와 앱을 빌드하고 검토를 위해 배포합니다.

### **6.4 버전 관리 및 거버넌스**

* **Figma 버전 관리**: Figma의 내장 버전 기록을 활용합니다. MCP 서버는 재현 가능한 빌드를 보장하기 위해 항상 Figma 파일의 특정, 명명된 버전에서 작동합니다.  
* **스키마 버전 관리**: UUIS 자체도 버전 관리되어야 합니다. 스키마에 대한 주요 변경(예: 필수 필드 추가)은 주 버전 번호를 올리고 렌더러의 조율된 업데이트가 필요합니다.  
* **분석 및 채택**: 생성된 Page\_JSON 파일을 분석하여 여러 프로젝트에서 컴포넌트 사용량을 추적하도록 MCP 서버를 확장할 수 있습니다. 이는 Figma 자체의 라이브러리 분석과 유사한 피드백 루프를 생성하여 38, 어떤 컴포넌트가 가장 가치 있고 어떤 것이 폐기될 수 있는지 식별하는 데 도움이 됩니다.

### **결론**

본 보고서는 COGO 시스템 MCP 서버 통합을 위한 체계적인 UI 스키마 설계 및 구현 방법론을 제시했습니다. 제안된 아키텍처는 Figma를 단일 진실 공급원으로 활용하고, 헤드리스 디자인 시스템 패러다임을 채택하여 플랫폼 독립적인 UUIS(Universal UI Schema)를 정의합니다. 이 UUIS는 디자인 토큰을 정의하는 RAW\_JSON, 기능적 컴포넌트를 정의하는 Widget/Component\_JSON, 그리고 화면 레이아웃을 정의하는 Page\_JSON의 3계층 구조로 구성됩니다.

이러한 접근법은 React와 Tailwind CSS, 그리고 Flutter라는 두 개의 이질적인 타겟 플랫폼에 대해 일관되고 자동화된 UI 생성을 가능하게 합니다. 각 플랫폼에 대한 변환 방법론은 토큰 수집, 동적 렌더링/위젯 팩토리 구현, 상태 관리 연동을 포함한 구체적인 기술 파이프라인을 제공합니다. COGO MCP 서버는 이 모든 프로세스를 조율하는 중앙 허브 역할을 수행하며, Figma로부터 데이터를 추출, 변환, 검증하고 CI/CD 파이프라인을 트리거합니다.

이 방법론을 채택함으로써 COGO 시스템은 개발 생산성을 극대화하고, 디자인과 코드 간의 일관성을 보장하며, 미래의 기술 변화에 유연하게 대응할 수 있는 확장 가능한 기반을 마련하게 될 것입니다. 성공적인 구현을 위해서는 디자이너와 개발자 간의 긴밀한 협력과 제안된 구조화 규칙 및 거버넌스 모델의 엄격한 준수가 필수적입니다.

#### **참고 자료**

1. Creating a headless design system using Figma \- LogRocket Blog, 8월 2, 2025에 액세스, [https://blog.logrocket.com/ux-design/creating-headless-design-system-figma/](https://blog.logrocket.com/ux-design/creating-headless-design-system-figma/)  
2. Get started with Headless Design Systems \- Mirahi | Digital Garden, 8월 2, 2025에 액세스, [https://garden.mirahi.io/get-started-with-headless-design-systems/](https://garden.mirahi.io/get-started-with-headless-design-systems/)  
3. How Designers Can Contribute to a Headless Design System | by Jasenka Gracic \- Medium, 8월 2, 2025에 액세스, [https://medium.com/design-bootcamp/how-designers-can-contribute-to-a-headless-design-system-4a36f776a1ce](https://medium.com/design-bootcamp/how-designers-can-contribute-to-a-headless-design-system-4a36f776a1ce)  
4. Ditch Rigid Design Systems and Go Headless with Figma\! \- YouTube, 8월 2, 2025에 액세스, [https://www.youtube.com/watch?v=nICHiy7IJVg](https://www.youtube.com/watch?v=nICHiy7IJVg)  
5. How to extract elements from Figma designs to build a design system? \- Reddit, 8월 2, 2025에 액세스, [https://www.reddit.com/r/DesignSystems/comments/1h7mamv/how\_to\_extract\_elements\_from\_figma\_designs\_to/](https://www.reddit.com/r/DesignSystems/comments/1h7mamv/how_to_extract_elements_from_figma_designs_to/)  
6. Six Figma Plugins to Improve Your Design System Workflows – Blog – Supernova.io, 8월 2, 2025에 액세스, [https://www.supernova.io/blog/six-figma-plugins-to-improve-your-design-system-workflows](https://www.supernova.io/blog/six-figma-plugins-to-improve-your-design-system-workflows)  
7. docs.tokens.studio, 8월 2, 2025에 액세스, [https://docs.tokens.studio/figma/export\#:\~:text=Once%20you%20have%20created%20your,based%20on%20your%20desired%20task.\&text=Confirm%20and%20complete%20the%20export.](https://docs.tokens.studio/figma/export#:~:text=Once%20you%20have%20created%20your,based%20on%20your%20desired%20task.&text=Confirm%20and%20complete%20the%20export.)  
8. Variables and Tokens Studio \- Tokens Studio for Figma, 8월 2, 2025에 액세스, [https://docs.tokens.studio/figma/variables-overview](https://docs.tokens.studio/figma/variables-overview)  
9. UnStyled headless Figma UI Kit \- Tokens Studio, 8월 2, 2025에 액세스, [https://tokens.studio/legacy/blog/unstyled-headless-figma-ui-kit](https://tokens.studio/legacy/blog/unstyled-headless-figma-ui-kit)  
10. Figma plugin to export design tokens to json in an amazon style dictionary compatible format. \- GitHub, 8월 2, 2025에 액세스, [https://github.com/lukasoppermann/design-tokens](https://github.com/lukasoppermann/design-tokens)  
11. Exposing Figma tokens to design system consumers \- Rangle.io, 8월 2, 2025에 액세스, [https://rangle.io/blog/exposing-figma-tokens-to-design-system-consumers](https://rangle.io/blog/exposing-figma-tokens-to-design-system-consumers)  
12. Flutter Fast-Track: Instantly Export Figma Designs to Cross-Platform Code \- DEV Community, 8월 2, 2025에 액세스, [https://dev.to/atforeveryoung/flutter-fast-track-instantly-export-figma-designs-to-cross-platform-code-1be6](https://dev.to/atforeveryoung/flutter-fast-track-instantly-export-figma-designs-to-cross-platform-code-1be6)  
13. How to use auto layout in Figma \- delasign, 8월 2, 2025에 액세스, [https://www.delasign.com/blog/figma-auto-layout/](https://www.delasign.com/blog/figma-auto-layout/)  
14. Auto Layout in Figma | Epic Web Dev, 8월 2, 2025에 액세스, [https://www.epicweb.dev/tips/auto-layout-in-figma](https://www.epicweb.dev/tips/auto-layout-in-figma)  
15. Convert your Figma designs to Flutter code in a flash \- Locofy.ai, 8월 2, 2025에 액세스, [https://www.locofy.ai/convert/figma-to-flutter](https://www.locofy.ai/convert/figma-to-flutter)  
16. Convert Figma to React: Get pixel perfect, high-quality code with Lightning \- Locofy.ai, 8월 2, 2025에 액세스, [https://www.locofy.ai/convert/figma-to-react](https://www.locofy.ai/convert/figma-to-react)  
17. Figma API | Documentation | Postman API Network, 8월 2, 2025에 액세스, [https://www.postman.com/doitagain/figma/documentation/t8z8pvo/figma-api](https://www.postman.com/doitagain/figma/documentation/t8z8pvo/figma-api)  
18. figma/rest-api-spec: OpenAPI specification and types for the ... \- GitHub, 8월 2, 2025에 액세스, [https://github.com/figma/rest-api-spec](https://github.com/figma/rest-api-spec)  
19. Figma Token Exporter | This tool is designed to extract Figma variables/tokens and export them in CSS, SASS and other formats for development., 8월 2, 2025에 액세스, [https://figma-tokens.com/](https://figma-tokens.com/)  
20. Figma API | Get Started \- Postman, 8월 2, 2025에 액세스, [https://www.postman.com/doitagain/figma/collection/t8z8pvo/figma-api](https://www.postman.com/doitagain/figma/collection/t8z8pvo/figma-api)  
21. How to Use the Figma API and Read Figma Documents \- 4.1 | newline, 8월 2, 2025에 액세스, [https://www.newline.co/courses/newline-guide-to-react-component-design-systems-with-figmagic/how-to-use-the-figma-api-and-read-figma-documents](https://www.newline.co/courses/newline-guide-to-react-component-design-systems-with-figmagic/how-to-use-the-figma-api-and-read-figma-documents)  
22. rest-api-spec/dist/api\_types.ts at main \- GitHub, 8월 2, 2025에 액세스, [https://github.com/figma/rest-api-spec/blob/main/dist/api\_types.ts](https://github.com/figma/rest-api-spec/blob/main/dist/api_types.ts)  
23. didoo/figma-api: Figma REST API implementation with TypeScript, Promises & ES6 \- GitHub, 8월 2, 2025에 액세스, [https://github.com/didoo/figma-api](https://github.com/didoo/figma-api)  
24. How to Create a Figma Plugin to Automate Your Design Workflow | by Anna Tran | Medium, 8월 2, 2025에 액세스, [https://medium.com/@anna235/motivation-3ea317c374a9](https://medium.com/@anna235/motivation-3ea317c374a9)  
25. BYFP 2: Introduction to Plugins & API – Figma Learn \- Help Center, 8월 2, 2025에 액세스, [https://help.figma.com/hc/en-us/articles/4407275338775--BYFP-2-Introduction-to-Plugins-API](https://help.figma.com/hc/en-us/articles/4407275338775--BYFP-2-Introduction-to-Plugins-API)  
26. Token Format \- W3C DTCG vs Legacy \- Tokens Studio for Figma, 8월 2, 2025에 액세스, [https://docs.tokens.studio/manage-settings/token-format](https://docs.tokens.studio/manage-settings/token-format)  
27. Token Values \- Tokens Studio for Figma, 8월 2, 2025에 액세스, [https://docs.tokens.studio/manage-tokens/token-values](https://docs.tokens.studio/manage-tokens/token-values)  
28. Strategy to generate the Tokens Studio(Figma) JSON file converter for Tailwind CSS and Emotion \- Brandon Wie, 8월 2, 2025에 액세스, [https://brandonwie.medium.com/strategy-to-generate-the-tokens-studio-figma-json-file-converter-for-tailwind-css-and-emotion-735f28240f20](https://brandonwie.medium.com/strategy-to-generate-the-tokens-studio-figma-json-file-converter-for-tailwind-css-and-emotion-735f28240f20)  
29. JSONX \- Create React Elements, JSX and HTML from JSON \- GitHub, 8월 2, 2025에 액세스, [https://github.com/repetere/jsonx](https://github.com/repetere/jsonx)  
30. measuredco/react-from-json: Declare your React component tree in JSON \- GitHub, 8월 2, 2025에 액세스, [https://github.com/measuredco/react-from-json](https://github.com/measuredco/react-from-json)  
31. Figma to Flutter: Convert designs to Flutter code \- Builder.io, 8월 2, 2025에 액세스, [https://www.builder.io/blog/figma-to-flutter](https://www.builder.io/blog/figma-to-flutter)  
32. json\_dynamic\_widget | Flutter package \- Pub.dev, 8월 2, 2025에 액세스, [https://pub.dev/packages/json\_dynamic\_widget](https://pub.dev/packages/json_dynamic_widget)  
33. Server‑Driven UI in Flutter Using JSON Configuration \- Vibe Studio, 8월 2, 2025에 액세스, [https://vibe-studio.ai/insights/server-driven-ui-in-flutter-using-json-configuration](https://vibe-studio.ai/insights/server-driven-ui-in-flutter-using-json-configuration)  
34. Dynamic JSON Widgets in Flutter: A Flexible Solution | by Techdynasty \- Medium, 8월 2, 2025에 액세스, [https://techdynasty.medium.com/dynamic-json-widgets-in-flutter-a-flexible-solution-3d4ef30ca7af](https://techdynasty.medium.com/dynamic-json-widgets-in-flutter-a-flexible-solution-3d4ef30ca7af)  
35. Mitosis Overview \- Builder.io, 8월 2, 2025에 액세스, [https://mitosis.builder.io/docs/overview/](https://mitosis.builder.io/docs/overview/)  
36. Using Mitosis to build a Design System \- De Voorhoede, 8월 2, 2025에 액세스, [https://www.voorhoede.nl/en/blog/write-components-once-run-everywhere-with-mitosis-a-beautiful-dream-or-reality/](https://www.voorhoede.nl/en/blog/write-components-once-run-everywhere-with-mitosis-a-beautiful-dream-or-reality/)  
37. A Quick Guide to Mitosis: Why You Need It and How You Can Use It \- Builder.io, 8월 2, 2025에 액세스, [https://www.builder.io/blog/mitosis-a-quick-guide](https://www.builder.io/blog/mitosis-a-quick-guide)  
38. View and explore library analytics – Figma Learn \- Help Center, 8월 2, 2025에 액세스, [https://help.figma.com/hc/en-us/articles/360039238353-View-and-explore-library-analytics](https://help.figma.com/hc/en-us/articles/360039238353-View-and-explore-library-analytics)  
39. Using the Figma Library Analytics API \- YouTube, 8월 2, 2025에 액세스, [https://www.youtube.com/watch?v=ywQzqMERs5E](https://www.youtube.com/watch?v=ywQzqMERs5E)