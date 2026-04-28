<powershell>
# EC2 User Data Script - Legacy .NET Loan Processing Application
$ErrorActionPreference = "Stop"
$logFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\UserDataExecution.log"
Start-Transcript -Path $logFile -Append
Write-Host "Starting User Data Execution - $(Get-Date)"

try {
    # Install IIS and required features
    Write-Host "Installing IIS..."
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    Install-WindowsFeature -Name Web-Asp-Net45
    Install-WindowsFeature -Name Web-Net-Ext45
    Install-WindowsFeature -Name Web-ISAPI-Ext
    Install-WindowsFeature -Name Web-ISAPI-Filter
    Install-WindowsFeature -Name Web-Mgmt-Console
    Install-WindowsFeature -Name Web-Scripting-Tools

    # Install .NET Framework 4.7.2 if needed
    $netVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
    if ($netVersion.Release -lt 461808) {
        Write-Host "Installing .NET Framework 4.7.2..."
        $netInstallerPath = "C:\Windows\Temp\NDP472-KB4054530-x86-x64-AllOS-ENU.exe"
        Invoke-WebRequest -Uri "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe" -OutFile $netInstallerPath
        Start-Process -FilePath $netInstallerPath -ArgumentList "/q", "/norestart" -Wait
    }

    # Install PowerShell modules
    Write-Host "Installing PowerShell modules..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module SqlServer -Force -AllowClobber -Scope AllUsers
    Install-Module AWS.Tools.Common -Force -AllowClobber -Scope AllUsers
    Install-Module AWS.Tools.SecretsManager -Force -AllowClobber -Scope AllUsers
    Install-Module AWS.Tools.SimpleSystemsManagement -Force -AllowClobber -Scope AllUsers
    Install-Module AWS.Tools.CodePipeline -Force -AllowClobber -Scope AllUsers
    Install-Module AWS.Tools.CodeDeploy -Force -AllowClobber -Scope AllUsers

    # Install CloudWatch Agent
    Write-Host "Installing CloudWatch Agent..."
    $cwAgentPath = "C:\Windows\Temp\amazon-cloudwatch-agent.msi"
    Invoke-WebRequest -Uri "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi" -OutFile $cwAgentPath
    Start-Process msiexec.exe -ArgumentList "/i", $cwAgentPath, "/qn" -Wait

    # Configure CloudWatch Agent
    $cwConfigPath = "C:\ProgramData\Amazon\AmazonCloudWatchAgent\config.json"
    @'
${cloudwatch_config}
'@ | Out-File -FilePath $cwConfigPath -Encoding UTF8
    
    # Start CloudWatch Agent
    try {
        & "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c file:$cwConfigPath
    } catch {
        Write-Host "WARNING: CloudWatch Agent config failed: $_"
    }

    # Install CodeDeploy Agent
    Write-Host "Installing CodeDeploy Agent..."
    $region = "${aws_region}"
    $codeDeployInstallerPath = "C:\Windows\Temp\codedeploy-agent.msi"
    Invoke-WebRequest -Uri "https://aws-codedeploy-$region.s3.$region.amazonaws.com/latest/codedeploy-agent.msi" -OutFile $codeDeployInstallerPath
    Start-Process msiexec.exe -ArgumentList "/i", $codeDeployInstallerPath, "/qn", "/l*v", "C:\Windows\Temp\codedeploy-agent-install.log" -Wait
    
    # Poll for CodeDeploy Agent service
    Write-Host "Waiting for CodeDeploy Agent..."
    $maxAttempts = 30
    $agentRunning = $false
    for ($i = 1; $i -le $maxAttempts; $i++) {
        $svc = Get-Service -Name "codedeployagent" -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Write-Host "CodeDeploy Agent running on attempt $i"
            $agentRunning = $true
            break
        }
        if ($svc -and $svc.Status -ne "Running") {
            Set-Service -Name "codedeployagent" -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name "codedeployagent" -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 5
    }
    if (-not $agentRunning) { Write-Host "Warning: CodeDeploy Agent not running after $maxAttempts attempts" }
    
    # Configure CodeDeploy Agent
    $codeDeployConfigPath = "C:\ProgramData\Amazon\CodeDeploy\conf.onpremises.yml"
    $configDir = Split-Path -Path $codeDeployConfigPath -Parent
    if (!(Test-Path $configDir)) { New-Item -Path $configDir -ItemType Directory -Force | Out-Null }
    "---`nregion: $region" | Out-File -FilePath $codeDeployConfigPath -Encoding UTF8 -Force
    Write-Host "CodeDeploy Agent configured for region: $region, environment: ${environment}"

    # Trigger CodePipeline (wait for CodeDeploy agent to register with ASG deployment group)
    if ($agentRunning) {
        Write-Host "Waiting 60s for CodeDeploy agent to register with deployment group..."
        Start-Sleep -Seconds 60
        Write-Host "Triggering CodePipeline..."
        try {
            Import-Module AWS.Tools.CodePipeline
            Start-CPPipelineExecution -Name "loan-processing-pipeline-${environment}" -Region $region
            Write-Host "CodePipeline triggered successfully"
        } catch {
            Write-Host "WARNING: Failed to trigger CodePipeline: $_"
        }
    } else {
        Write-Host "Skipping pipeline trigger - CodeDeploy Agent not running"
    }

    # Configure IIS site (CodeDeploy will populate the app directory)
    Write-Host "Configuring IIS..."
    $appPath = "C:\inetpub\wwwroot\LoanProcessing"
    New-Item -Path $appPath -ItemType Directory -Force
    Import-Module WebAdministration
    $appPoolName = "LoanProcessingAppPool"
    if (!(Test-Path "IIS:\AppPools\$appPoolName")) {
        New-WebAppPool -Name $appPoolName
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedRuntimeVersion -Value "v4.0"
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name enable32BitAppOnWin64 -Value $false
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name processModel.identityType -Value 2
    }
    if (Test-Path "IIS:\Sites\Default Web Site") { Remove-Website -Name "Default Web Site" }
    $siteName = "LoanProcessing"
    if (!(Test-Path "IIS:\Sites\$siteName")) {
        New-Website -Name $siteName -PhysicalPath $appPath -ApplicationPool $appPoolName -Port 80
    }
    Start-Website -Name $siteName

    # Firewall rules
    New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
    New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

    # System optimization
    Set-TimeZone -Id "UTC"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Value 30
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Value 65534

    Write-Host "User Data Execution Completed - $(Get-Date)"
    
} catch {
    Write-Host "ERROR: User Data Failed: $_"
    Write-Host "Stack: $($_.ScriptStackTrace)"
    throw
} finally {
    Stop-Transcript
}
</powershell>
