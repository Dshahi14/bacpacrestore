<# 
import a database from a blob container in another subsciption
 #>

[CmdletBinding()]
param (
    [string] $tenantid,
    [string] $subscriptionid,
    [string] $spn_clientid,
    [string] $spn_secret,
    [string] $skuname
)

If ($environment -eq $null){
    $environment = "DEV";
}
Write-Host "************************************************"
Write-Host "variables"
Write-Host "************************************************"
$resourcegroup1 = "demo"
$sqlserver1 = "backups1000000".ToLower()
$keyvaultname = "storesecret100000010".ToLower()    
$backups = 'backups1000000'
$filename = "DEMO_PRD_$(Get-Date -Format "yyyy-MM-dd").bacpac" ###            YOU CAN ONLY IMPORT TODAYS PRODUCTION EXPORT
$bloburi = "https://backups1000000.blob.core.windows.net/bacpac/$filename" 

### PRODUCTION
Write-Host "************************************************"
Write-Host "login via spn to production and get the container key"
Write-Host "************************************************"
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid
$keyvalue = az storage account keys list -g $resourcegroup1 -n $backups --subscription $subscriptionid --query '[0].value' -o json
az logout --username $spn_clientid

### DEV or UAT 
Write-Host "************************************************"
Write-Host "login to dev or uat"
Write-Host "************************************************" 
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid
$sqladmin = az keyvault secret show --name 'sqladmin' --vault-name $keyvaultname --query 'value' 
$sqlpassword = az keyvault secret show --name 'sqlpassword' --vault-name $keyvaultname --query 'value'
Write-Host "************************************************"
Write-Host "import bacpac from production to blob container"
Write-Host "************************************************" 
az account set --subscription $subscriptionid
az sql db delete -g $resourcegroup1 -s $sqlserver1 -n "test" --yes
az sql db create -g $resourcegroup1 -s $sqlserver1 -n "test" --service-objective $skuname
az sql db import -s $sqlserver1 -n "test" -g $resourcegroup1 -u $sqladmin -p $sqlpassword  --auth-type SQL --storage-uri $bloburi --storage-key-type "StorageAccessKey" --storage-key "$keyvalue"
