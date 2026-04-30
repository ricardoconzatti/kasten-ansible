param(
    [string]$labId
)

$ErrorActionPreference = "Stop"

# === LOCK CONFIG ===
$LockDir = "/home/conza/scripts/ip-locks"

if (-not (Test-Path $LockDir)) {
    New-Item -ItemType Directory -Path $LockDir | Out-Null
}

$SelectedIP = $null
$LockFile = $null

try {

    # Disable PowerCLI warnings
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null

    # === CONFIG ===
    $vCenter = "vcenter.caverna.local"
    #$vcUser = "no"
    #$vcPass = "no"

    $TemplateVM = "Ubuntu 24.04"
    $SnapshotName = "snapshot-linked"
    $Datastore = "NUC01_GOLD_DS_01"
    $VMHost = "esxi-nuc01.caverna.local"
    $Folder = "Lab"
    $CustomizationSpecName = "Ubuntu IP VLAN 10"

    $BaseIP = "192.168.10."
    $NumCPU = 2
    $MemoryGB = 6

    # === CONNECT ===
    Connect-VIServer -Server $vCenter #-User $vcUser -Password $vcPass | Out-Null

    # === VALIDATE SOURCE ===
    $SourceVM = Get-VM -Name $TemplateVM
    if (-not $SourceVM) {
        throw "Template VM not found"
    }

    $Snapshot = Get-Snapshot -VM $SourceVM -Name $SnapshotName
    if (-not $Snapshot) {
        throw "Snapshot not found"
    }

    # === FIND AVAILABLE IP WITH LOCK ===
    for ($i = 151; $i -le 159; $i++) {
        $ip = "$BaseIP$i"
        $lockPath = "$LockDir/$ip.lock"

        try {
            $fs = [System.IO.File]::Open($lockPath, 'CreateNew', 'Write', 'None')
            $fs.Close()

            if (-not (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
                $SelectedIP = $ip
                $LockFile = $lockPath
                break
            }
            else {
                # IP já responde → libera lock
                Remove-Item $lockPath -ErrorAction SilentlyContinue
            }
        }
        catch {
            continue
        }
    }

    if (-not $SelectedIP) {
        throw "No available IP found in range 151-159"
    }

    # === VM NAME ===
    if (-not $labId) {
        throw "labId parameter is required"
    }

    $VMName = "kasten-lab-$labId"

    # === TEMP SPEC ===
    $TempSpecName = "temp-$VMName"

    Get-OSCustomizationSpec -Name $TempSpecName -ErrorAction SilentlyContinue | `
        Remove-OSCustomizationSpec -Confirm:$false | Out-Null

    $BaseSpec = Get-OSCustomizationSpec -Name $CustomizationSpecName
    if (-not $BaseSpec) {
        throw "Base customization spec not found"
    }

    $Spec = New-OSCustomizationSpec -Spec $BaseSpec -Name $TempSpecName -Type NonPersistent

    if (-not $Spec) {
        throw "Failed to create temporary customization spec"
    }

    Get-OSCustomizationNicMapping -OSCustomizationSpec $Spec | `
        Set-OSCustomizationNicMapping `
            -IpMode UseStaticIP `
            -IpAddress $SelectedIP `
            -SubnetMask "255.255.255.0" `
            -DefaultGateway "192.168.10.250" | Out-Null

    # === CREATE VM ===
    New-VM `
        -Name $VMName `
        -VM $SourceVM `
        -LinkedClone `
        -ReferenceSnapshot $Snapshot `
        -VMHost $VMHost `
        -Datastore $Datastore `
        -Location $Folder `
        -OSCustomizationSpec $TempSpecName | Out-Null

    Start-Sleep -Seconds 5

    $vm = Get-VM -Name $VMName
    if (-not $vm) {
        throw "VM creation failed"
    }

    # === SET CPU / RAM ===
    Set-VM -VM $vm -NumCpu $NumCPU -MemoryGB $MemoryGB -Confirm:$false | Out-Null

    # === POWER ON ===
    Start-VM -VM $vm | Out-Null

    Start-Sleep -Seconds 5

    $vmCheck = Get-VM -Name $VMName
    if ($vmCheck.PowerState -ne "PoweredOn") {
        throw "VM failed to power on"
    }

    # === SUCCESS OUTPUT ===
    $result = @{
        status  = "success"
        vm_name = $VMName
        ip      = $SelectedIP
    }

}
catch {
    $result = @{
        status  = "error"
        message = $_.Exception.Message
    }
}
finally {
    if ($result.status -ne "success" -and $LockFile) {
        Remove-Item $LockFile -ErrorAction SilentlyContinue
    }
}

# === FINAL OUTPUT ===
$result | ConvertTo-Json -Depth 5
