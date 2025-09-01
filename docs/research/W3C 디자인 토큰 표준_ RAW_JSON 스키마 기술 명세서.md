# **W3C 디자인 토큰 표준: RAW\_JSON 스키마 기술 명세서**

## **W3C 디자인 토큰 표준 소개**

### **1.1 표준의 필요성**

디지털 제품 개발 생태계에서 디자인과 개발 간의 간극은 오랫동안 비효율성과 불일치성의 주요 원인이었습니다. 디자인 도구(예: Figma)에서 정의된 시각적 스타일 가이드라인—색상, 타이포그래피, 간격 등—은 개발 환경에서 코드로 수동 변환되는 과정을 거쳐야 했습니다. 이 과정은 오류 발생 가능성이 높을 뿐만 아니라, 디자인 시스템이 확장됨에 따라 유지보수가 기하급수적으로 어려워지는 문제를 야기했습니다.1 각 팀이나 도구가 독자적인 형식으로 스타일 정보를 관리하면서, 디자인 시스템의 '단일 진실 공급원(Single Source of Truth)'을 유지하는 것은 거의 불가능에 가까웠습니다.3

이러한 문제를 해결하기 위해 '디자인 토큰'이라는 개념이 등장했습니다. 디자인 토큰은 디자인 시스템의 가장 작은 단위인 시각적 속성(예: 특정 16진수 색상 코드, 폰트 크기)을 플랫폼에 구애받지 않는 변수 형태로 추상화한 것입니다. 그러나 초기에는 디자인 토큰을 구조화하고 저장하는 표준화된 방식이 부재하여, 각 도구나 조직마다 독자적인 JSON 스키마를 사용하는 파편화가 지속되었습니다. 이는 도구 간 상호운용성을 저해하고 디자인 시스템의 확장성을 제한하는 새로운 병목 현상을 초래했습니다. 이러한 배경 속에서 디자인과 개발 워크플로우를 원활하게 연결하고, 기술 스택 전반에 걸쳐 일관성을 보장할 수 있는 공통의 언어, 즉 산업 표준의 필요성이 절실하게 대두되었습니다.

### **1.2 W3C 디자인 토큰 커뮤니티 그룹(DTCG)의 역할**

이러한 산업적 요구에 부응하기 위해 W3C(World Wide Web Consortium) 산하에 디자인 토큰 커뮤니티 그룹(Design Tokens Community Group, DTCG)이 결성되었습니다.4 DTCG는 UX 전문가, 개발자, 그리고 주요 디자인 도구 공급업체의 대표들로 구성된 조직으로, 디자인 시스템의 핵심 스타일 요소를 규모에 맞게 공유할 수 있는 개방형 표준을 제정하는 것을 목표로 삼았습니다.5

DTCG의 핵심 목표는 "제품과 디자인 도구가 디자인 시스템의 스타일 요소를 대규모로 공유하는 데 의존할 수 있는 표준을 제공하는 것"입니다.4 이는 특정 도구나 플랫폼에 종속되지 않는, 상호운용 가능한 디자인 토큰 데이터 형식을 정의함으로써 달성됩니다. 이 표준을 통해 디자인 시스템은 진정한 의미의 단일 진실 공급원을 구축하고, 자동화된 워크플로우를 통해 디자인 변경 사항을 코드에 즉각적이고 정확하게 반영할 수 있게 됩니다.

DTCG 표준의 등장은 단순히 새로운 파일 형식을 제안하는 것을 넘어, 디자인 시스템 생태계의 패러다임을 전환하는 중요한 계기가 되었습니다. 과거에는 Tokens Studio와 같은 도구들이 자체적인 '레거시(legacy)' 형식을 사용하며 각자의 사일로 안에서 발전해왔지만 6, DTCG 표준은 이러한 파편화된 도구들이 서로 소통하고 협력할 수 있는 공통의 기반을 마련했습니다. 이는 특정 벤더에 대한 종속을 방지하고, 도구들이 독점적인 데이터 형식이 아닌 사용자 경험과 기능적 우수성을 바탕으로 경쟁하는 건강한 생태계를 조성하는 철학적 전환을 의미합니다. 결과적으로 Style Dictionary 7, Tokens Studio 6와 같은 다양한 변환 엔진과 관리 도구들이 동일한 토큰 파일을 소스로 사용하여 각기 다른 플랫폼(웹, iOS, Android 등)에 맞는 코드를 생성할 수 있게 되었습니다.

### **1.3 표준의 핵심 원칙**

DTCG는 장기적으로 지속 가능하고 널리 채택될 수 있는 표준을 만들기 위해 세 가지 핵심 원칙을 수립했습니다. 이 원칙들은 표준의 기술적 사양뿐만 아니라, 그것이 지향하는 생태계의 철학을 반영합니다.5

1. **포용성 (Inclusive)**: 이 표준은 특정 기술이나 도구에 대한 전문 지식 유무와 관계없이 누구나 디자인 토큰의 개념을 익히고 활용할 수 있도록 설계되었습니다. 이는 다양한 배경을 가진 사람들이 새로운 정신 모델을 개발하고, 기술을 습득하며, 프로젝트에 디자인 시스템을 확장 적용할 수 있도록 힘을 실어주는 것을 목표로 합니다. 커뮤니티의 모든 구성원이 대화에 참여하고 각자의 사용 사례를 공유하는 것을 장려하여, 표준이 실제 현장의 요구를 반영하며 발전할 수 있도록 합니다.8  
2. **집중과 확장성 (Focused, yet extensible)**: 표준 명세는 가장 보편적으로 참조되는 사용 사례를 포괄하는 데 필요한 최소한의 범위에 집중합니다. 이 작은 발자국(small footprint)은 의존성 없는 단순성을 유지하는 데 도움을 줍니다. 동시에, 표준은 $extensions와 같은 명시적인 확장 메커니즘을 제공하여 커뮤니티가 디자인 토큰의 미래를 정의할 새로운 아이디어를 실험하고 발전시킬 수 있는 플랫폼 역할을 합니다. 이는 핵심 표준의 안정성을 해치지 않으면서도 각 도구의 혁신을 장려하는 균형 잡힌 접근 방식입니다.5  
3. **안정성 (Stable)**: 이 표준은 사용자와 도구 제작자들이 장기적으로 신뢰하고 시스템의 기반으로 삼을 수 있는 안정적인 토대를 제공하는 것을 목표로 합니다. 이를 위해 JSON과 같이 이미 널리 사용되고 검증된 기존 표준을 기반으로 구축되었습니다. 이는 새로운 기술을 배우는 데 드는 장벽을 낮추고, 다양한 프로그래밍 환경에서 표준을 쉽게 채택할 수 있도록 보장합니다. 안정성은 도구 생태계가 번성하기 위한 필수 전제 조건입니다.5

이 세 가지 원칙은 DTCG 표준이 단순한 기술 문서를 넘어, 개방적이고 협력적이며 미래 지향적인 디자인 시스템 생태계를 구축하기 위한 청사진임을 보여줍니다.

## **DTCG 준수 JSON 파일의 해부학**

### **2.1 기본 구조: 그룹과 토큰**

DTCG 표준을 따르는 디자인 토큰 파일은 두 가지 기본 구성 요소, 즉 '그룹(Group)'과 '토큰(Token)'으로 이루어진 계층적 JSON 객체입니다. 이 두 요소를 명확하게 구분하는 것이 표준의 핵심입니다.

* **그룹 (Groups)**: 그룹은 디자인 토큰을 체계적으로 구성하고 분류하기 위한 구조적 요소입니다. JSON 객체로 표현되며, 다른 그룹이나 토큰을 자식으로 포함할 수 있습니다. 표준 명세에 따르면, $value 속성을 포함하지 않는 모든 객체는 그룹으로 간주됩니다.9 그룹을 중첩하여 사용함으로써  
  color.background.primary와 같이 의미 있는 계층 구조(경로)를 만들 수 있습니다.  
* **토큰 (Tokens)**: 토큰은 디자인 시스템의 개별적인 디자인 결정을 나타내는 최종 단위입니다. 표준은 토큰을 매우 엄격하고 명확하게 정의하는데, 바로 $value 속성을 포함하는 JSON 객체입니다.10 이  
  $value 속성의 존재 여부가 해당 객체가 그룹인지 토큰인지를 결정하는 유일한 기준이 됩니다.

이처럼 $value 속성의 유무를 통해 그룹과 토큰을 구분하는 방식은 표준의 의도적인 설계 결정입니다. 이는 파서(parser)나 변환 엔진의 논리를 극적으로 단순화시키는 역할을 합니다. 과거의 비표준 형식에서는 키-값 쌍이 토큰인지, 아니면 특정 속성이 없는 객체가 토큰인지 등을 추론해야 하는 모호함이 존재했습니다. 그러나 DTCG 표준에서는 파서가 JSON 트리를 순회하며 각 노드에서 if (node.hasOwnProperty('$value'))라는 간단한 조건 확인만으로 해당 노드가 처리해야 할 '토큰'인지, 아니면 더 깊이 탐색해야 할 '그룹'인지를 명확하게 판단할 수 있습니다. 이러한 설계는 변환 과정의 예측 가능성과 신뢰성을 높여주며, 다양한 도구들이 일관된 방식으로 토큰 파일을 해석할 수 있도록 보장합니다. 이는 결과적으로 표준의 '안정성' 원칙에 기여하며, 새로운 도구를 개발하는 개발자들의 진입 장벽을 낮추는 효과를 가져옵니다.8

### **2.2 파일 형식 및 미디어 타입**

DTCG 표준을 따르는 모든 디자인 토큰 파일은 반드시 유효한 JSON(JavaScript Object Notation) 형식이어야 합니다.10 JSON은 텍스트 기반의 경량 데이터 교환 형식으로, 사람이 읽고 쓰기 쉬우며 기계가 파싱하고 생성하기에도 용이하여 광범위한 프로그래밍 언어에서 기본적으로 지원됩니다. 이는 표준의 '안정성'과 '포용성' 원칙을 뒷받침하는 중요한 선택입니다.

HTTP/HTTPS를 통해 디자인 토큰 파일을 제공하거나 미디어 타입(MIME 타입)을 명시해야 하는 경우, 표준은 application/design-tokens+json을 사용할 것을 \*\*권장(SHOULD)\*\*합니다. 하지만 모든 디자인 토큰 파일은 유효한 JSON 파일이므로, 일반적인 JSON 미디어 타입인 application/json을 사용하는 것도 \*\*허용(MAY)\*\*됩니다. 표준을 준수하는 도구는 두 가지 미디어 타입을 모두 지원해야만(MUST) 합니다.10 이 규정은 다양한 서버 환경과 클라이언트에서의 호환성을 보장하기 위한 것입니다.

### **2.3 이름 지정 규칙 및 예약 문자**

파싱의 일관성과 에일리어스(alias) 구문과의 충돌을 방지하기 위해, DTCG 표준은 그룹과 토큰의 이름(즉, JSON 객체의 키)에 대한 엄격한 규칙을 명시합니다.

* 이름에는 점(.)을 포함할 수 없습니다. 점은 에일리어스 값에서 토큰 경로를 구분하는 데 사용되는 예약된 문자입니다.  
* 이름에는 중괄호({, })를 포함할 수 없습니다. 중괄호는 에일리어스 값의 시작과 끝을 나타내는 데 사용됩니다.  
* 이름은 달러 기호($)로 시작할 수 없습니다. 달러 기호는 표준 명세에서 정의된 특수 속성(예: $value, $type)을 위한 네임스페이스로 예약되어 있습니다.9

이러한 명명 규칙을 준수하는 것은 DTCG 호환 토큰 파일을 작성하는 데 있어 필수적입니다.

## **토큰 및 그룹의 핵심 속성**

### **3.1 $ 접두사: 표준을 위한 네임스페이스**

DTCG 표준에 정의된 모든 특수 속성은 달러 기호($)로 시작합니다. 이 접두사는 표준 명세에 의해 예약된 속성임을 명시하는 네임스페이스 역할을 합니다.9 이는 사용자가 정의하는 토큰이나 그룹의 이름과 표준 속성 간의 충돌을 원천적으로 방지하는 중요한 설계적 장치입니다. 예를 들어, 과거의 비표준 형식에서는 사용자가

type이나 value라는 이름의 색상 토큰을 만들 경우, 이를 파싱하는 도구가 해당 키를 토큰의 이름으로 해석해야 할지, 아니면 토큰의 속성으로 해석해야 할지 모호해지는 문제가 발생할 수 있었습니다.6

$ 접두사는 이러한 모호성을 제거하여 파싱의 안정성과 예측 가능성을 크게 향상시킵니다.

### **3.2 토큰 레벨 속성**

토큰 객체 내에서 사용되는 표준 속성은 다음과 같습니다.

* **$value (필수)**: 토큰의 실제 값을 정의합니다. 이 값은 토큰의 $type에 따라 문자열, 숫자, 불리언, 객체, 배열 등 다양한 JSON 데이터 타입을 가질 수 있습니다. $value 속성의 존재 자체가 해당 객체가 토큰임을 증명하는 유일한 기준입니다.9  
* **$type (선택 사항, 권장)**: 토큰의 의미론적 유형을 지정하는 문자열입니다 (예: "color", "dimension", "fontFamily"). 이 속성은 도구가 토큰의 값을 올바르게 해석하고, 유효성을 검사하며, 특정 플랫폼(예: CSS, iOS, Android)에 맞는 코드로 변환하는 데 결정적인 역할을 합니다. $type이 명시되지 않은 토큰은 타입이 없는(typeless) 것으로 간주될 수 있지만, 명시적으로 지정하는 것이 강력히 권장됩니다.9  
* **$description (선택 사항)**: 토큰에 대한 설명, 사용 지침, 또는 컨텍스트를 제공하는 문자열입니다. 이 속성을 적극적으로 활용하면 디자인 시스템 자체가 문서의 역할을 수행하게 되어(self-documenting), 새로운 팀원이 시스템을 이해하고 채택하는 데 큰 도움이 됩니다.9

### **3.3 그룹 레벨 속성**

그룹 객체에도 표준 속성을 적용하여 하위 토큰들의 관리를 용이하게 할 수 있습니다.

* **$type**: 그룹에 $type 속성을 정의하면, 해당 그룹 및 그 하위 그룹에 속한 모든 토큰들의 기본 타입을 설정하게 됩니다. 만약 하위 토큰이 자체적으로 $type을 명시적으로 가지고 있다면 그 값이 우선 적용되지만, 그렇지 않은 경우에는 상위 그룹으로부터 타입을 상속받습니다. 이 '타입 상속' 메커니즘은 동일한 타입의 토큰들을 그룹화할 때 반복적인 타입 선언을 줄여주어 토큰 파일을 훨씬 간결하게 만듭니다.10  
* **$description**: 그룹에 대한 설명을 제공합니다. 문서 자동 생성 도구는 이 값을 사용하여 특정 토큰 카테고리(예: 'Brand Colors')에 대한 소개 문단을 생성하는 등 다용도로 활용할 수 있습니다.10

### **3.4 확장성 메커니즘: $extensions**

DTCG 표준은 핵심 명세의 안정성을 유지하면서도 각 도구의 특수한 요구사항을 수용하기 위해 $extensions라는 공식적인 확장 메커니즘을 제공합니다.

* **목적**: $extensions 속성은 특정 도구나 벤더가 표준을 위반하지 않으면서 자신들만의 메타데이터를 토큰 파일 내에 저장할 수 있는 표준화된 공간을 제공합니다.9 예를 들어, Figma 플러그인은 이 공간을 사용하여 Figma 노드 ID나 특정 플러그인 설정을 저장할 수 있습니다.  
* **구조**: $extensions의 값은 객체여야 하며, 이 객체의 키는 다른 벤더와의 충돌을 피하기 위해 고유한 네임스페이스를 사용해야 합니다. 표준은 이를 위해 역방향 도메인 이름 표기법(reverse domain name notation)을 사용할 것을 권장합니다 (예: "com.tokens.studio": {... }).10  
* **규정 준수**: 표준을 준수하는 도구는 자신이 이해하지 못하는 $extensions 데이터를 처리할 때, 해당 데이터를 반드시 보존해야 합니다(MUST). 즉, A라는 도구가 추가한 확장 데이터를 B라는 도구가 파일을 읽고 저장할 때 그대로 유지해야 합니다. 이 규정은 여러 도구를 거치는 워크플로우에서도 정보가 유실되지 않도록 보장하는 중요한 역할을 합니다.10

## **표준 토큰 유형 카탈로그**

DTCG 표준은 디자인 시스템에서 일반적으로 사용되는 다양한 시각적 속성을 표현하기 위해 여러 가지 토큰 유형($type)을 정의합니다. 각 유형은 특정 목적을 가지며, $value에 기대되는 데이터 형식이 정해져 있습니다. 이는 도구가 토큰의 의미를 정확히 파악하고 적절한 코드로 변환하는 데 필수적입니다.

아래 표는 주요 토큰 유형과 그에 대한 설명을 요약한 것입니다.

| $type 값 | 설명 | 기대되는 $value 형식 | 예시 $value |
| :---- | :---- | :---- | :---- |
| color | 단색(solid color) 값을 나타냅니다. | 문자열 (sRGB 16진수 형식, 예: \#RRGGBB). | "\#FF5733" |
| dimension | 거리, 크기 등 측정값을 나타냅니다. | 단위가 포함된 문자열 (예: px, rem, %). | "16px" |
| fontFamily | 글꼴 모음을 나타냅니다. | 문자열 또는 폴백을 위한 문자열 배열. | \["Helvetica", "Arial", "sans-serif"\] |
| fontWeight | 글꼴 두께를 나타냅니다. | 숫자 (1-1000) 또는 표준 문자열 (예: bold). | 700 |
| duration | 시간의 길이를 나타냅니다. (애니메이션 등) | 단위가 포함된 문자열 (예: ms, s). | "250ms" |
| number | 단위가 없는 숫자 값을 나타냅니다. (예: line-height, opacity) | 숫자. | 1.5 |
| cubicBezier | CSS cubic-bezier() 타이밍 함수를 나타냅니다. | 4개의 숫자로 구성된 배열. | \[0.42, 0, 0.58, 1.0\] |
| boolean | 참/거짓 값을 나타냅니다. | 불리언 (true 또는 false). | true |
| link | 에셋(이미지, 아이콘 등)의 경로를 나타냅니다. | 문자열 (URL 또는 상대 경로). | "/assets/icons/heart.svg" |
| typography | 복합적인 텍스트 스타일을 나타냅니다. | fontFamily, fontSize 등을 포함하는 객체. | { "fontSize": "1rem", "fontWeight": 400 } |
| border | 테두리 스타일을 나타냅니다. | color, width, style을 포함하는 객체. | { "color": "\#000000", "width": "1px", "style": "solid" } |
| boxShadow | 그림자 효과를 나타냅니다. | 단일 그림자 객체 또는 여러 그림자 객체의 배열. | { "offsetX": "0px", "offsetY": "4px", "blur": "8px", "color": "\#00000040" } |
| gradient | 그라데이션 색상을 나타냅니다. | 색상 정지점(color stop) 객체들의 배열. | \[{ "color": "\#FF0000", "position": 0 }, { "color": "\#0000FF", "position": 1 }\] |

### **4.1 기본 유형 (Primitive Types)**

기본 유형의 토큰은 $value가 문자열, 숫자, 불리언 등 단일 값으로 표현됩니다.

* **color**: sRGB 색 공간의 16진수 색상 코드를 나타냅니다. 값은 반드시 "\#RRGGBB" 또는 "\#RRGGBBAA" 형식의 문자열이어야 합니다.9  
  JSON  
  {  
    "brand": {  
      "$type": "color",  
      "primary": {  
        "$value": "\#0A74FF",  
        "$description": "The primary brand color for interactive elements."  
      },  
      "secondary": {  
        "$value": "\#FFB800"  
      }  
    }  
  }

* **dimension**: 픽셀(px), rem, 퍼센트(%) 등 단위를 포함하는 측정값을 나타냅니다. 값은 숫자와 단위를 결합한 문자열이어야 합니다.12  
  JSON  
  {  
    "spacing": {  
      "$type": "dimension",  
      "scale": {  
        "100": { "$value": "4px" },  
        "200": { "$value": "8px" },  
        "300": { "$value": "12px" }  
      },  
      "border-radius": {  
        "medium": { "$value": "8px" }  
      }  
    }  
  }

* **fontFamily**: 글꼴 이름을 나타냅니다. 단일 글꼴은 문자열로, 여러 폴백(fallback) 글꼴을 포함할 경우 문자열 배열로 지정합니다.13  
  JSON  
  {  
    "font": {  
      "family": {  
        "body": {  
          "$type": "fontFamily",  
          "$value":  
        },  
        "heading": {  
          "$type": "fontFamily",  
          "$value": "Georgia"  
        }  
      }  
    }  
  }

* **fontWeight**: 글꼴 두께를 나타냅니다. 값은 1에서 1000 사이의 숫자이거나, "normal", "bold"와 같은 CSS 표준 문자열일 수 있습니다. 숫자 값을 사용하는 것이 일반적입니다.13  
  JSON  
  {  
    "font": {  
      "weight": {  
        "$type": "fontWeight",  
        "regular": { "$value": 400 },  
        "bold": { "$value": 700 }  
      }  
    }  
  }

### **4.2 복합 유형 (Composite Types)**

복합 유형의 토큰은 $value가 여러 하위 속성을 포함하는 객체 또는 객체의 배열로 구성됩니다. 이는 CSS의 복잡한 속성들을 하나의 토큰으로 캡슐화하기 위해 사용됩니다.

복합 토큰의 구조는 임의로 정해진 것이 아닙니다. 이는 해당 토큰이 표현하고자 하는 CSS 규칙의 하위 속성들과 일대일로 매핑되도록 신중하게 설계된 스키마입니다. 예를 들어, boxShadow 토큰의 offsetX, offsetY, blur 등의 키는 CSS의 box-shadow 속성을 구성하는 각 부분에 직접 대응합니다.14 이러한 의도적인 설계는 토큰 변환 과정이 예측 가능하고 신뢰할 수 있도록 보장합니다. 변환 도구는 복합 토큰의 값을 어떻게 해석해야 할지 추측할 필요 없이, 정의된 스키마에 따라 각 키를 최종 CSS 출력의 해당 부분에 매핑하기만 하면 됩니다. 이는 디자인 시스템 자동화의 핵심인 결정론적이고 안정적인 변환 프로세스를 가능하게 합니다.

* **typography**: 완전한 텍스트 스타일을 나타내는 복합 토큰입니다. $value는 fontFamily, fontSize, fontWeight, lineHeight, letterSpacing 등 텍스트 스타일을 구성하는 여러 속성을 포함하는 객체입니다.13 이를 통해 단일 토큰으로 전체 타이포그래피 스타일을 적용할 수 있습니다.  
  JSON  
  {  
    "typography": {  
      "heading": {  
        "level-1": {  
          "$type": "typography",  
          "$value": {  
            "fontFamily": "{font.family.heading}",  
            "fontWeight": "{font.weight.bold}",  
            "lineHeight": 1.2,  
            "fontSize": "48px",  
            "letterSpacing": "-0.02em"  
          }  
        }  
      }  
    }  
  }

* **boxShadow**: 그림자 효과를 나타내는 복합 토큰입니다. 단일 그림자는 객체로, 여러 개의 그림자를 중첩할 때는 객체의 배열로 $value를 정의합니다. 각 객체는 offsetX, offsetY, blur, spread, color, 그리고 inset (불리언) 키를 포함할 수 있습니다.14  
  JSON  
  {  
    "shadow": {  
      "elevation": {  
        "medium": {  
          "$type": "boxShadow",  
          "$value":  
        }  
      }  
    }  
  }

* **border**: 테두리 스타일을 나타냅니다. $value는 color, width, style (예: "solid") 속성을 포함하는 객체입니다.13  
  JSON  
  {  
    "border": {  
      "default": {  
        "$type": "border",  
        "$value": {  
          "color": "{color.gray.300}",  
          "width": "{spacing.border-width.default}",  
          "style": "solid"  
        }  
      }  
    }  
  }

## **에일리어스와 테마를 통한 확장 가능한 시스템 구축**

### **5.1 에일리어스(참조) 구문**

에일리어스(Alias)는 하나의 토큰이 다른 토큰의 값을 참조하는 기능으로, 디자인 시스템의 확장성과 유지보수성을 극대화하는 핵심 메커니즘입니다. DTCG 표준에서 에일리어스는 중괄호({})로 감싸인 문자열 값으로 표현됩니다. 이 문자열은 참조하려는 토큰의 전체 경로를 점(.)으로 구분하여 나타냅니다.16

예를 들어, {color.brand.primary.500}라는 값은 color 그룹 아래, brand 그룹 아래, primary 그룹 아래에 있는 500이라는 이름의 토큰 값을 참조하라는 의미입니다.

JSON

{  
  "color": {  
    "brand": {  
      "blue": {  
        "500": {  
          "$type": "color",  
          "$value": "\#0A74FF"  
        }  
      }  
    },  
    "interactive": {  
      "default": {  
        "$type": "color",  
        // 'color.brand.blue.500' 토큰의 값을 참조  
        "$value": "{color.brand.blue.500}"  
      }  
    }  
  }  
}

변환 엔진이 {color.interactive.default} 토큰을 처리할 때, 이 에일리어스를 해석하여 최종적으로 "\#0A74FF"라는 값을 사용하게 됩니다.

### **5.2 추상화의 힘: 계층적 토큰 아키텍처**

에일리어스는 단순한 변수 대체를 넘어, 디자인 시스템을 여러 추상화 계층으로 구조화할 수 있게 해주는 강력한 도구입니다. 잘 설계된 계층적 토큰 아키텍처는 시스템의 일관성을 유지하고, 변경 사항의 영향을 쉽게 예측하며, 새로운 테마나 브랜드를 손쉽게 추가할 수 있도록 만듭니다. 일반적인 계층 구조는 다음과 같습니다.

* **1계층: 전역/핵심 토큰 (Global/Core Tokens)**: 디자인 시스템의 가장 기본적인, 원자적인 값들입니다. 이들은 컨텍스트에 독립적이며, 순수한 값 자체를 나타냅니다 (예: blue.500은 특정 파란색의 16진수 코드).18 이 계층의 토큰들은 일반적으로 에일리어스를 사용하지 않고 실제 값을 직접 가집니다.  
* **2계층: 의미론적/에일리어스 토큰 (Semantic/Alias Tokens)**: 전역 토큰을 참조하여, 그 값에 특정 컨텍스트나 용도를 부여하는 토큰들입니다. 이 계층은 '무엇인가(what it is)'를 '무엇을 위한 것인가(what it's for)'로 번역하는 역할을 합니다.16 예를 들어,  
  color.action.primary (주요 액션 색상)라는 의미론적 토큰은 전역 토큰인 {color.brand.blue.500}을 참조할 수 있습니다.  
* **3계층: 컴포넌트별 토큰 (Component-Specific Tokens)**: 특정 UI 컴포넌트에서만 사용하기 위해 정의된 가장 구체적인 토큰들입니다. 이들은 주로 의미론적 토큰을 참조하여, 해당 컴포넌트의 특정 부분에 어떤 스타일을 적용할지 명시합니다. 예를 들어, button.primary.background.color (기본 버튼의 배경색)는 의미론적 토큰인 {color.action.primary}를 참조할 수 있습니다.

이러한 계층적 구조는 디자인 결정을 체계적으로 관리하고, 변경의 파급 효과를 제어하는 데 매우 효과적입니다. 예를 들어, 브랜드의 기본 파란색을 변경해야 할 경우, 1계층의 color.brand.blue.500 토큰 값만 수정하면, 이를 참조하는 모든 의미론적 토큰과 컴포넌트별 토큰에 변경 사항이 자동으로 전파됩니다.

### **5.3 에일리어스를 활용한 테마 구현**

계층적 토큰 아키텍처는 다크 모드(dark mode), 고대비 모드 등 여러 테마를 효율적으로 구현하는 기반이 됩니다. 테마는 주로 2계층인 의미론적 토큰 수준에서 에일리어스 참조를 변경함으로써 구현됩니다.

예를 들어, 기본(라이트) 테마 파일에서는 다음과 같이 정의할 수 있습니다.

JSON

// tokens/light.json  
{  
  "color": {  
    "background": {  
      "page": { "$value": "{color.global.white}" }  
    },  
    "text": {  
      "default": { "$value": "{color.global.black}" }  
    }  
  }  
}

그리고 다크 테마 파일에서는 동일한 이름의 의미론적 토큰이 다른 전역 토큰을 참조하도록 재정의합니다.

JSON

// tokens/dark.json  
{  
  "color": {  
    "background": {  
      "page": { "$value": "{color.global.black}" }  
    },  
    "text": {  
      "default": { "$value": "{color.global.white}" }  
    }  
  }  
}

컴포넌트들은 항상 {color.background.page}와 같은 의미론적 토큰을 사용하므로, 어떤 테마 파일이 적용되느냐에 따라 실제 값만 바뀌고 컴포넌트 코드는 전혀 수정할 필요가 없습니다. 이는 테마 관리를 매우 단순하고 확장 가능하게 만듭니다.

이러한 에일리어스 시스템은 단순한 참조 관계의 집합이 아니라, 디자인 결정들의 방향성 비순환 그래프(Directed Acyclic Graph, DAG)를 형성합니다. 이 그래프에서 각 토큰은 노드(node)가 되고, 에일리어스는 한 노드에서 다른 노드로 향하는 간선(edge)이 됩니다. 예를 들어, button.background \-\> color.action.primary \-\> color.brand.blue.500과 같은 참조 체인은 그래프 상의 경로를 나타냅니다.

이러한 그래프 구조를 이해하는 것은 디자인 시스템의 복잡성을 관리하는 데 강력한 정신 모델을 제공합니다. 토큰이 자기 자신을 참조하거나 여러 토큰이 서로를 참조하여 순환 구조를 만드는 것이 금지되는 이유가 바로 여기에 있습니다. 순환 참조는 값 해석(resolution) 과정에서 무한 루프를 유발하여 변환 파이프라인을 중단시키기 때문입니다.16 따라서 토큰 시스템은 반드시 '비순환' 그래프여야 합니다.

이 DAG 모델은 또한 고급 도구의 개발 가능성을 열어줍니다. 예를 들어, 특정 전역 토큰(그래프의 루트에 가까운 노드)을 변경했을 때 어떤 컴포넌트들이 영향을 받는지 시각적으로 보여주는 '영향 반경(blast radius)' 분석 도구를 만들 수 있습니다. 이는 디자이너와 개발자가 변경 사항의 파급 효과를 사전에 예측하고, 시스템을 보다 안전하게 유지보수하는 데 큰 도움이 됩니다.

## **전체 구현 예시 및 모범 사례**

### **6.1 종합 tokens.json 예시**

지금까지 논의된 모든 개념—그룹, 기본 및 복합 유형, 계층적 에일리어스, 테마 구현—을 통합한 종합적인 tokens.json 파일 예시는 다음과 같습니다. 이 예시는 작지만 현실적인 디자인 시스템의 구조를 보여줍니다.

JSON

{  
  "global": {  
    "$description": "Core, context-agnostic values for the design system.",  
    "color": {  
      "$type": "color",  
      "blue": {  
        "100": { "$value": "\#E6F1FF" },  
        "500": { "$value": "\#0A74FF" },  
        "900": { "$value": "\#002B61" }  
      },  
      "gray": {  
        "100": { "$value": "\#F5F5F5" },  
        "500": { "$value": "\#808080" },  
        "900": { "$value": "\#1A1A1A" }  
      },  
      "white": { "$value": "\#FFFFFF" },  
      "black": { "$value": "\#000000" }  
    },  
    "font": {  
      "family": {  
        "sans": {  
          "$type": "fontFamily",  
          "$value":  
        }  
      },  
      "weight": {  
        "$type": "fontWeight",  
        "regular": { "$value": 400 },  
        "bold": { "$value": 700 }  
      }  
    },  
    "spacing": {  
      "$type": "dimension",  
      "base": { "$value": "4px" },  
      "xs": { "$value": "{spacing.base}" },      // 4px  
      "s": { "$value": "{spacing.base} \* 2" },   // 8px  
      "m": { "$value": "{spacing.base} \* 4" },   // 16px  
      "l": { "$value": "{spacing.base} \* 6" }    // 24px  
    }  
  },  
  "light": {  
    "$description": "Semantic tokens for the light theme.",  
    "color": {  
      "$type": "color",  
      "background": {  
        "primary": { "$value": "{global.color.white}" },  
        "secondary": { "$value": "{global.color.gray.100}" }  
      },  
      "text": {  
        "primary": { "$value": "{global.color.gray.900}" },  
        "secondary": { "$value": "{global.color.gray.500}" }  
      },  
      "action": {  
        "primary": { "$value": "{global.color.blue.500}" }  
      }  
    }  
  },  
  "dark": {  
    "$description": "Semantic tokens for the dark theme.",  
    "color": {  
      "$type": "color",  
      "background": {  
        "primary": { "$value": "{global.color.gray.900}" },  
        "secondary": { "$value": "{global.color.black}" }  
      },  
      "text": {  
        "primary": { "$value": "{global.color.gray.100}" },  
        "secondary": { "$value": "{global.color.gray.500}" }  
      },  
      "action": {  
        "primary": { "$value": "{global.color.blue.100}" }  
      }  
    }  
  },  
  "component": {  
    "button": {  
      "primary": {  
        "background-color": {  
          "$type": "color",  
          "$value": "{light.color.action.primary}"  
        },  
        "text-color": {  
          "$type": "color",  
          "$value": "{global.color.white}"  
        },  
        "typography": {  
          "$type": "typography",  
          "$value": {  
            "fontFamily": "{global.font.family.sans}",  
            "fontWeight": "{global.font.weight.bold}",  
            "fontSize": "{global.spacing.m}"  
          }  
        },  
        "padding": {  
          "$type": "dimension",  
          "$value": "{global.spacing.m}"  
        }  
      }  
    },  
    "card": {  
      "background-color": {  
        "$type": "color",  
        "$value": "{light.color.background.primary}"  
      },  
      "shadow": {  
        "$type": "boxShadow",  
        "$value": {  
          "offsetX": "0px",  
          "offsetY": "2px",  
          "blur": "4px",  
          "color": "\#00000026"  
        }  
      }  
    }  
  }  
}

### **6.2 구현을 위한 모범 사례**

DTCG 표준을 효과적으로 활용하기 위한 몇 가지 모범 사례는 다음과 같습니다.

* **일관된 이름 지정 규칙**: 예측 가능하고 일관된 토큰 명명 규칙을 수립하는 것이 중요합니다. 일반적으로 \[카테고리\]-\[속성\]-\[변형\]-\[상태\] (예: color-background-primary-hover)와 같은 구조가 권장됩니다. 이는 토큰의 용도를 이름만으로도 쉽게 파악할 수 있게 해줍니다.  
* **파일 분리 및 구성**: 대규모 디자인 시스템에서는 모든 토큰을 단일 파일에 관리하는 것이 비효율적일 수 있습니다. Cobalt와 같은 도구는 여러 토큰 파일을 병합하는 기능을 지원하므로 9,  
  colors.json, typography.json, spacing.json 등 유형별로 파일을 분리하여 관리하는 전략을 고려할 수 있습니다. 이는 가독성과 유지보수성을 향상시킵니다.  
* **적극적인 문서화**: $description 속성을 토큰과 그룹 레벨 모두에서 적극적으로 활용하여 시스템을 자체적으로 문서화해야 합니다. 잘 작성된 설명은 토큰의 의도와 사용법을 명확히 하여, 팀원들이 디자인 시스템을 올바르게 이해하고 사용하는 데 큰 도움이 됩니다.  
* **의미론적 계층 활용**: 컴포넌트별 토큰이 전역 토큰을 직접 참조하는 것을 지양하고, 반드시 의미론적 토큰 계층을 거치도록 설계해야 합니다. 이 추상화 계층은 시스템의 유연성과 확장성을 보장하는 핵심 요소입니다. 의미론적 계층을 건너뛰면 테마 적용이나 대규모 리팩토링 시 어려움을 겪을 수 있습니다.

### **6.3 결론: 상호운용 가능한 디자인 시스템의 미래**

W3C 디자인 토큰 커뮤니티 그룹(DTCG) 표준은 디자인과 개발 간의 워크플로우를 혁신하고, 파편화된 도구 생태계에 질서를 부여하기 위한 중요한 이정표입니다. 이 표준은 명확하고 구조화된 RAW\_JSON 스키마를 제공함으로써, 디자인 시스템의 핵심 가치인 일관성, 확장성, 유지보수성을 기술적으로 뒷받침합니다.

$value를 통한 명확한 토큰 정의, $type을 통한 의미론적 분류, 그리고 에일리어스를 통한 강력한 추상화 계층 구축 기능은 이 표준의 핵심적인 장점입니다. 특히, 에일리어스 시스템이 형성하는 방향성 비순환 그래프(DAG) 구조는 복잡한 디자인 결정들의 관계를 체계적으로 관리하고, 테마와 같은 고차원적인 기능을 손쉽게 구현할 수 있는 이론적 기반을 제공합니다.

결론적으로, DTCG 표준을 채택하는 것은 단순히 파일 형식을 통일하는 것을 넘어, 디자인 시스템을 보다 견고하고, 자동화 친화적이며, 미래 지향적으로 구축하는 전략적인 선택입니다. 이 표준은 앞으로 등장할 다양한 디자인 시스템 도구들이 서로 원활하게 소통하고 협력할 수 있는 안정적인 토대가 되어, 진정으로 상호운용 가능한 디자인 시스템 생태계의 미래를 열어갈 것입니다.

#### **참고 자료**

1. How to extract elements from Figma designs to build a design system? \- Reddit, 8월 2, 2025에 액세스, [https://www.reddit.com/r/DesignSystems/comments/1h7mamv/how\_to\_extract\_elements\_from\_figma\_designs\_to/](https://www.reddit.com/r/DesignSystems/comments/1h7mamv/how_to_extract_elements_from_figma_designs_to/)  
2. We built a free Figma to JSON Exporter plugin : r/FigmaDesign \- Reddit, 8월 2, 2025에 액세스, [https://www.reddit.com/r/FigmaDesign/comments/1m0efwp/we\_built\_a\_free\_figma\_to\_json\_exporter\_plugin/](https://www.reddit.com/r/FigmaDesign/comments/1m0efwp/we_built_a_free_figma_to_json_exporter_plugin/)  
3. Six Figma Plugins to Improve Your Design System Workflows – Blog – Supernova.io, 8월 2, 2025에 액세스, [https://www.supernova.io/blog/six-figma-plugins-to-improve-your-design-system-workflows](https://www.supernova.io/blog/six-figma-plugins-to-improve-your-design-system-workflows)  
4. Design Tokens | Community Groups \- W3C, 8월 2, 2025에 액세스, [https://www.w3.org/groups/cg/design-tokens](https://www.w3.org/groups/cg/design-tokens)  
5. design-tokens/community-group: This is the official DTCG repository for the design tokens specification. \- GitHub, 8월 2, 2025에 액세스, [https://github.com/design-tokens/community-group](https://github.com/design-tokens/community-group)  
6. Token Format \- W3C DTCG vs Legacy \- Tokens Studio for Figma, 8월 2, 2025에 액세스, [https://docs.tokens.studio/manage-settings/token-format](https://docs.tokens.studio/manage-settings/token-format)  
7. Design Tokens Community Group | Style Dictionary, 8월 2, 2025에 액세스, [https://styledictionary.com/info/dtcg/](https://styledictionary.com/info/dtcg/)  
8. Design Tokens Community Group: Home, 8월 2, 2025에 액세스, [https://www.designtokens.org/](https://www.designtokens.org/)  
9. tokens.json Manifest \- Cobalt, 8월 2, 2025에 액세스, [https://cobalt-ui.pages.dev/guides/tokens](https://cobalt-ui.pages.dev/guides/tokens)  
10. Design Tokens Format Module, 8월 2, 2025에 액세스, [https://second-editors-draft.tr.designtokens.org/format/](https://second-editors-draft.tr.designtokens.org/format/)  
11. W3C \- DTCG Specification Alignment \- Tokens Studio, 8월 2, 2025에 액세스, [https://feedback.tokens.studio/p/w3c-dtcg-specification-alignment](https://feedback.tokens.studio/p/w3c-dtcg-specification-alignment)  
12. Design Tokens Community Group | Style Dictionary, 8월 2, 2025에 액세스, [https://styledictionary.com/reference/utils/dtcg/](https://styledictionary.com/reference/utils/dtcg/)  
13. Token types \- Specify Docs, 8월 2, 2025에 액세스, [https://docs.specifyapp.com/v1/concepts/token-types](https://docs.specifyapp.com/v1/concepts/token-types)  
14. Box Shadow \- Composite \- Tokens Studio for Figma, 8월 2, 2025에 액세스, [https://docs.tokens.studio/manage-tokens/token-types/box-shadow](https://docs.tokens.studio/manage-tokens/token-types/box-shadow)  
15. Shadow type feedback · Issue \#100 · design-tokens/community-group \- GitHub, 8월 2, 2025에 액세스, [https://github.com/design-tokens/community-group/issues/100](https://github.com/design-tokens/community-group/issues/100)  
16. Token Values with References | Tokens Studio for Figma, 8월 2, 2025에 액세스, [https://docs.tokens.studio/manage-tokens/token-values/references](https://docs.tokens.studio/manage-tokens/token-values/references)  
17. Design Tokens \- Style Dictionary, 8월 2, 2025에 액세스, [https://styledictionary.com/info/tokens/](https://styledictionary.com/info/tokens/)  
18. Design Tokens: What are global, alias and component tokens — Part 1 \- Medium, 8월 2, 2025에 액세스, [https://medium.com/@yamini1020.yanamala/design-system-what-are-global-alias-and-component-tokens-part-1-78420a5827a1](https://medium.com/@yamini1020.yanamala/design-system-what-are-global-alias-and-component-tokens-part-1-78420a5827a1)