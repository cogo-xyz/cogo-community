# 🔐 분산 Agent 환경에서의 API Key 관리 설계

## 🎯 **설계 목표**

- **중앙화된 Key 관리**: 단일 소스에서 모든 Agent가 Key 조회
- **동적 Key 로테이션**: 무중단 Key 업데이트
- **클라우드 Agnostic**: AWS, Azure, GCP, 개인 PC 모두 지원
- **실시간 동기화**: Supabase Realtime을 통한 즉시 반영
- **보안**: 암호화된 Key 저장 및 전송

---

## 🏗️ **Architecture 1: Supabase 중앙 Key Store**

### **구조**
```
┌─────────────────────────────────────────────────────┐
│                 Supabase Central                     │
│  ┌─────────────────┐    ┌─────────────────────────┐ │
│  │   API Keys      │    │    Realtime Sync        │ │
│  │   (Encrypted)   │◄──►│   Key Updates           │ │
│  └─────────────────┘    └─────────────────────────┘ │
└─────────────────┬───────────────────────────────────┘
                  │
          ┌───────┴───────┐
          │  Key Manager  │ (New Service)
          └───────┬───────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│Agent 1│    │Agent 2│    │Agent 3│
│AWS EC2│    │Azure  │    │개인 PC │
└───────┘    └───────┘    └───────┘
```

### **Key Management Service 구현**

```typescript
// src/services/DistributedKeyManager.ts
export class DistributedKeyManager {
  private keyCache: Map<string, string> = new Map();
  private realtimeClient: SupabaseClient;
  
  async getApiKey(service: 'claude' | 'openai' | 'gemini' | 'fireworks' | 'deepinfra'): Promise<string> {
    // 1. 캐시 확인
    if (this.keyCache.has(service)) {
      return this.keyCache.get(service)!;
    }
    
    // 2. Supabase에서 암호화된 Key 조회
    const encryptedKey = await this.fetchEncryptedKey(service);
    const decryptedKey = await this.decryptKey(encryptedKey);
    
    // 3. 캐시 저장
    this.keyCache.set(service, decryptedKey);
    return decryptedKey;
  }
  
  // Realtime으로 Key 업데이트 수신
  subscribeToKeyUpdates(): void {
    this.realtimeClient
      .channel('api_keys_updates')
      .on('postgres_changes', 
        { event: 'UPDATE', schema: 'public', table: 'api_keys' },
        (payload) => this.handleKeyUpdate(payload)
      );
  }
}
```

---

## 🏗️ **Architecture 2: HashiCorp Vault 방식**

### **구조**
```
┌─────────────────────────────────────────────────────┐
│                HashiCorp Vault                      │
│  ┌─────────────────┐    ┌─────────────────────────┐ │
│  │   KV Secrets    │    │    Dynamic Secrets      │ │
│  │   Engine        │    │    Auto-Rotation        │ │
│  └─────────────────┘    └─────────────────────────┘ │
└─────────────────┬───────────────────────────────────┘
                  │
          ┌───────▼───────┐
          │  Agent Auth   │ (JWT Token)
          └───────┬───────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│Agent 1│    │Agent 2│    │Agent 3│
│각자의  │    │Token  │    │인증   │
│인증    │    │기반   │    │받고   │
└───────┘    └───────┘    └───────┘
```

---

## 🏗️ **Architecture 3: Environment-Based with Git Ops**

### **구조**
```
┌─────────────────────────────────────────────────────┐
│                Git Repository                       │
│  ┌─────────────────┐    ┌─────────────────────────┐ │
│  │   env.secrets   │    │    deployment.yaml      │ │
│  │   (Encrypted)   │    │    (per environment)    │ │
│  └─────────────────┘    └─────────────────────────┘ │
└─────────────────┬───────────────────────────────────┘
                  │
          ┌───────▼───────┐
          │   CI/CD       │ (Auto Deploy)
          └───────┬───────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│Dev    │    │Stage  │    │Prod   │
│환경   │    │환경   │    │환경   │
└───────┘    └───────┘    └───────┘
```

---

## 🎯 **권장: Hybrid 접근법**

### **Phase 1: Supabase 중앙 관리 (즉시 적용)**
```typescript
// 기존 .env 방식을 점진적으로 교체
export class HybridKeyManager {
  async getApiKey(service: string): Promise<string> {
    // 1. 환경변수 우선 (개발용)
    const envKey = process.env[`${service.toUpperCase()}_API_KEY`];
    if (envKey && !envKey.startsWith('placeholder')) {
      return envKey;
    }
    
    // 2. Supabase 중앙 저장소 (프로덕션용)
    return await this.distributedKeyManager.getApiKey(service);
  }
}
```

### **Phase 2: Agent 자동 등록 및 Key 할당**
```typescript
// Agent가 시작할 때 자동으로 Key 권한 요청
export class AgentBootstrap {
  async initialize(): Promise<void> {
    const agentId = this.generateAgentId();
    const keyPermissions = await this.requestKeyPermissions(agentId);
    this.keyManager.setPermissions(keyPermissions);
  }
}
```

---

## 🔧 **구현 계획**

### **Step 1: 현재 상태 유지하면서 기반 구축**
1. `DistributedKeyManager` 서비스 생성
2. Supabase에 `api_keys` 테이블 생성
3. 암호화/복호화 로직 구현

### **Step 2: 점진적 마이그레이션**
1. 개발 환경: 기존 .env 방식 유지
2. 프로덕션 환경: Supabase 중앙 관리로 전환
3. Realtime Key 업데이트 구현

### **Step 3: 고급 기능 추가**
1. Key 로테이션 자동화
2. 사용량 기반 Key 선택
3. 지역별 Key 분산

---

## 💡 **즉시 적용 가능한 개선안**

### **1. Key Validation Service**
```typescript
// 모든 Agent가 시작 시 Key 유효성 검증
export class KeyValidationService {
  async validateAllKeys(): Promise<KeyValidationResult> {
    const results = await Promise.all([
      this.validateClaude(),
      this.validateOpenAI(),
      this.validateGemini(),
      this.validateFireworks(),
      this.validateDeepInfra()
    ]);
    
    return this.aggregateResults(results);
  }
}
```

### **2. Agent Key Registry**
```typescript
// 어떤 Agent가 어떤 Key를 사용하는지 추적
export class AgentKeyRegistry {
  private keyUsage: Map<string, Set<string>> = new Map();
  
  registerKeyUsage(agentId: string, service: string): void {
    // Key 사용량 추적 및 분산
  }
}
```

---

## 🚀 **당장 적용할 수 있는 방법**

현재 상황에서는 **제공해주신 실제 Key들을 설정하되**, 동시에 **분산 Key 관리 기반**을 구축하는 것이 좋겠습니다.

1. **즉시**: 실제 Key로 .env 업데이트  
2. **병렬**: `DistributedKeyManager` 서비스 개발
3. **점진적**: 프로덕션 환경에서 중앙 관리로 전환

어떤 방식으로 진행하시겠습니까?
