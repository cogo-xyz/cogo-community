### **COGO 유니버설 UI 스키마(UUIS) 기술 명세서 (플랫폼 중립 버전)**

이 스키마는 세 가지 계층으로 구성되며, 모든 스타일링은 RAW\_JSON에 정의된 **디자인 토큰**을 참조하는 것을 원칙으로 합니다. JSON 자체에는 \#FFFFFF와 같은 하드코딩된 값이 포함되지 않습니다.

#### **1\. Single Widget JSON (단일 위젯 JSON)**

**목적**: 더 이상 분해할 수 없는 UI의 기본 기능 단위를 정의합니다. 사용자와 직접 상호작용하는 원자적(atomic) 요소입니다.

**플랫폼 중립적 설계 원칙**:

* type은 '버튼', '입력 필드'와 같은 추상적인 개념을 나타냅니다.  
* props는 label, placeholder와 같이 모든 플랫폼에서 공통적으로 이해할 수 있는 속성들로 구성됩니다. 레이아웃과 관련된 속성은 포함하지 않습니다.

**스키마 정의:**

| 속성 | 타입 | 필수 여부 | 설명 |
| :---- | :---- | :---- | :---- |
| id | String | 아니요 | 상태 관리 및 이벤트 타겟팅을 위한 위젯의 고유 식별자입니다. |
| type | String | 예 | 위젯의 의미론적 유형입니다. (예: "cogo:text", "cogo:button", "cogo:textfield", "cogo:image") |
| props | Object | 아니요 | 위젯의 내용과 모양을 정의하는 플랫폼 중립적 속성입니다. (예: label, placeholder, src, variant, size) |
| events | Array\[Object\] | 아니요 | 사용자 상호작용과 그에 따른 시스템의 반응을 정의합니다. |

예제 1-1: 기본 제출 버튼 (Single Widget JSON)  
이 JSON은 "제출이라는 텍스트를 가진 기본 스타일의 버튼"이라는 의도를 표현합니다. React 렌더러는 이를 \<button className="..."\>제출\</button\>으로, Flutter 렌더러는 ElevatedButton(...)으로 변환할 책임이 있습니다.

JSON

{  
  "id": "submit\_button",  
  "type": "cogo:button",  
  "props": {  
    "label": "제출",  
    "variant": "primary"  
  },  
  "events":  
}

예제 1-2: 비밀번호 입력 필드 (Single Widget JSON)  
"비밀번호를 입력받는, '비밀번호'라는 라벨이 붙은 텍스트 필드"를 정의합니다. inputType은 렌더러에게 입력을 마스킹 처리하도록 지시합니다.

JSON

{  
  "id": "password\_input",  
  "type": "cogo:textfield",  
  "props": {  
    "label": "비밀번호",  
    "placeholder": "비밀번호를 입력하세요",  
    "inputType": "password"  
  },  
  "events":  
}

#### **2\. Component JSON (컴포넌트 JSON)**

**목적**: 여러 Single Widget 또는 다른 Component들을 조합하여 하나의 독립된 단위처럼 동작하는 재사용 가능한 복합 UI를 정의합니다. 핵심은 **구조와 레이아웃의 캡슐화**입니다.

**플랫폼 중립적 설계 원칙**:

* type은 일반적인 레이아웃 컨테이너(cogo:stack, cogo:box)이거나, 특정 의미를 가진 복합 컴포넌트(cogo:search-bar)일 수 있습니다.  
* 레이아웃 관련 속성은 CSS Flexbox와 같이 널리 알려진 웹 표준 개념을 차용하여 정의합니다. 이는 Flutter의 Row/Column 위젯으로도 쉽게 매핑될 수 있습니다.1

**스키마 정의:**

| 속성 | 타입 | 필수 여부 | 설명 |
| :---- | :---- | :---- | :---- |
| id | String | 아니요 | 컴포넌트의 고유 식별자입니다. |
| type | String | 예 | 컴포넌트의 의미론적 유형입니다. (예: "cogo:stack", "cogo:card") |
| props | Object | 아니요 | 컴포넌트 자체의 시각적 속성(예: variant) 및 **자식 요소들의 레이아웃**을 정의합니다. |
| children | Array\[Object\] | 아니요 | 이 컴포넌트를 구성하는 자식 요소(Single Widget 또는 다른 Component)들의 배열입니다. |
| events | Array\[Object\] | 아니요 | 컴포넌트 전체에 적용되는 상호작용을 정의합니다. (예: 카드 전체 클릭 이벤트) |

**props.layout 객체 상세 스키마 (컨테이너 타입용):**

| 속성 | 타입 | 설명 | CSS Flexbox 대응 | Flutter 대응 |
| :---- | :---- | :---- | :---- | :---- |
| direction | String | 자식 요소의 정렬 방향. ("horizontal" | "vertical") | flex-direction |
| justifyContent | String | 주축(main axis) 정렬. ("start" | "center" | "end" |
| alignItems | String | 교차축(cross axis) 정렬. ("start" | "center" | "end" |
| padding | String/Object | 내부 여백. (토큰 참조, 예: "medium") | padding | Padding 위젯 |
| gap | String | 자식 요소 간의 간격. (토큰 참조, 예: "small") | gap | SizedBox 등 |

예제 2-1: 사용자 프로필 카드 (Component JSON)  
아바타 이미지와 사용자 이름/이메일 텍스트를 가로로 배치한 카드 컴포넌트입니다.

JSON

{  
  "id": "user\_profile\_card",  
  "type": "cogo:card",  
  "props": {  
    "variant": "elevated",  
    "layout": {  
      "direction": "horizontal",  
      "alignItems": "center",  
      "padding": "medium",  
      "gap": "medium"  
    }  
  },  
  "events":,  
  "children": \[  
    {  
      "id": "user\_avatar",  
      "type": "cogo:image",  
      "props": {  
        "src": "https://example.com/avatar.png",  
        "shape": "circle",  
        "size": "medium"  
      }  
    },  
    {  
      "id": "user\_info\_stack",  
      "type": "cogo:stack",  
      "props": {  
        "layout": {  
          "direction": "vertical",  
          "gap": "x-small"  
        }  
      },  
      "children": \[  
        {  
          "id": "user\_name",  
          "type": "cogo:text",  
          "props": {  
            "content": "COGO 사용자",  
            "style": "heading.h6"  
          }  
        },  
        {  
          "id": "user\_email",  
          "type": "cogo:text",  
          "props": {  
            "content": "user@cogo.ai",  
            "style": "body.small",  
            "color": "text.secondary"  
          }  
        }  
      \]  
    }  
  \]  
}

#### **3\. Page JSON (페이지 JSON)**

**목적**: 애플리케이션의 한 화면 전체를 구성하는 최상위 문서입니다. Single Widget과 Component들을 조합하여 최종 UI 구조를 완성합니다.

**스키마 정의:**

| 속성 | 타입 | 필수 여부 | 설명 |
| :---- | :---- | :---- | :---- |
| schemaVersion | String | 예 | 사용된 UUIS 스키마의 버전입니다. (예: "1.0.0") |
| pageName | String | 예 | 페이지의 이름입니다. (예: "LoginPage") |
| route | String | 예 | 페이지의 경로입니다. (예: "/login") |
| root | Object | 예 | 페이지의 최상위 레이아웃을 정의하는 단일 Component JSON 객체입니다. |

예제 3-1: 회원가입 페이지 (Page JSON)  
위에서 정의한 개념들을 모두 사용하여 완전한 회원가입 페이지를 구성합니다.

JSON

{  
  "schemaVersion": "1.0.0",  
  "pageName": "SignupPage",  
  "route": "/signup",  
  "root": {  
    "id": "signup\_page\_stack",  
    "type": "cogo:stack",  
    "props": {  
      "layout": {  
        "direction": "vertical",  
        "justifyContent": "center",  
        "alignItems": "center",  
        "padding": "large",  
        "gap": "large"  
      }  
    },  
    "children":  
      }  
    \]  
  }  
}

이처럼 플랫폼 중립적으로 재설계된 스키마는 UI의 본질적인 구조와 의미에만 집중합니다. 각 플랫폼(React, Flutter)의 렌더러는 이 공통의 '청사진'을 해석하여 자신의 기술 스택에 맞는 최적의 코드를 생성하는 역할만 수행하면 되므로, 진정한 의미의 '한 번 설계하여 어디서든 렌더링하는(Design Once, Render Anywhere)' 시스템을 구축할 수 있습니다.