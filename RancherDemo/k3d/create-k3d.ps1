Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-ExeValid {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $buf = New-Object byte[] 2
            $null = $fs.Read($buf, 0, 2)
            return ($buf[0] -eq 0x4D -and $buf[1] -eq 0x5A) # 'MZ'
        } finally { $fs.Dispose() }
    } catch { return $false }
}

function DownloadWithFallback {
    param(
        [string]$Url,
        [string]$Dest
    )
    Write-Host "Downloading from: $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -Headers @{ 'Accept'='application/octet-stream' } -UseBasicParsing
    } catch {
        Write-Warning "Invoke-WebRequest failed. Trying curl.exe..."
        & curl.exe -L "$Url" -o "$Dest"
    }
}

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $ScriptDir 'bin'
$KubeconfigDir = Join-Path $ScriptDir 'kubeconfig'
$K3dConfig = Join-Path $ScriptDir 'k3d-config.yaml'
$KubeconfigOut = Join-Path $KubeconfigDir 'kubeconfig.yaml'

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $KubeconfigDir | Out-Null

# k3d
$k3dExe = Join-Path $BinDir 'k3d.exe'
if (-not (Test-ExeValid $k3dExe)) {
    $k3dUrlPinned = 'https://github.com/k3d-io/k3d/releases/download/v5.6.3/k3d-windows-amd64.exe'
    $k3dUrlLatest = 'https://github.com/k3d-io/k3d/releases/latest/download/k3d-windows-amd64.exe'
    Write-Host "Downloading k3d..."
    DownloadWithFallback -Url $k3dUrlPinned -Dest $k3dExe
    if (-not (Test-ExeValid $k3dExe)) {
        Write-Warning "Pinned k3d download invalid, trying latest..."
        DownloadWithFallback -Url $k3dUrlLatest -Dest $k3dExe
    }
    if (-not (Test-ExeValid $k3dExe)) {
        throw "k3d.exe 下載失敗或檔案無效，請檢查網路或稍後再試。"
    }
    Unblock-File -Path $k3dExe -ErrorAction SilentlyContinue
}

# kubectl
$kubectlExe = Join-Path $BinDir 'kubectl.exe'
if (-not (Test-ExeValid $kubectlExe)) {
    Write-Host "Resolving kubectl latest version..."
    $kubectlVersion = (Invoke-WebRequest -Uri 'https://dl.k8s.io/release/stable.txt' -UseBasicParsing).Content.Trim()
    $kubectlDownload = "https://dl.k8s.io/release/$kubectlVersion/bin/windows/amd64/kubectl.exe"
    Write-Host "Downloading kubectl $kubectlVersion..."
    DownloadWithFallback -Url $kubectlDownload -Dest $kubectlExe
    if (-not (Test-ExeValid $kubectlExe)) {
        throw "kubectl.exe 下載失敗或檔案無效，請檢查網路或稍後再試。"
    }
    Unblock-File -Path $kubectlExe -ErrorAction SilentlyContinue
}

# PATH (current session)
$env:PATH = "$BinDir;$env:PATH"

# k3d sanity check
& $k3dExe version

# Create cluster if not exists
Write-Host "Creating k3d cluster 'my-rancher-cluster' (if missing)..."
$existing = (& $k3dExe cluster list) | Out-String
if ($existing -notmatch 'my-rancher-cluster') {
    if (Test-Path $K3dConfig) {
        & $k3dExe cluster create my-rancher-cluster --config $K3dConfig
    } else {
        & $k3dExe cluster create my-rancher-cluster
    }
} else {
    Write-Host "Cluster already exists, skipping creation."
}

# Write kubeconfig
Write-Host "Writing kubeconfig to $KubeconfigOut ..."
& $k3dExe kubeconfig write my-rancher-cluster --output $KubeconfigOut
Write-Host "KUBECONFIG: $KubeconfigOut"

# Validate cluster
Write-Host "Validating cluster with kubectl..."
& $kubectlExe --kubeconfig $KubeconfigOut version --short
& $kubectlExe --kubeconfig $KubeconfigOut cluster-info
& $kubectlExe --kubeconfig $KubeconfigOut get nodes -o wide

Write-Host "Done. Next steps:"
Write-Host "1) 開啟瀏覽器至 https://localhost:18443 (初始密碼 admin)"
Write-Host "2) 在 Rancher > Cluster Management > Create/Import > Import a cluster"
Write-Host "3) 複製 Rancher 提供的 kubectl apply 註冊指令，在此叢集執行："
Write-Host "   kubectl --kubeconfig `"$KubeconfigOut`" apply -f <Rancher 給你的 URL>"

