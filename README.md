### HTTP での接続

#### クライアント側

```PowerShell
winrm quickconfig
winrm set winrm/config/client '@{TrustedHosts="Computer1,Computer2"}'
```


ファイアウォールの設定もセットで


### HTTPS での接続

参考情報参照。

### 接続確認(SSL)

#### サーバー側

```PowerShell
Enable-PSRemoting -Force
winrm quickconfig
winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="_";CertificateThumbprint="_"}
```

```PowerShell
$hostName="winsrv01.nomupro.com"
$winrmPort = "5986"
$cred = Get-Credential
$soptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
Enter-PSSession -ComputerName $hostName -Port $winrmPort -Credential $cred -SessionOption $soptions -UseSSL
```

### トラブルシューティング

#### `Error: error uploading shell script: http response error: 401 - invalid content type`

- Linux から実行する場合は、サーバー側で Basic 認証を true にする必要あり。参考情報参照。

#### `Error: run command operation returned`

- ユーザー名の始まりが `.\` の様になっているとだめ。

#### `Error: [ERROR][hyperv][read] path argument is required`

- state ファイルを削除すると直ったことがあった。

### 参考情報
- https://qiita.com/kazinoue/items/bdd7b783d6742770b2cc
- https://www.vwnet.jp/Windows/PowerShell/EnableWinRMFromLinux.htm
- https://www.vwnet.jp/Windows/WS16/2017062701/EnterPSSession4WGWS16.htm