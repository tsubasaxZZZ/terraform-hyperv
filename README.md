## HTTP での接続

以下 README の通りにセットアップする
- https://github.com/taliesins/terraform-provider-hyperv#setting-up-server-for-provider-usage

### サーバー側

```powershell
Enable-PSRemoting -SkipNetworkProfileCheck -Force

Set-WSManInstance WinRM/Config/WinRS -ValueSet @{MaxMemoryPerShellMB = 1024}
Set-WSManInstance WinRM/Config -ValueSet @{MaxTimeoutms=1800000}
Set-WSManInstance WinRM/Config/Client -ValueSet @{TrustedHosts="*"}
Set-WSManInstance WinRM/Config/Service/Auth -ValueSet @{Negotiate = $true}
```

```powershell
# Get the public networks
$PubNets = Get-NetConnectionProfile -NetworkCategory Public -ErrorAction SilentlyContinue 

# Set the profile to private
foreach ($PubNet in $PubNets) {
    Set-NetConnectionProfile -InterfaceIndex $PubNet.InterfaceIndex -NetworkCategory Private
}

# Configure winrm
Set-WSManInstance WinRM/Config/Service -ValueSet @{AllowUnencrypted = $true}

# Restore network categories
foreach ($PubNet in $PubNets) {
    Set-NetConnectionProfile -InterfaceIndex $PubNet.InterfaceIndex -NetworkCategory Public
}

Get-ChildItem wsman:\localhost\Listener\ | Where-Object -Property Keys -eq 'Transport=HTTP' | Remove-Item -Recurse
New-Item -Path WSMan:\localhost\Listener -Transport HTTP -Address * -Force -Verbose

Restart-Service WinRM -Verbose

New-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Name "WinRMHTTPIn" -Profile Any -LocalPort 5985 -Protocol TCP -Verbose
```

### クライアント側

特に何もしなくてもいけるはず。

## トラシュー用

### デバッグ

`terraform plan` や `terraform apply` を実行すると、ホストに PowerShell スクリプトが転送される。従ってそのスクリプトを見ると何が実行されるかが分かるのでデバッグできる。

スクリプトは、ユーザー名で指定したユーザーの `%localappdata%\temp` にコピーされる。terraform の実行が終了するとすぐに削除されてしまうので、直ぐにコピーする。

### クライアント側

```PowerShell
winrm quickconfig
winrm set winrm/config/client '@{TrustedHosts="Computer1,Computer2"}'
```


ファイアウォールの設定もセットで

### エラーメッセージ

#### `Error: error uploading shell script: http response error: 401 - invalid content type`

- Linux から実行する場合は、サーバー側で Basic 認証を true にする必要あり。参考情報参照。
- Windows 10 だとうまくいかない可能性あり。

#### `Error: run command operation returned`

- ユーザー名の始まりが `.\` の様になっているとだめ。

#### `Error: [ERROR][hyperv][read] path argument is required`

- state ファイルを削除すると直ったことがあった。

#### 何も設定してない場合
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

#### Enable-PSRemoting -SkipNetworkProfileCheck -Force だけを実施

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

#### リモートからの実行

何も設定しない場合(HTTPS接続が前提で、証明書をインポートしていない場合)、リモートクライアントから `terraform apply` を実行すると以下のエラーがでる。
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



## 参考情報
- https://qiita.com/kazinoue/items/bdd7b783d6742770b2cc
- https://www.vwnet.jp/Windows/PowerShell/EnableWinRMFromLinux.htm
- https://www.vwnet.jp/Windows/WS16/2017062701/EnterPSSession4WGWS16.htm