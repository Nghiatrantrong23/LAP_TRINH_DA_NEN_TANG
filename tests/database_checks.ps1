param([ValidateSet('Check','Cleanup')][string]$Mode='Check',[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{10}$')][string]$RunTag)
$ErrorActionPreference='Stop'
$config=Get-Content (Join-Path $PSScriptRoot '..\WebApi\appsettings.json') -Raw | ConvertFrom-Json
$conn=New-Object System.Data.SqlClient.SqlConnection($config.ConnectionStrings.SportsBooking)
if($conn.Database -ne 'SportsBookingStage2'){throw 'This test helper only supports SportsBookingStage2.'}
try{
 $conn.Open();$cmd=$conn.CreateCommand()
 $null=$cmd.Parameters.Add('@tag',[System.Data.SqlDbType]::VarChar,10);$cmd.Parameters['@tag'].Value=$RunTag
 if($Mode -eq 'Cleanup'){
  $cmd.CommandText=@"
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @members TABLE(Id uniqueidentifier);
INSERT @members SELECT Id FROM Members WHERE NormalizedEmail LIKE 'TEST-'+UPPER(@tag)+'-%@EXAMPLE.COM';
DELETE AuthSessions WHERE MemberId IN (SELECT Id FROM @members);
DELETE Carts WHERE MemberId IN (SELECT Id FROM @members);
DELETE Members WHERE Id IN (SELECT Id FROM @members);
COMMIT;
"@
  $null=$cmd.ExecuteNonQuery();Write-Output 'Fixture cleanup passed.'
 }else{
  $cmd.CommandText=@"
SELECT CASE WHEN
 (SELECT COUNT(*) FROM sys.tables WHERE name<>'__EFMigrationsHistory')=23
 AND (SELECT COUNT(*) FROM __EFMigrationsHistory)=1
 AND (SELECT COUNT(*) FROM Roles WHERE (Id=1 AND Name='Member') OR (Id=2 AND Name='Admin'))=2
 AND (SELECT COUNT(*) FROM Products WHERE VenueId=(SELECT Id FROM Venues WHERE Name=N'SportBooking Demo'))=5
 AND (SELECT COUNT(*) FROM CourtSchedules)=21
 AND (SELECT COUNT(*) FROM CourtPriceRules)=21
 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Members') AND name='RowVersion' AND system_type_id=189)
 AND NOT EXISTS(SELECT 1 FROM Members WHERE NormalizedEmail LIKE 'TEST-'+UPPER(@tag)+'-%@EXAMPLE.COM' AND LEFT(PasswordHash,2) <> CHAR(36)+'2')
 AND NOT EXISTS(SELECT 1 FROM AuthSessions WHERE DATALENGTH(RefreshTokenHash)<>32)
 THEN 1 ELSE 0 END;
"@
  if([int]$cmd.ExecuteScalar() -ne 1){throw 'Schema, seed, rowversion or hashed-credential check failed.'}
  # Check a real FK violation without leaving changes behind.
  $tx=$conn.BeginTransaction();$cmd.Transaction=$tx
  $cmd.CommandText="UPDATE Members SET RoleId=999 WHERE NormalizedEmail LIKE 'TEST-'+UPPER(@tag)+'-%@EXAMPLE.COM'"
  $protected=$false
  try{$null=$cmd.ExecuteNonQuery()}catch{if($_.Exception.ToString().Contains('FOREIGN KEY')){$protected=$true}else{throw}}
  $tx.Rollback();if(-not $protected){throw 'Role FK was not enforced.'}
  Write-Output '23 tables, migration, seed, rowversion, credential hashing and FK checks passed.'
 }
}finally{$conn.Dispose()}
