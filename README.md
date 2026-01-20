# Infrastructure Bootstrap

GCP 프로젝트 및 공유 네트워크 리소스를 생성하는 Terraform 모듈입니다.

## 생성되는 리소스

| 리소스 | 설명 |
|--------|------|
| GCP Project | 새 프로젝트 생성 및 Billing 연결 |
| APIs | 필요한 GCP API 활성화 |
| VPC | 메인 VPC 네트워크 |
| Subnets | GKE/VM용 메인 서브넷, Cloud Run용 서버리스 서브넷 |
| Private Service Access | CloudSQL 프라이빗 연결용 |
| Firewall Rules | 내부 통신, IAP SSH, Health Check 허용 |

## 아키텍처

```
infra-bootstrap (이 모듈)
    │
    ├── GCP Project
    ├── VPC + Subnets
    └── Firewall Rules
          │
          ▼
    ┌─────────────────┐
    │  Remote State   │ ◄── 다른 모듈에서 참조
    └─────────────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
infra-app   infra-monitor
```

## 사전 요구사항

1. **GCP 권한**: Organization 또는 Folder 수준의 `Project Creator` 역할
2. **Terraform Cloud/Scalr**: 워크스페이스 생성
3. **인증**: GCP Service Account 또는 사용자 인증

## Terraform Cloud/Scalr 설정

### 1. 워크스페이스 생성

- Name: `telecom-app-bootstrap`
- VCS: 이 저장소 연결
- Working Directory: `-infra/infra-bootstrap`

### 2. 변수 설정

#### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `billing_account_id` | string | GCP Billing Account ID (예: `XXXXXX-XXXXXX-XXXXXX`) |

#### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `org_id` | string | `""` | GCP Organization ID (folder_id와 택1) |
| `folder_id` | string | `""` | GCP Folder ID (org_id와 택1) |
| `project_name` | string | `"telecom-app"` | 프로젝트 이름 접두사 |
| `environment` | string | `"dev"` | 환경 (dev/staging/prod) |
| `region` | string | `"asia-northeast3"` | GCP 리전 |
| `main_subnet_cidr` | string | `"10.0.0.0/20"` | 메인 서브넷 CIDR |
| `pods_cidr` | string | `"10.4.0.0/14"` | GKE Pods CIDR |
| `services_cidr` | string | `"10.8.0.0/20"` | GKE Services CIDR |
| `serverless_subnet_cidr` | string | `"10.1.0.0/28"` | 서버리스 서브넷 CIDR |
| `create_state_bucket` | bool | `false` | GCS 상태 버킷 생성 여부 |

### 3. 환경 변수

| Variable | Description |
|----------|-------------|
| `GOOGLE_CREDENTIALS` | GCP Service Account JSON 키 |

## Outputs

| Output | Description |
|--------|-------------|
| `project_id` | 생성된 GCP 프로젝트 ID |
| `project_number` | 생성된 GCP 프로젝트 번호 |
| `vpc_id` | VPC ID |
| `vpc_name` | VPC 이름 |
| `vpc_self_link` | VPC Self Link |
| `main_subnet_id` | 메인 서브넷 ID |
| `main_subnet_name` | 메인 서브넷 이름 |
| `main_subnet_self_link` | 메인 서브넷 Self Link |
| `serverless_subnet_id` | 서버리스 서브넷 ID |
| `serverless_subnet_name` | 서버리스 서브넷 이름 |
| `region` | GCP 리전 |

## 네트워크 구성

```
VPC: telecom-app-vpc
│
├── main-subnet (10.0.0.0/20)
│   ├── GKE Nodes
│   ├── Redis VMs
│   ├── pods (secondary: 10.4.0.0/14)
│   └── services (secondary: 10.8.0.0/20)
│
├── serverless-subnet (10.1.0.0/28)
│   └── Cloud Run VPC Connector
│
└── Private Service Access (10.x.x.x/16)
    └── CloudSQL
```

## 배포 순서

1. **infra-bootstrap** (이 모듈) - 먼저 배포
2. **infra-application** - bootstrap 완료 후 배포
3. **infra-monitor** - (선택) 모니터링 인프라

## 로컬 테스트

```bash
# 초기화 (backend 비활성화)
terraform init -backend=false

# 검증
terraform validate

# 플랜 (실제 배포 전 확인)
terraform plan
```
