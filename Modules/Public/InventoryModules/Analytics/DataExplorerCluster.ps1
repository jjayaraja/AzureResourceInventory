<#
.Synopsis
Inventory for Azure Data Explorer

.DESCRIPTION
This script consolidates information for all microsoft.kusto/clusters resource provider in $Resources variable. 
Excel Sheet Name: DataExplorerCluster

.Link
https://github.com/jjayaraja/AzureResourceInventory/Modules/Public/InventoryModules/Analytics/DataExplorerCluster.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 3.6.0
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Retirements, $Task ,$File, $SmaResources, $TableStyle, $Unsupported)

If ($Task -eq 'Processing') {

    $DataExplorer = $Resources | Where-Object { $_.TYPE -eq 'microsoft.kusto/clusters' }

    if($DataExplorer)
        {
            $tmp = foreach ($1 in $DataExplorer) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $sku = $1.SKU
                $Retired = $Retirements | Where-Object { $_.id -eq $1.id }
                if ($Retired) 
                    {
                        $RetiredFeature = foreach ($Retire in $Retired)
                            {
                                $RetiredServiceID = $Unsupported | Where-Object {$_.Id -eq $Retired.ServiceID}
                                $tmp0 = [pscustomobject]@{
                                        'RetiredFeature'            = $RetiredServiceID.RetiringFeature
                                        'RetiredDate'               = $RetiredServiceID.RetirementDate 
                                    }
                                $tmp0
                            }
                        $RetiringFeature = if ($RetiredFeature.RetiredFeature.count -gt 1) { $RetiredFeature.RetiredFeature | ForEach-Object { $_ + ' ,' } }else { $RetiredFeature.RetiredFeature}
                        $RetiringFeature = [string]$RetiringFeature
                        $RetiringFeature = if ($RetiringFeature -like '* ,*') { $RetiringFeature -replace ".$" }else { $RetiringFeature }

                        $RetiringDate = if ($RetiredFeature.RetiredDate.count -gt 1) { $RetiredFeature.RetiredDate | ForEach-Object { $_ + ' ,' } }else { $RetiredFeature.RetiredDate}
                        $RetiringDate = [string]$RetiringDate
                        $RetiringDate = if ($RetiringDate -like '* ,*') { $RetiringDate -replace ".$" }else { $RetiringDate }
                    }
                else 
                    {
                        $RetiringFeature = $null
                        $RetiringDate = $null
                    }
                $VNET = if(![string]::IsNullOrEmpty($data.virtualNetworkConfiguration.subnetid)){$data.virtualNetworkConfiguration.subnetid.split('/')[8]}else{$null}
                $Subnet = if(![string]::IsNullOrEmpty($data.virtualNetworkConfiguration.subnetid)){$data.virtualNetworkConfiguration.subnetid.split('/')[10]}else{$null}
                $DataPIP = if(![string]::IsNullOrEmpty($data.virtualNetworkConfiguration.dataManagementPublicIpId)){$data.virtualNetworkConfiguration.dataManagementPublicIpId.split('/')[8]}else{$null}
                $EnginePIP = if(![string]::IsNullOrEmpty($data.virtualNetworkConfiguration.enginePublicIpId)){$data.virtualNetworkConfiguration.enginePublicIpId.split('/')[8]}else{$null}
                $TenantPerm = if($data.trustedExternalTenants.value -eq '*'){'All Tenants'}else{$data.trustedExternalTenants.value}
                $AutoScale = if($data.optimizedAutoscale.isEnabled -eq 'true'){'Enabled'}else{'Disabled'}
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                        = $1.id;
                            'Subscription'              = $sub1.Name;
                            'Resource Group'            = $1.RESOURCEGROUP;
                            'Name'                      = $1.NAME;
                            'Location'                  = $1.LOCATION;
                            'Retiring Feature'          = $RetiringFeature;
                            'Retiring Date'             = $RetiringDate;
                            'Compute specifications'    = $sku.name;
                            'Instance count'            = $sku.capacity;
                            'State'                     = $data.state;
                            'State Reason'              = $data.stateReason;
                            'Virtual Network'           = $VNET;
                            'Subnet'                    = $Subnet;
                            'Data Management Public IP' = $DataPIP;
                            'Engine Public IP'          = $EnginePIP;
                            'Tenants Permissions'       = $TenantPerm;
                            'Disk Encryption'           = $data.enableDiskEncryption;
                            'Streaming Ingestion'       = $data.enableStreamingIngest;
                            'Optimized Autoscale'       = $AutoScale;
                            'Optimized Autoscale Min'   = $data.optimizedAutoscale.minimum;
                            'Optimized Autoscale Max'   = $data.optimizedAutoscale.maximum;
                            'URI'                       = $data.uri;
                            'Data Ingestion Uri'        = $data.dataIngestionUri;
                            'Resource U'                = $ResUCount;
                            'Tag Name'                  = [string]$Tag.Name;
                            'Tag Value'                 = [string]$Tag.Value
                        }
                        $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }                
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources) {

        $TableName = ('DTExplTable_'+($SmaResources.'Resource U').count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText 'All Tenants' -Range O:O
        $condtxt += New-ConditionalText FALSE -Range P:P
        $condtxt += New-ConditionalText Disabled -Range R:R
        #Retirement
        $condtxt += New-ConditionalText -Range E2:E100 -ConditionalType ContainsText


        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Retiring Feature')
        $Exc.Add('Retiring Date')
        $Exc.Add('Compute specifications')
        $Exc.Add('Instance count')
        $Exc.Add('State')
        $Exc.Add('State Reason')
        $Exc.Add('Virtual Network')
        $Exc.Add('Subnet')
        $Exc.Add('Data Management Public IP')
        $Exc.Add('Engine Public IP')
        $Exc.Add('Tenants Permissions')
        $Exc.Add('Disk Encryption')
        $Exc.Add('Streaming Ingestion')
        $Exc.Add('Optimized Autoscale')
        $Exc.Add('Optimized Autoscale Min')
        $Exc.Add('Optimized Autoscale Max')
        $Exc.Add('URI')
        $Exc.Add('Data Ingestion Uri')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        [PSCustomObject]$SmaResources | 
        ForEach-Object { $_ } | Select-Object $Exc | 
        Export-Excel -Path $File -WorksheetName 'Data Explorer Clusters' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
}