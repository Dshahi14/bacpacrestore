[CmdletBinding()]
param (
    [string] $tenantid,
    [string] $subscriptionid,
    [string] $spn_clientid,
    [string] $spn_secret
)
Write-Host "************************************************"
Write-Host "variables"
Write-Host "************************************************"
$environment = "PRD";
$backups = 'backups1000000'
$resourcegroup1 = "demo"
$location1 = "EastUS"
$sqlserver1 = "test1000000".ToLower()
$keyvaultname = "storesecret100000010".ToLower()

### PRODUCTION
Write-Host "************************************************"
Write-Host "login via SPN which is locked down to production subscription"
Write-Host "************************************************"
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid 
$sqladmin = az keyvault secret show --name 'sqladmin' --vault-name $keyvaultname --query 'value' 
$sqlpassword = az keyvault secret show --name 'sqlpassword' --vault-name $keyvaultname --query 'value' 
Write-Host "************************************************"
Write-Host "create blog storage with container called bacpac"
Write-Host "************************************************"
az storage account create -n $backups -g $resourcegroup1 -l $location1 --sku Standard_LRS
$keyvalue = az storage account keys list -g $resourcegroup1 -n $backups --subscription $subscriptionid --query '[0].value' -o json
az storage container create -n bacpac --account-name $backups --account-key $keyvalue --auth-mode key
az storage container policy create --container-name bacpac --name ReadWrite --account-key ""$keyvalue"" --account-name $backups --auth-mode key --permissions rwdl
Write-Host "************************************************"
Write-Host "export bacpac from production to blob container"
Write-Host "************************************************"
$filename = "demo_PRD_$(Get-Date -Format "yyyy-MM-dd").bacpac"
$bloburi = "https://backups1000000.blob.core.windows.net/bacpac/$filename" 
az sql db export -s $sqlserver1 -n 'WideWorldImporters-Standard' -g $resourcegroup1 -p $sqlpassword -u $sqladmin --storage-uri $bloburi --storage-key-type "StorageAccessKey" --storage-key "$keyvalue"
