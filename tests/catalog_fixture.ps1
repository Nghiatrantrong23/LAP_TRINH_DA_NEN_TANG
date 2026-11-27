param([ValidateSet('Cart','ClearCart','Order','CompleteOrder','Check','Cleanup')][string]$Mode,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{10}$')][string]$RunTag,[int]$CourtId=0,[int]$ServiceId=0)
$ErrorActionPreference='Stop'
$config=Get-Content (Join-Path $PSScriptRoot '..\WebApi\appsettings.json') -Raw | ConvertFrom-Json
$conn=New-Object System.Data.SqlClient.SqlConnection($config.ConnectionStrings.SportsBooking)
if($conn.Database -ne 'SportsBookingStage2'){throw 'Fixtures only support the local development database.'}
try{
 $conn.Open();$cmd=$conn.CreateCommand()
 $null=$cmd.Parameters.Add('@tag',[System.Data.SqlDbType]::VarChar,10);$cmd.Parameters['@tag'].Value=$RunTag
 $null=$cmd.Parameters.Add('@court',[System.Data.SqlDbType]::Int);$cmd.Parameters['@court'].Value=$CourtId
 $null=$cmd.Parameters.Add('@service',[System.Data.SqlDbType]::Int);$cmd.Parameters['@service'].Value=$ServiceId
 if($Mode -eq 'Cleanup'){
  $cmd.CommandText=@"
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @products TABLE(Id int);
INSERT @products SELECT Id FROM Products WHERE Name LIKE 'TEST3 %'+@tag;
DECLARE @orders TABLE(Id uniqueidentifier);
INSERT @orders SELECT Id FROM Orders WHERE OrderCode='TEST3-'+@tag;
DECLARE @members TABLE(Id uniqueidentifier);
INSERT @members SELECT Id FROM Members WHERE NormalizedEmail='CATALOG-'+UPPER(@tag)+'@EXAMPLE.COM';
DELETE SlotReservations WHERE OrderItemId IN (SELECT Id FROM OrderItems WHERE OrderId IN (SELECT Id FROM @orders));
DELETE OrderItemSlots WHERE OrderItemId IN (SELECT Id FROM OrderItems WHERE OrderId IN (SELECT Id FROM @orders));
DELETE OrderItems WHERE OrderId IN (SELECT Id FROM @orders);
DELETE Orders WHERE Id IN (SELECT Id FROM @orders);
DELETE CartItems WHERE CartId IN (SELECT Id FROM Carts WHERE MemberId IN (SELECT Id FROM @members));
DELETE Carts WHERE MemberId IN (SELECT Id FROM @members);
DELETE AuthSessions WHERE MemberId IN (SELECT Id FROM @members);
DELETE Members WHERE Id IN (SELECT Id FROM @members);
INSERT FileDeletionJobs(RelativePath,CreatedAt,Attempts) SELECT ImagePath,GETUTCDATE(),0 FROM Products WHERE Id IN (SELECT Id FROM @products) AND ImagePath IS NOT NULL;
DELETE CourtSlots WHERE CourtId IN (SELECT Id FROM @products);
DELETE CourtPriceRules WHERE CourtId IN (SELECT Id FROM @products);
DELETE CourtSchedules WHERE CourtId IN (SELECT Id FROM @products);
DELETE CourtProfiles WHERE ProductId IN (SELECT Id FROM @products);
DELETE Products WHERE Id IN (SELECT Id FROM @products);
INSERT FileDeletionJobs(RelativePath,CreatedAt,Attempts) SELECT ImagePath,GETUTCDATE(),0 FROM Categories WHERE Name LIKE 'TEST3 %'+@tag AND ImagePath IS NOT NULL;
DELETE Categories WHERE Name LIKE 'TEST3 %'+@tag;
COMMIT;
"@
 }else{
  $guard="IF NOT EXISTS(SELECT 1 FROM Products WHERE Id=@court AND Name='TEST3 Court '+@tag) OR NOT EXISTS(SELECT 1 FROM Products WHERE Id=@service AND Name='TEST3 Service '+@tag) THROW 50000,'Fixture product identity mismatch',1;"
  if($Mode -eq 'Cart'){
   $cmd.CommandText=$guard+@"
INSERT CartItems(CartId,ProductId,Quantity,CreatedAt) SELECT Id,@service,1,GETUTCDATE() FROM Carts WHERE MemberId=(SELECT Id FROM Members WHERE NormalizedEmail='CATALOG-'+UPPER(@tag)+'@EXAMPLE.COM');
"@
  }elseif($Mode -eq 'ClearCart'){
   $cmd.CommandText="DELETE CartItems WHERE ProductId=@service AND CartId IN (SELECT Id FROM Carts WHERE MemberId IN (SELECT Id FROM Members WHERE NormalizedEmail='CATALOG-'+UPPER(@tag)+'@EXAMPLE.COM'));"
  }elseif($Mode -eq 'Order'){
   $cmd.CommandText=$guard+@"
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @order uniqueidentifier=NEWID(),@item bigint,@slot bigint;
INSERT Orders(Id,OrderCode,MemberId,VenueId,BookingDate,CustomerName,CustomerPhone,Status,TotalAmount,DepositAmount,IdempotencyKey,RequestHash,CreatedAt)
SELECT @order,'TEST3-'+@tag,m.Id,p.VenueId,CAST(DATEADD(day,2,GETDATE()) AS date),'TEST3 '+@tag,'0900000000','Confirmed',10000,3000,@tag,HASHBYTES('SHA2_256',@tag),GETUTCDATE() FROM Products p CROSS JOIN Members m WHERE p.Id=@court AND m.NormalizedEmail='CATALOG-'+UPPER(@tag)+'@EXAMPLE.COM';
INSERT OrderItems(OrderId,ProductId,ProductName,ProductType,Unit,Quantity,LineTotal) SELECT @order,Id,Name,Type,Unit,1,10000 FROM Products WHERE Id=@court;
SET @item=SCOPE_IDENTITY();
INSERT CourtSlots(CourtId,PlayDate,StartTime,EndTime,IsBlocked) VALUES(@court,CAST(DATEADD(day,2,GETDATE()) AS date),'18:00','18:30',0);
SET @slot=SCOPE_IDENTITY();
INSERT OrderItemSlots(OrderItemId,CourtSlotId,UnitPrice)VALUES(@item,@slot,10000);
INSERT SlotReservations(CourtSlotId,OrderItemId)VALUES(@slot,@item);
COMMIT;
"@
  }elseif($Mode -eq 'CompleteOrder'){$cmd.CommandText="UPDATE Orders SET Status='Completed' WHERE OrderCode='TEST3-'+@tag;"}
  elseif($Mode -eq 'Check'){
   $cmd.CommandText=$guard+@"
IF (SELECT COUNT(*) FROM CourtSchedules WHERE CourtId=@court)<>7 OR (SELECT COUNT(*) FROM CourtPriceRules WHERE CourtId=@court)<>7 THROW 50000,'Court schedule/rule count mismatch',1;
IF EXISTS(SELECT 1 FROM OrderItems WHERE OrderId IN(SELECT Id FROM Orders WHERE OrderCode='TEST3-'+@tag) AND LineTotal<>10000) THROW 50000,'Historical price was changed',1;
"@
  }
 }
 $null=$cmd.ExecuteNonQuery();Write-Output 'Fixture operation passed.'
}finally{$conn.Dispose()}
