# Infrastructure Bootstrap

GCP 공유 네트워크 리소스를 생성하는 Terraform 모듈입니다.

## 생성되는 리소스

| 리소스 | 설명 |
|--------|------|
| APIs | 필요한 GCP API 활성화 |
| VPC | 메인 VPC 네트워크 |
| Subnets | GKE/VM용 메인 서브넷, Cloud Run용 서버리스 서브넷 |
| Private Service Access | CloudSQL 프라이빗 연결용 |
| Firewall Rules | 내부 통신, IAP SSH, Health Check 허용 |

## 아키텍처

```
infra-bootstrap (이 모듈)
    │
    ├── API Enablement
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

1. **GCP 프로젝트**: 수동으로 미리 생성 필요
2. **Terraform Cloud/Scalr**: 워크스페이스 생성
3. **인증**: GCP Service Account JSON 키

### GCP 프로젝트 수동 생성

```bash
# 1. 프로젝트 생성
gcloud projects create YOUR_PROJECT_ID --name="Your Project Name"

# 2. Billing 연결
gcloud billing projects link YOUR_PROJECT_ID --billing-account=BILLING_ACCOUNT_ID

# 3. Cloud Resource Manager API 활성화 (Terraform이 다른 API를 관리하기 위해 필요)
gcloud services enable cloudresourcemanager.googleapis.com --project=YOUR_PROJECT_ID

# 4. Service Account 생성
gcloud iam service-accounts create terraform-cloud \
  --project=YOUR_PROJECT_ID \
  --display-name="Terraform Cloud"

# 5. Owner 권한 부여
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:terraform-cloud@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/owner"

# 6. 키 생성
gcloud iam service-accounts keys create key.json \
  --iam-account=terraform-cloud@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

## Terraform Cloud/Scalr 설정

### 1. 워크스페이스 생성

- Name: `telecom-app-bootstrap`
- VCS: 이 저장소 연결
- Working Directory: `-infra/infra-bootstrap`

### 2. 변수 설정

#### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | string | GCP Project ID (수동 생성한 프로젝트) |

#### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | string | `"telecom-app"` | 리소스 이름 접두사 |
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
| `GOOGLE_CREDENTIALS` | GCP Service Account JSON 키 (Sensitive) |

## Outputs

| Output | Description |
|--------|-------------|
| `project_id` | GCP 프로젝트 ID |
| `region` | GCP 리전 |
| `vpc_id` | VPC ID |
| `vpc_name` | VPC 이름 |
| `vpc_self_link` | VPC Self Link |
| `main_subnet_id` | 메인 서브넷 ID |
| `main_subnet_name` | 메인 서브넷 이름 |
| `main_subnet_self_link` | 메인 서브넷 Self Link |
| `serverless_subnet_id` | 서버리스 서브넷 ID |
| `serverless_subnet_name` | 서버리스 서브넷 이름 |

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

1. **GCP 프로젝트 수동 생성** (위 가이드 참조)
2. **infra-bootstrap** (이 모듈) - API, VPC 설정
3. **infra-application** - GKE, CloudSQL 등
4. **infra-monitor** - (선택) 모니터링 인프라

## 로컬 테스트

```bash
# 초기화 (backend 비활성화)
terraform init -backend=false

# 검증
terraform validate

# 플랜 (실제 배포 전 확인)
terraform plan
```
