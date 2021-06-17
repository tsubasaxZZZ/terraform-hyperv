### 接続確認

```PowerShell
$hostName="winsrv01.nomupro.com"
$winrmPort = "5986"
$cred = Get-Credential
$soptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
Enter-PSSession -ComputerName $hostName -Port $winrmPort -Credential $cred -SessionOption $soptions -UseSSL
```

### 参考情報
- https://qiita.com/kazinoue/items/bdd7b783d6742770b2cc