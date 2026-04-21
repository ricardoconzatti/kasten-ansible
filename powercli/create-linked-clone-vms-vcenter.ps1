# === CONFIG ===
$vCenter = "vcenter.caverna.local"
#$vcUser = "conza@caverna.local"
#$vcPass = "no"

$TemplateVM = "Ubuntu 24.04"
$SnapshotName = "snapshot-linked"
$Datastore = "NUC01_GOLD_DS_01"
$VMHost = "esxi-nuc01.caverna.local"
$Folder = "Lab"
$CustomizationSpecName = "Ubuntu IP VLAN 10"

# VM config
$BaseVMName = "kub-lab"
$BaseIP = "192.168.10."
$StartIP = 150
$NumCPU = 2
$MemoryGB = 6

# Lab duration (in minutes)
$LabDurationMinutes = 120

# === CONNECT ===
Connect-VIServer -Server $vCenter #-User $vcUser -Password $vcPass

# === INPUT ===
$Qtd = Read-Host "How many VMs do you want to create?"

# === GET SOURCE OBJECTS ===
$SourceVM = Get-VM -Name $TemplateVM
$Snapshot = Get-Snapshot -VM $SourceVM -Name $SnapshotName

# Store created VMs
$CreatedVMs = @()

# === LOOP ===
for ($i = 1; $i -le $Qtd; $i++) {

    $Index = "{0:D3}" -f $i
    $VMName = "$BaseVMName-$Index"
    $IP = $BaseIP + ($StartIP + $i)

    Write-Host "Creating VM: $VMName with IP $IP" -ForegroundColor Green

    # Temporary customization spec
    $TempSpecName = "temp-$VMName"

    Get-OSCustomizationSpec -Name $TempSpecName -ErrorAction SilentlyContinue | `
        Remove-OSCustomizationSpec -Confirm:$false

    $Spec = Get-OSCustomizationSpec -Name $CustomizationSpecName | `
        New-OSCustomizationSpec -Name $TempSpecName -Type NonPersistent

    Get-OSCustomizationNicMapping -OSCustomizationSpec $Spec | `
        Set-OSCustomizationNicMapping `
            -IpMode UseStaticIP `
            -IpAddress $IP `
            -SubnetMask "255.255.255.0" `
            -DefaultGateway "192.168.10.250"

    # Create linked clone
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

    # Set CPU and Memory
    Set-VM -VM $vm -NumCpu $NumCPU -MemoryGB $MemoryGB -Confirm:$false | Out-Null

    # Power on
    Start-VM -VM $vm | Out-Null

    # Add to list
    $CreatedVMs += $vm

    # Cleanup temp spec
    Remove-OSCustomizationSpec -OSCustomizationSpec $TempSpecName -Confirm:$false | Out-Null

    Start-Sleep -Seconds 2
}

Write-Host "All VMs created successfully" -ForegroundColor Cyan

# === WAIT FOR LAB DURATION ===
Write-Host "Lab will run for $LabDurationMinutes minutes..." -ForegroundColor Yellow
Start-Sleep -Seconds ($LabDurationMinutes * 60)

# === POWER OFF AND ANNOTATE ===
$ShutdownTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

foreach ($vm in $CreatedVMs) {

    Write-Host "Powering off VM: $($vm.Name)" -ForegroundColor Red

    Stop-VM -VM $vm -Confirm:$false | Out-Null

    # Add annotation
    Set-VM -VM $vm -Notes "Powered off at $ShutdownTime" -Confirm:$false | Out-Null
}

Write-Host "All VMs have been powered off and annotated" -ForegroundColor Cyan
