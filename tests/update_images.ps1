$config = Get-Content 'D:\LTDNT\WebApi\appsettings.json' | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($config.ConnectionStrings.SportsBooking)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
UPDATE Products SET ImagePath = '/uploads/products/sancaulong1.png' WHERE Id = 1;
UPDATE Products SET ImagePath = '/uploads/products/sancaulong2.png' WHERE Id = 2;
UPDATE Products SET ImagePath = '/uploads/products/sandabanh1.png' WHERE Id = 3;
UPDATE Products SET ImagePath = '/uploads/products/doan1.png' WHERE Id = 4;
UPDATE Products SET ImagePath = '/uploads/products/doan2.png' WHERE Id = 5;
SELECT Id, Name, ImagePath FROM Products;
"@
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    Write-Output ($reader["Id"].ToString() + ": " + $reader["Name"] + " => " + $reader["ImagePath"])
}
$conn.Close()
