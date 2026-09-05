# Agent Note: 在 Harness 測試中消費 OpenDesign dsh-runtime profile

Status: proposed

## Problem

OpenDesign(`nexu-io/open-design`)透過 `dsh --profile open-design {--probe|--models|--stdio}` 表面驅動使用者自行安裝的 DeepSeek Harness。profile adapter(`@open-design/dsh-runtime`)由 OpenDesign 擁有與版本化;DeepSeek Harness 僅透過 `cordis.patch.yml` 承載它。Harness 發版可能在不改 OpenDesign wire 契約的情況下改變 profile 載入的套件(agent、session、llm、cmdline),而 OpenDesign 發版也可能獨立演進 wire 契約。目前 Harness 沒有任何測試會以 `open-design` profile 消費建置好的 `open-design-dsh-runtime` tarball,因此任何一方的 drift 都會在使用者執行設計任務、看到 profile 失敗之前保持沉默。

## Proposal

新增一個由 DeepSeek Harness 擁有的小型、無需 key 的消費測試:

- 在 Harness CI(或 release-candidate gate)中,安裝 OpenDesign 產出的 `open-design-dsh-runtime-<v>.tgz` 到暫時的 `open-design` profile,並透過 `dsh --profile open-design --stdio` 重放錄製的 session(probe、models,以及一次最小的 execute-to-result run)。
- golden replay corpus 保持小且隨測試版本化;盡量沿用 repo 既有的無 key recorded-session snapshot 機制。
- 不在此 repo 內 vendor OpenDesign 原始碼,也不複製 protocol schema;schema 的唯一真理仍位於 `open-design/packages/dsh-runtime/docs/`(`protocol.md` + `dsh-stdio-contract.schema.json`)。Harness 測試只消費建置產物。
- 隨測試記錄 OpenDesign–Harness 版本相容矩陣(Harness 版本 x dsh-runtime 版本),讓 mismatch 在 CI 當下就大聲失敗,而不是在使用者機器上才發生。

Scope:本 note 涵蓋 Harness 側的 consumer。OpenDesign 側的契約所有權與其自身 golden tests 不在本範圍,由 OpenDesign 追蹤。

## Alternatives considered

### 從 OpenDesign schema 複製 golden JSON fixtures

拒絕:在此 repo 複製第二份 schema 會與 owner drift,並重新造成契約想消除的落差。若離線單元測試需要 fixture,應在 CI 中從擁有的 schema 產生,而非檢查人工維護的副本。

### 在 Harness CI 執行完整 OpenDesign 設計 run

拒絕:會把 Harness CI 耦合到 OpenDesign 的 daemon、專案 fixtures 與模型可用性。profile boundary 是 Harness 必須遵守的介面;用 recorded replay 測試該介面已足夠且更便宜。

### 沒有 Harness 側測試(維持現狀)

拒絕:OpenDesign wire 契約已經被 Harness 發版消費,缺少 consumer 測試會使整合契約在 host 側無法驗證。

## Acceptance criteria

- CI job(或 release-candidate gate)會將 OpenDesign 建置的 `open-design-dsh-runtime` tarball 安裝到暫時的 `open-design` profile,並在支援的平台上成功重放錄製的 session。
- 相容矩陣已檢查進 repo,任一方版本移動時更新。
- 當 probe identity、models frame 或必要 run frame 偏離 recorded replay 時,測試大聲失敗。

## Risks

- OpenDesign tarball 是外部 build 輸入;job 必須釘住或記錄實際消費的版本,並在無法取得時清楚失敗。
- 兩個 repo 都把 Windows 視為 best-effort;replay 應標記在 Harness 支援的平台上執行,且 Windows-only 失敗不得與 wire drift 混為一談。
- Pre-release churn:兩邊都還在 pre-stable 時,故意的契約變更需要重新產生 replay fixtures;這是捕捉非預期 drift 的代價。
