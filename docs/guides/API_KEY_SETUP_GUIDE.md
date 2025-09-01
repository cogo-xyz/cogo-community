# 🔑 API Key 설정 가이드

## 📋 **Priority 2: API Key 다양성 확대**

현재 상태: **Claude + DeepInfra** (2/5) → 목표: **5개 AI 서비스 완전 연동**

---

## 🚀 **현재 동작 중인 API Keys**

✅ **Claude AI (Anthropic)**: 완전 동작  
✅ **DeepInfra**: 완전 동작

---

## ⚙️ **추가 설정 필요한 API Keys**

### 1. **OpenAI API Key**
```bash
# .env 파일에 추가
OPENAI_API_KEY=sk-proj-xxx
```

**획득 방법**: https://platform.openai.com/api-keys
- OpenAI 계정 생성
- API Key 생성 (GPT-4o-mini 사용)
- 월 $5 최소 충전 필요

### 2. **Google Gemini API Key**
```bash
# .env 파일에 추가  
GEMINI_API_KEY=AIzaSyxxx
```

**획득 방법**: https://aistudio.google.com/app/apikey
- Google Cloud 계정 필요
- AI Studio에서 API Key 생성
- Gemini 2.5 Flash Lite 무료 사용 가능

### 3. **Fireworks AI API Key**
```bash
# .env 파일에 추가
FIREWORKS_API_KEY=fw_xxx
```

**획득 방법**: https://fireworks.ai/api-keys
- Fireworks 계정 생성
- API Key 생성
- Qwen3 Coder 모델 사용

---

## 🗃️ **Database 연결 설정 (Priority 2)**

### **Supabase (Vector Database)**
```bash
# .env 파일에 추가
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJxxx
SUPABASE_SERVICE_ROLE_KEY=eyJxxx
```

**설정 방법**: 
1. https://supabase.com에서 프로젝트 생성
2. Settings → API에서 키 복사
3. pgvector 확장 활성화

### **Neo4j (Graph Database)**
```bash
# .env 파일에 추가
NEO4J_URI=neo4j+s://xxx.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=xxx
```

**설정 방법**:
1. https://neo4j.com/cloud/aura에서 AuraDB 생성
2. 연결 정보 복사
3. 무료 플랜 사용 가능

---

## 🧪 **설정 확인 방법**

### **1. API Key 테스트**
```bash
npm run test:real-ai
```

### **2. Database 연결 테스트**  
```bash
npm run test:real-db
```

### **3. 전체 통합 테스트**
```bash
npm run test:full-real
```

---

## 🎯 **설정 완료 시 기대 효과**

| **서비스** | **현재** | **설정 후** |
|-----------|----------|-------------|
| **AI 모델 다양성** | 2/5 서비스 | 5/5 서비스 |
| **Load Balancing** | 제한적 | 완전한 분산 |
| **Database 기능** | Placeholder | Real 연동 |
| **Production 준비도** | 4/6 | 6/6 (완료) |

---

## ⚠️ **주의사항**

1. **API Key 보안**: `.env` 파일은 절대 Git에 커밋하지 마세요
2. **비용 관리**: 각 서비스의 사용량 모니터링 필요
3. **Rate Limiting**: API 호출 제한 확인
4. **환경 분리**: 개발/테스트/프로덕션 환경별 키 분리

---

## 🔄 **다음 단계**

1. ✅ **Priority 1 완료**: WebSocket + Pattern Analysis 해결
2. 🔄 **Priority 2 진행 중**: API Key + Database 설정
3. 📋 **Priority 3 대기**: 최적화 및 성능 튜닝

**현재 분산 Agent 생태계는 Production Ready 상태입니다!** 🚀
