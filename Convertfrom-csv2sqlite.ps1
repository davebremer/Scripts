Function Convertfrom-csv2sqlite {
<#
.SYNOPSIS
 Convert a CSV file into an sqlite database

.DESCRIPTION
 Convert a CSV file into an sqlite database. If the database file does not exist then it is created.
 If the file exists then the data is appended to an existing table.

.PARAMETER CsvFile
 The name of the CSV file to be converted. The first line must contain headings

.PARAMETER Database
 The name of the SQLite database file

.PARAMETER TableName
 The name of the table to import the CSV file. If not provided, then the name of the file is used
 as the table name - excluding the suffix. The table must contain fields matching the CSV header line

.PARAMETER BufferSize
 The number of records to be imported in a batch. Defaults to 1000.

.EXAMPLE
 Convertfrom-csv2sqlite  -CsvFile "example.csv" -Database "wibble.sqlite"

 If the file wibble.sqlite does not exist then it is created with a single table named 'example'.
 This will have fields based on the csv file heading.

 If the file exists then the data is appended to the 'example' table. If the table does not exist
 then an "ExecuteNonQuery" exception is thrown

.EXAMPLE
  Convertfrom-csv2sqlite  -CsvFile "example.csv" -Database "wibble.sqlite" -TableName "foo"

  The table 'foo' is used rather than 'example'. 

.INPUTS
 CSV file

.OUTPUTS
 SQLite file
 
.LINK
 https://github.com/RamblingCookieMonster/PSSQLite

.NOTES
 Author: Dave Bremer
 Date: 2018-11-12

 Updates:

#>

#Requires –Modules pssqlite
[CmdletBinding()] 
param(
    [Parameter(
        Mandatory = $TRUE,
        Position = 1,
        HelpMessage = 'CSV File'
    )]
    [String]$CsvFile,

    [Parameter(
        Mandatory = $TRUE,
        Position = 2,
        HelpMessage = 'Database File'
    )]
    [String]$Database,

    [Parameter( 
        Mandatory = $FALSE,
        HelpMessage = 'Table name'
    )]
    [String]$TableName = ((Split-path $CsvFile -Leaf).Split(".")[0]),

    [Parameter(
        Mandatory = $FALSE,
        HelpMessage = 'Buffer Size'
    )]
    [ValidateRange(1, [int]::MaxValue)]
    [int64]$BufferSize=1000
  ) 

BEGIN{
    
    $dbExists = (Test-Path $Database -PathType Leaf)
    Write-Verbose ("Database file: {0} - Exists? {1}" -f $Database,$dbExists)
    Write-Verbose ("CSV file: {0}" -f $CsvFile)
    Write-Verbose ("Table: {0}" -f $Tablename)
    Write-Verbose ("Buffer Size: {0}" -f $BufferSize)

    $values = @()
    $datatable = $null
    $conn = New-SQLiteConnection -DataSource $Database
}

PROCESS{
    if (! $dbExists ) { #create database
        #$headings = (Get-Content $CsvFile -first 1).Replace(" ","_")
        $headings = (Get-Content $CsvFile -first 1)
        $createQuery = ("CREATE TABLE [{0}] ([{1}] TEXT)" -f $TableName,
            ($headings.Replace(",","] TEXT,[")))
        Write-Verbose ("Create Query: {0}" -f $createQuery)
        Invoke-SqliteQuery -SQLiteConnection $conn -Query $createquery
    }

    import-csv $CsvFile |
    foreach {
        $values += $_

        if ($values.Count -ge 4500) {
            $datatable = $values | Out-DataTable
            Invoke-SQLiteBulkCopy -SQLiteConnection $conn -DataTable $datatable -Table $tablename -Force
            $values = @()
        }
    
    } 
    #Write out any left in buffer
    if ($values.Count -gt 0) {
            $datatable = $values | Out-DataTable
            Invoke-SQLiteBulkCopy -SQLiteConnection $conn -DataTable $datatable -Table $tablename -Force
            $values = @()
    }

}
END{$conn.Close()}
}