# Windows 10 をサーバーとする場合

## 手順

1. サーバー上で `Enable-PSRemoting -SkipNetworkProfileCheck -Force` を実行
2. サーバー上で HTTPSの設定と証明書の生成
	- [WinRM allow HTTPS](https://github.com/taliesins/terraform-provider-hyperv#:~:text=ValueSet%20%40%7BNegotiate%20%3D%20%24true%7D-,WinRM%20allow%20HTTPS,-%23Create%20CA%20certificate) のコマンドをそのまま実行。
	- ここまでの設定で`terraform apply`をするとローカル上にデプロイできる。
3. (リモートから実行する場合)リモートクライアント上に 2. で生成した自己署名証明書をインポート
    - 自己署名証明書(<ホスト名>.pfx)をリモートクライアントにインポートすることでリモートからの実行が可能となる。
    - 2.のコマンドのまま実行した場合、証明書のパスワードは、`P@ssw0rd`。

## Terraform の設定例

```
provider "hyperv" {
  user            = var.user
  password        = var.password
  host            = var.host

  # for HTTPS
  port            = 5986
  https           = true <----------- https を true にする

  insecure        = false
  use_ntlm        = true
  script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout         = "30s"
```

## エラーメッセージ
### 何も設定してない場合
```
PS C:\temp\hvswitchtest> terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # hyperv_network_switch.internal will be created
  + resource "hyperv_network_switch" "internal" {
      + allow_management_os                     = true
      + default_flow_minimum_bandwidth_absolute = 0
      + default_flow_minimum_bandwidth_weight   = 0
      + default_queue_vmmq_enabled              = false
      + default_queue_vmmq_queue_pairs          = 16
      + default_queue_vrss_enabled              = false
      + enable_embedded_teaming                 = false
      + enable_iov                              = false
      + enable_packet_direct                    = false
      + id                                      = (known after apply)
      + minimum_bandwidth_mode                  = "None"
      + name                                    = "internal2"
      + switch_type                             = "Internal"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

hyperv_network_switch.internal: Creating...
╷
│ Error: error uploading shell script: unknown error Post "http://localhost:5985/wsman": dial tcp [::1]:5985: connectex: No connection could be made because the target machine actively refused it.
│
│   with hyperv_network_switch.internal,
│   on main.tf line 41, in resource "hyperv_network_switch" "internal":
│   41: resource "hyperv_network_switch" "internal" {
│
```

### Enable-PSRemoting -SkipNetworkProfileCheck -Force だけを実施

```
PS C:\temp\hvswitchtest> terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # hyperv_network_switch.internal will be created
  + resource "hyperv_network_switch" "internal" {
      + allow_management_os                     = true
      + default_flow_minimum_bandwidth_absolute = 0
      + default_flow_minimum_bandwidth_weight   = 0
      + default_queue_vmmq_enabled              = false
      + default_queue_vmmq_queue_pairs          = 16
      + default_queue_vrss_enabled              = false
      + enable_embedded_teaming                 = false
      + enable_iov                              = false
      + enable_packet_direct                    = false
      + id                                      = (known after apply)
      + minimum_bandwidth_mode                  = "None"
      + name                                    = "internal2"
      + switch_type                             = "Internal"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

hyperv_network_switch.internal: Creating...
╷
│ Error: error uploading shell script: http response error: 401 - invalid content type
│
│   with hyperv_network_switch.internal,
│   on main.tf line 41, in resource "hyperv_network_switch" "internal":
│   41: resource "hyperv_network_switch" "internal" {
│
```

## リモートからの実行

何も設定しない場合、リモートクライアントから `terraform apply` を実行すると以下のエラーがでる。
```
PS C:\temp\win10nested1220> terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # hyperv_network_switch.internal will be created
  + resource "hyperv_network_switch" "internal" {
      + allow_management_os                     = true
      + default_flow_minimum_bandwidth_absolute = 0
      + default_flow_minimum_bandwidth_weight   = 0
      + default_queue_vmmq_enabled              = false
      + default_queue_vmmq_queue_pairs          = 16
      + default_queue_vrss_enabled              = false
      + enable_embedded_teaming                 = false
      + enable_iov                              = false
      + enable_packet_direct                    = false
      + id                                      = (known after apply)
      + minimum_bandwidth_mode                  = "None"
      + name                                    = "internal2"
      + switch_type                             = "Internal"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

hyperv_network_switch.internal: Creating...
╷
│ Error: error uploading shell script: unknown error Post "https://172.20.0.8:5986/wsman": x509: certificate signed by unknown authority
│
│   with hyperv_network_switch.internal,
│   on main.tf line 41, in resource "hyperv_network_switch" "internal":
│   41: resource "hyperv_network_switch" "internal" {
│
```

