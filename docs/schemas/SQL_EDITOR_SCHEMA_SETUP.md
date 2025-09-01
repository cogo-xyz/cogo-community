# 🏗️ SQL Editor를 통한 분산 Agent 에코시스템 스키마 설정

## 📋 **개요**

기존 마이그레이션 파일들의 복잡한 의존성과 오류를 피하고, **Supabase SQL Editor에서 직접 분산 Agent 에코시스템 스키마를 설정**하는 방법입니다.

## 🚀 **설정 단계**

### **Step 1: Supabase 대시보드 접속**

1. **Supabase Dashboard** 접속
2. **SQL Editor** 메뉴 클릭
3. **New Query** 버튼 클릭

### **Step 2: 분산 스키마 실행**

1. `sql-editor-distributed-schema.sql` 파일 열기
2. **전체 내용 복사**
3. **SQL Editor에 붙여넣기**
4. **RUN** 버튼 클릭

### **Step 3: 실행 결과 확인**

성공적으로 실행되면 다음과 같은 메시지들이 나타납니다:

```sql
✅ Distributed Agent Ecosystem Schema successfully created!
🚀 Self-upgrading agent infrastructure ready
📊 Tables: agent_registry, agent_hierarchy, agent_versions, realtime_channels, distributed_tasks, agent_communication_logs, agent_performance_history
⚡ Indexes: 15+ performance indexes created
📡 Channels: 8 default realtime channels configured
📦 Versions: 5 initial agent versions added
```

### **Step 4: 스키마 백업**

```bash
# 설정된 스키마를 로컬에 백업
npm run schema:backup
```

## 📊 **생성되는 테이블 구조**

### **1. Agent Registry (`agent_registry`)**
- **목적**: 모든 Agent의 중앙 등록소
- **키 필드**: `agent_id`, `agent_type`, `agent_class`, `status`
- **특징**: 자가 등록, 버전 관리, 성능 메트릭

### **2. Agent Hierarchy (`agent_hierarchy`)**
- **목적**: Parent-Child Agent 관계 관리
- **키 필드**: `parent_agent_id`, `child_agent_id`, `communication_protocol`
- **특징**: 통신 프로토콜별 설정, 연결 상태 추적

### **3. Agent Versions (`agent_versions`)**
- **목적**: Agent 버전 및 자동 업그레이드 관리
- **키 필드**: `agent_class`, `version`, `release_type`
- **특징**: 호환성 체크, 배포 전략, 롤백 지원

### **4. Realtime Channels (`realtime_channels`)**
- **목적**: Supabase Realtime 채널 관리
- **키 필드**: `channel_name`, `channel_type`
- **특징**: 접근 제어, 사용량 통계

### **5. Distributed Tasks (`distributed_tasks`)**
- **목적**: 분산 환경에서 Task 관리
- **키 필드**: `task_id`, `assigned_to_agent_id`, `status`
- **특징**: 위임 전략, 의존성 관리, 실행 추적

### **6. Communication Logs (`agent_communication_logs`)**
- **목적**: Agent 간 통신 추적 및 감사
- **키 필드**: `from_agent_id`, `to_agent_id`, `protocol`
- **특징**: 완전한 감사 추적, 성능 분석

### **7. Performance History (`agent_performance_history`)**
- **목적**: Agent 성능 이력 관리
- **키 필드**: `agent_id`, `recorded_at`
- **특징**: 시계열 성능 데이터, 모니터링 지원

## 🔧 **기본 설정값**

### **Realtime Channels**
- `agents.discovery` - Agent 자가 등록 및 발견
- `agents.heartbeat` - Agent 헬스체크 및 모니터링
- `tasks.distribution` - Task 할당 및 배포
- `system.health` - 시스템 전체 상태 모니터링
- `agents.orchestrator` - Orchestrator Agent 전용
- `agents.executor` - Executor Agent 전용
- `agents.indexing` - Indexing Agent 전용
- `agents.research` - Research Agent 전용

### **Agent Versions**
- `test-system v1.0.0` - Test System Agent
- `orchestrator v2.1.0` - Orchestrator Parent Unit
- `executor v1.8.3` - Executor Child Unit
- `indexing v1.7.1` - Indexing Child Unit
- `research v1.9.0` - Research Child Unit

## 📦 **백업 및 복원**

### **백업 생성**
```bash
npm run schema:backup
```

### **백업 파일 위치**
```
backups/schema/
├── distributed_schema_backup_YYYYMMDD_HHMMSS.sql
└── latest_schema_backup.sql -> (최신 백업 링크)
```

### **복원 방법**
1. 백업된 SQL 파일을 SQL Editor에서 실행
2. 또는 `npx supabase db reset` 후 백업 파일 적용

## 🔍 **검증 방법**

### **테이블 생성 확인**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%agent%'
ORDER BY table_name;
```

### **초기 데이터 확인**
```sql
-- Realtime Channels 확인
SELECT channel_name, channel_type 
FROM realtime_channels 
ORDER BY channel_name;

-- Agent Versions 확인
SELECT agent_class, version, release_type 
FROM agent_versions 
ORDER BY agent_class;
```

## 🚨 **주의사항**

1. **기존 데이터 백업**: 스키마 적용 전 기존 데이터 백업 권장
2. **권한 확인**: SQL Editor 실행 권한 확인
3. **종속성**: `uuid-ossp`, `vector`, `pg_trgm` 확장 필요
4. **네이밍**: 기존 테이블과 이름 충돌 시 수정 필요

## 🎯 **다음 단계**

1. ✅ **스키마 설정 완료**
2. 🔄 **Mock 데이터베이스와 호환성 검증**
3. 🚀 **실제 Agent들을 새 스키마에 연결**
4. 🧪 **분산 기능 테스트**

---

## 📞 **문제 해결**

### **일반적인 오류**

**Q**: Extension 오류가 발생하는 경우?
**A**: Supabase 대시보드 → Settings → Extensions에서 필요한 확장 활성화

**Q**: 권한 오류가 발생하는 경우?
**A**: 프로젝트 Owner 권한 확인 또는 관리자에게 문의

**Q**: 테이블이 생성되지 않는 경우?
**A**: SQL Editor에서 각 섹션별로 나누어 실행해보기

### **백업 복원 실패**

**Q**: 백업 스크립트가 실행되지 않는 경우?
**A**: `chmod +x scripts/backup-schema-from-supabase.sh` 실행 후 재시도

**Q**: Supabase가 실행되지 않는 경우?
**A**: `npx supabase start` 실행 후 백업 재시도
