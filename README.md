# terraform-infrastructure

Infraestrutura como código (Terraform) para uma plataforma de dados AWS,
com arquitetura de **Data Mesh**: cada domínio/setor tem seu próprio Data
Lake (Bronze/Silver/Gold), governança de acesso e workspace isolado no
Athena. Pensada para ser **genérica e reutilizável entre clientes**.

## Arquitetura

```
modules/
├── s3_lake_layers/       # Buckets Bronze/Silver/Gold + lifecycle (FinOps)
├── domain_iam/           # Governança: owner, analyst, pipeline roles
├── athena_workspaces/    # Workspace isolado por usuário + query logging
├── kinesis_stream/       # Stream de eventos para o pipeline online
├── dynamodb_online/      # Tabela consolidada (carga batch + online)
├── audit_logging/        # Bucket central de auditoria (logs em S3)
└── workspace_cleanup/    # Lambda de expurgo de workspaces inativos

environments/
└── poc/                  # Ambiente de baixa volumetria (1 domínio de exemplo)
```

## Governança de acesso (resumo)

- Usuários **não podem inserir/alterar dados manualmente** — apenas a role
  `pipeline` (usada por Glue/Lambda) tem permissão de escrita.
- Cada usuário tem um **workspace isolado no Athena** para consultar dados.
- Acesso é **SELECT apenas no próprio domínio** por padrão.
- Acesso cruzado entre domínios é solicitado e aprovado manualmente pelo
  owner (v1) — arquivos de solicitação ficam em
  `s3://data-platform-access-requests-{env}/`.
- Todo o histórico de queries e solicitações fica auditado em
  `s3://data-platform-audit-logs-{env}/`.

## FinOps

- Lifecycle policies movem dados automaticamente entre storage classes
  conforme a idade (Bronze até Deep Archive, Silver até Glacier, Gold até
  Intelligent Tiering).
- Workspaces do Athena sem acesso por 90 dias são arquivados; sem acesso
  por 180 dias são deletados (Lambda `workspace_cleanup`, roda todo dia às 2h).
- DynamoDB em `PAY_PER_REQUEST` no POC (troca fácil pra `PROVISIONED`
  quando o tráfego virar previsível).
- Sem CloudWatch Logs — logs de pipeline e auditoria vão direto pro S3.

## Como usar

1. Copie `environments/poc/terraform.tfvars.example` para
   `environments/poc/terraform.tfvars` e ajuste os valores.
2. (Opcional, recomendado) Configure um backend S3 remoto em
   `environments/poc/providers.tf`.
3. Localmente:
   ```bash
   cd environments/poc
   terraform init
   terraform plan
   terraform apply
   ```

## Deploy automático (CI/CD)

O workflow `.github/workflows/deploy-terraform.yml` roda automaticamente:
- Em Pull Requests: `terraform plan` e comenta o resultado no PR.
- Em push para `main`: `terraform plan` + `terraform apply`.

Requer os secrets `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`
configurados em **Settings → Secrets and variables → Actions**.

## Multi-domínio / multi-cliente

Para adicionar um novo domínio, duplique `environments/poc/` (ex:
`environments/orders/`) e ajuste apenas as variáveis — os módulos são
genéricos e reutilizáveis entre domínios e entre clientes.
