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


### HTTPS での実行

##### サーバー側

```PowerShell
Enable-PSRemoting -Force
winrm quickconfig
winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="_";CertificateThumbprint="_"}
```

`CertificateThumbprint` は、`certmgr` や `certutil` を使って取得する。

```PowerShell
$hostName="winsrv01.nomupro.com"
$winrmPort = "5986"
$cred = Get-Credential
$soptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
Enter-PSSession -ComputerName $hostName -Port $winrmPort -Credential $cred -SessionOption $soptions -UseSSL
```

### エラーメッセージ

#### `Error: error uploading shell script: http response error: 401 - invalid content type`

- Linux から実行する場合は、サーバー側で Basic 認証を true にする必要あり。参考情報参照。
- Windows 10 だとうまくいかない可能性あり。

#### `Error: run command operation returned`

- ユーザー名の始まりが `.\` の様になっているとだめ。

#### `Error: [ERROR][hyperv][read] path argument is required`

- state ファイルを削除すると直ったことがあった。

## 参考情報
- https://qiita.com/kazinoue/items/bdd7b783d6742770b2cc
- https://www.vwnet.jp/Windows/PowerShell/EnableWinRMFromLinux.htm
- https://www.vwnet.jp/Windows/WS16/2017062701/EnterPSSession4WGWS16.htm