<#
    Core script courtesy of Aaron Nelson (http://sqlvariant.com/)
#>
Param(
[Parameter(Mandatory=$true,position=0)][String] $OutputFile,
[Parameter(ParameterSetName="SingleServer",position=1)][String] $SingleServer,
[Parameter(ParameterSetName="CMS",position=1)][String] $CMS,
[Parameter(ParameterSetName="ServerFile",position=1)][String] $ServerFile
)

Function Write-Excel($vSvr, $IntRow, $Sheet)
{
     $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
     $Sheet.Cells.Item($intRow,2) = $vSvr
     $Sheet.Cells.Item($intRow,1).Font.Bold = $True
     $Sheet.Cells.Item($intRow,2).Font.Bold = $True
     $intRow++
     $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
     $Sheet.Cells.Item($intRow,2) = "COLLATION"
     $Sheet.Cells.Item($intRow,3) = "COMPATIBILITY LEVEL"
     $Sheet.Cells.Item($intRow,4) = "AUTOSHRINK"
     $Sheet.Cells.Item($intRow,5) = "AUTOUPDATESTATISTICS"
     $Sheet.Cells.Item($intRow,6) = "AUTOCREATESTATISTICS"
     $Sheet.Cells.Item($intRow,7) = "RECOVERY MODEL"
     $Sheet.Cells.Item($intRow,8) = "SIZE (MB)"
     $Sheet.Cells.Item($intRow,9) = "SPACE AVAILABLE (MB)"
     for ($col = 1; $col –le 9; $col++)
     {    $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
          $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
          $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
     }
     $intRow++
     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr
     $dbs = $s.Databases
     ForEach ($db in $dbs) 
     {
          $dbSpaceAvailable = $db.SpaceAvailable/1KB 
          $dbSpaceAvailable = "{0:N3}" -f $dbSpaceAvailable 
          
          $Sheet.Cells.Item($intRow, 1) = $db.Name
          $Sheet.Cells.Item($intRow, 2) = $db.Collation
          $Sheet.Cells.Item($intRow, 3) = $db.CompatibilityLevel
          
          if ($db.AutoShrink -eq "True")  { $fgColor = 3 } else { $fgColor = 0 }
          $Sheet.Cells.Item($intRow, 4) = $db.AutoShrink 
          $Sheet.Cells.item($intRow, 4).Interior.ColorIndex = $fgColor
		  
          if ($db.AutoUpdateStatisticsEnabled -eq "True")  { $fgColor = 0 } else { $fgColor = 3 }
          $Sheet.Cells.Item($intRow, 5) = $db.AutoUpdateStatisticsEnabled 
          $Sheet.Cells.item($intRow, 5).Interior.ColorIndex = $fgColor
		  
          if ($db.AutoCreateStatisticsEnabled -eq "True")  { $fgColor = 0 } else { $fgColor = 3 }
          $Sheet.Cells.Item($intRow, 6) = $db.AutoCreateStatisticsEnabled 
          $Sheet.Cells.item($intRow, 6).Interior.ColorIndex = $fgColor
		  
          if ($db.RecoveryModel -eq 1) { $Sheet.Cells.Item($intRow, 7) = "Full" }
		  elseif ($db.RecoveryModel -eq 3) { $Sheet.Cells.Item($intRow, 7) = "Simple" }
		  else { $Sheet.Cells.Item($intRow, 7) = "Bulk Logged" }
          
          if ($db.RecoveryModel -eq 3)  { $fgColor = 3 } else { $fgColor = 4 }
		  $Sheet.Cells.item($intRow, 8).Interior.ColorIndex = $fgColor
          $Sheet.Cells.Item($intRow, 8) = "{0:N3}" -f $db.Size
          
          if ($dbSpaceAvailable -lt 2.000) { $fgColor = 3 } else { $fgColor = 0 }
          $Sheet.Cells.Item($intRow, 9) = $dbSpaceAvailable 
          $Sheet.Cells.item($intRow, 9).Interior.ColorIndex = $fgColor
          $intRow ++
    }
    Return $intRow
}


$vFullPath = $OutputFile
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
$Excel = New-Object -ComObject Excel.Application 
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1) 
$intRow = 1
    switch($PsCmdlet.ParameterSetName)
    {
    "SingleServer" {
        $intRow = Write-Excel $SingleServer $intRow $Sheet
        }
    "CMS" {
        $sconn = new-object System.Data.SqlClient.SqlConnection("server=$CMS;Trusted_Connection=true");
        $q = "SELECT DISTINCT server_name FROM msdb.dbo.sysmanagement_shared_registered_servers;"
        $sconn.Open()
        $cmd = new-object System.Data.SqlClient.SqlCommand ($q, $sconn);
        $cmd.CommandTimeout = 0;
        $dr = $cmd.ExecuteReader();
        while ($dr.Read()){
            $ServerName = $dr.GetValue(0);
            $intRow = Write-Excel $ServerName $intRow $Sheet
            $intRow ++
         }
        $dr.Close()
        $sconn.Close()   
        }
    "ServerFile" {
       foreach ($ServerName in get-content $ServerFile)
       {
            $intRow = Write-Excel $ServerName $intRow $Sheet
            $intRow ++
       }
      }
    }

$Sheet.UsedRange.EntireColumn.AutoFit()
$Excel.Worksheets.Item(3).Delete()
$Excel.Worksheets.Item(2).Delete()
$Excel.Worksheets.Item(1).Name = "Recovery models"
#$Excel.SaveAs($vFullPath)
#$Excel.Close()
