Function WriteHeader() {
	Write-Output "<table border=`"1`">"
	Write-Output "<tr>"
	Write-Output "    <td rowspan=`"2`"><strong>President</strong></td>"
	Write-Output "    <td style=`"text-align: center`" colspan=`"2`"><strong>First market day</strong></td>"
	Write-Output "    <td style=`"text-align: center`" colspan=`"2`"><strong>Last market day</strong></td>"
	Write-Output "    <td rowspan=`"2`"><strong>Annual return</strong></td>"
	Write-Output "    <td style=`"text-align: center`" colspan=`"2`"><strong>Record highs</strong></td>"
	Write-Output "</tr>"
	Write-Output "<tr>"
	Write-Output "    <td><strong>Date</strong></td>"
	Write-Output "    <td><strong>Open</strong></td>"
	Write-Output "    <td><strong>Date</strong></td>"
	Write-Output "    <td><strong>Close</strong></td>"
	Write-Output "    <td><strong>Count</strong></td>"
	Write-Output "    <td><strong>Mean days to new record high</strong></td>"
	Write-Output "</tr>"
}

Function WritePresident() {
	$president = $presidents[$iPresident].President;

	If ($marketDays -eq 0) {
		# No market days;
		Return;
	}

	# +1 is because we include both the start and end days
	$calendarDays = (New-Timespan -Start $firstMarketDay -End $lastMarketDay).Days + 1;

	# the annualized return is (last/first)^(365.25/days) - 1
	$return = "{0:P0}" -f ([Math]::pow([double]$lastClose / [double]$firstOpen, 365.25 / $calendarDays) - 1);

	If ($recordHighs -eq 0) {
		$daysBetweenHighs = "N/A";
		$daysBetweenHighsAlign = "left";
	} Else {
		# the mean time between highs is (days / highs)
		$daysBetweenHighs = "{0:N0}" -f ($calendarDays / $recordHighs);
		$daysBetweenHighsAlign = "right";
	}

	$firstDatePretty = $firstMarketDay.ToString("yyyy-MM-dd");
	$firstOpenPretty = ([double]$firstOpen).ToString("N2");
	$lastDatePretty = $lastMarketDay.ToString("yyyy-MM-dd");
	$lastClosePretty = ([double]$lastClose).ToString("N2");

	Write-Output "<tr>"
	Write-Output "    <td>$president</td>"
	Write-Output "    <td>$firstDatePretty</td>"
	Write-Output "    <td style=`"text-align: right`">$firstOpenPretty</td>"
	Write-Output "    <td>$lastDatePretty</td>"
	Write-Output "    <td style=`"text-align: right`">$lastClosePretty</td>"
	Write-Output "    <td style=`"text-align: right`">$return</td>"
	Write-Output "    <td style=`"text-align: right`">$recordHighs</td>"
	Write-Output "    <td style=`"text-align: $daysBetweenHighsAlign`">$daysBetweenHighs</td>"
	Write-Output "</tr>"

}

Function WriteFooter() {
	$firstMarketDay = [DateTime]$djia[0].Date;
	$firstDatePretty = $firstMarketDay.ToString("yyyy-MM-dd");

	$firstOpen = [double]$djia[0].Open;
	$firstOpenPretty = $firstOpen.ToString("N2");

	$lastMarketDay = [DateTime]$djia[@($djia).Count - 1].Date;
	$lastDatePretty = $lastMarketDay.ToString("yyyy-MM-dd");

	$lastClose = [double]$djia[@($djia).Count - 1].Close;
	$lastClosePretty = $lastClose.ToString("N2");

	# +1 is because we include both the start and end days
	$calendarDays = (New-Timespan -Start $firstMarketDay -End $lastMarketDay).Days + 1;

	# the annualized return is (last/first)^(365.25/days) - 1
	$return = "{0:P0}" -f ([Math]::pow([double]$lastClose / [double]$firstOpen, 365.25 / $calendarDays) - 1);

	# the mean time between highs is (days / highs)
	$daysBetweenHighs = "{0:N0}" -f ($calendarDays / $totalRecordHighs);
	$daysBetweenHighsAlign = "right";

	Write-Output "<tr>"
	Write-Output "    <td><strong>Overall</strong></td>"
	Write-Output "    <td><strong>$firstDatePretty</strong></td>"
	Write-Output "    <td style=`"text-align: right`"><strong>$firstOpenPretty</strong></td>"
	Write-Output "    <td><strong>$lastDatePretty</strong></td>"
	Write-Output "    <td style=`"text-align: right`"><strong>$lastClosePretty</strong></td>"
	Write-Output "    <td style=`"text-align: right`"><strong>$return</strong></td>"
	Write-Output "    <td style=`"text-align: right`"><strong>$totalRecordHighs</strong></td>"
	Write-Output "    <td style=`"text-align: right`"><strong>$daysBetweenHighs</strong></td>"
	Write-Output "</tr>"
	Write-Output "</table>"
}

# Start End President
$presidents = Get-Content "presidents.csv" | ConvertFrom-Csv;

# Date Open High Low Close Volume
$djia = Get-Content "dow-jones-industrial-average.csv" | ConvertFrom-Csv;

# iterate over both lists at once
$iPresident = 0;
$iDjia = 0;

# per-president stats
$marketDays = 0;
$recordHighs = 0;
$totalRecordHighs = 0;
$high = 0;
$firstMarketDay = $null;
$lastMarketDay = $null;
$firstOpen = $null;
$lastClose = $null;

WriteHeader;

While ($iPresident -lt $presidents.Count -and $iDjia -lt $djia.Count) {
	While ( `
		$iPresident -lt $presidents.Count -and `
		$presidents[$iPresident].End -ne "" -and `
		[DateTime]$presidents[$iPresident].End -lt [DateTime]$djia[$iDjia].Date `
	) {
		WritePresident;

		$iPresident++;

		$marketDays = 0;
		$recordHighs = 0;
	}

	$marketDays++;

	If ($marketDays -eq 1) {
		$firstMarketDay = [DateTime]$djia[$iDjia].Date;
		$firstOpen = $djia[$iDjia].Open;
	}
	$lastMarketDay = [DateTime]$djia[$iDjia].Date;
	$lastClose = $djia[$iDjia].Close;

	If ([double]$djia[$iDjia].Close -gt [double]$high) {
		$recordHighs++;
		$totalRecordHighs++;
		[double]$high = $djia[$iDjia].Close;
	}

	$iDjia++;
}

If ($iPresident -lt $presidents.Count) {
	WritePresident;
}

WriteFooter;
