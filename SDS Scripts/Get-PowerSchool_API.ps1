<#
Script Name:
Get-PowerSchool_API.ps1

Synopsis:
This script is designed to connect to your PowerSchool instance, and get/check several objects and attributes related to SDS.

Syntax Examples:
.\Get-PowerSchool_API.ps1 -ServerUrl <server url> -ClientID <client id> -ClientSecret <client secret>

Written By: 
SDS Team

Change Log:
Version 1.0, 12/09/2016 - First Draft

#>

[CmdletBinding()]

Param (

	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]

    	[string]$ServerUrl,

    
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    
	[string]$ClientId,

    
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    
	[string]$ClientSecret

)

# Global Constants

$global:AccessToken = ""

$global:AccessTokenUrl = $ServerUrl+"/oauth/access_token"

$global:SchoolTerm = "2015"

$global:DefaultPageSize = "10"

$SchoolUrl = $ServerUrl+"/ws/v1/district/school?page=1&pagesize=100"

# Resource Counts

$DistSchoolCountUrl = $ServerUrl+"/ws/v1/district/school/count"

$DistActiveStudentCountUrl = $ServerUrl+"/ws/v1/district/student/count?q=school_enrollment.enroll_status==(A)"

$SchoolCourseCountUrl = $ServerUrl+"/ws/v1/school/{0}/course/count"

$SchoolSectionCountUrl = $ServerUrl+"/ws/v1/school/{0}/section/count"

$SchoolSectionsOfTermCountUrl = $ServerUrl+"/ws/v1/school/{0}/section/count?q=term.start_year=="+$global:SchoolTerm

$SchoolStaffCountUrl = $ServerUrl+"/ws/v1/school/{0}/staff/count"

$SchoolActiveStudentCountUrl = $ServerUrl+"/ws/v1/school/{0}/student/count?q=school_enrollment.enroll_status==(A)"

$SchoolAllStudentCountUrl = $ServerUrl+"/ws/v1/school/{0}/student/count?q=school_enrollment.enroll_status_code=ge=-1"


# Resource by ID

$CourseByIdUrl = $ServerUrl+"/ws/v1/course/{0}"

$SchoolByIdUrl = $ServerUrl+"/ws/v1/school/{0}"

$SectionByIdUrl = $ServerUrl+"/ws/v1/section/{0}?expansions=term"

$StudentByIdUrl = $ServerUrl+"/ws/v1/student/{0}?expansions=addresses,contact,contact_info,demographics,ethnicity_race,phones,school_enrollment,student_username"

$StudentByNumUrl = $ServerUrl+"/ws/v1/district/student?page=1&pagesize=10&expansions=addresses,contact,contact_info,demographics,ethnicity_race,phones,school_enrollment&q=local_id=={0}"

$StaffByIdUrl = $ServerUrl+"/ws/v1/staff/{0}?expansions=addresses,emails,phones,school_affiliations"

$EnrollmentByIdUrl = $ServerUrl+"/ws/v1/section_enrollment/{0}"

# Resource list

$CoursesUrl = $ServerUrl+"/ws/v1/school/{0}/course?page={1}&pagesize={2}"

$SectionsUrl = $ServerUrl+"/ws/v1/school/{0}/section?page={1}&pagesize={2}&expansions=term"

$StaffsUrl = $ServerUrl+"/ws/v1/school/{0}/staff?page={1}&pagesize={2}&expansions=addresses,emails,phones,school_affiliations"

$ActiveStudentsUrl = $ServerUrl+"/ws/v1/school/{0}/student?page={1}&pagesize={2}&expansions=addresses,contact,contact_info,demographics,ethnicity_race,phones,school_enrollment&q=school_enrollment.enroll_status==(A)"

$AllStudentsUrl = $ServerUrl+"/ws/v1/school/{0}/student?page={1}&pagesize={2}&expansions=addresses,contact,contact_info,demographics,ethnicity_race,phones,school_enrollment&q=school_enrollment.enroll_status_code=gt=-2147483648"




function Get-AccessToken

{
    
	$Credentials = $ClientId+":"+$ClientSecret
    
	$RawCred = [System.Text.Encoding]::UTF8.GetBytes($Credentials)
    
	$EncodedCreds = [System.Convert]::ToBase64String($RawCred)
    
	$Headers = @{Authorization = "Basic "+$EncodedCreds}

    
	$Body = "grant_type=client_credentials"

    

	try
{
        
	$Result = Invoke-RestMethod -Uri $global:AccessTokenUrl -Method Post -Headers $Headers -Body $Body
        
	if ($Result.access_token -ne $null)
{
            
		Write-Host ""
            
		Write-Host "Acquired AccessToken: $($Result.access_token)"
            
		Write-Host "RESULT: Credentials are valid." -ForegroundColor Green
            
		Write-Host ""
            Return $($Result.access_token)
        
	}
        
	
	else{
            
	Write-Host ""
            
	Write-Host "RESULT: ServerURL is not valid" -ForegroundColor Red
            
	Exit;
        
	}

	}
    
	
	catch
{
        
	Write-Host ""
        
	Write-Host $_.Exception.Message
        
	Write-Host "RESULT: Credentials are invalid." -ForegroundColor Red
        
	Write-Host ""
        
	Exit;
    
	}

}


function Execute-Get-Request($QueryUrl)

{
    
	$Headers = @{Authorization = "Bearer "+$global:AccessToken; Accept = "application/json"}
    
	$Result = Invoke-RestMethod -Uri $QueryUrl -Method Get -Headers $Headers
    
	Return $Result

}


function Get-Entity-ById($EntityUrl, $EntityName)

{
    
	Write-Host "Enter $EntityName ID: "
    
	$Id = Read-Host
    
	$QueryUrl = [System.String]::Format($EntityUrl,$Id)
    
	$Result = Execute-Get-Request $QueryUrl
    
	Return $Result

}






function Get-Course-ById

{
    
	$Result = Get-Entity-ById $CourseByIdUrl "Course"
    
	if ($Result.course -ne $null)
{
        
		$Result.course | fl *
    
	}

}






function Get-School-ById

{
	$Result = Get-Entity-ById $SchoolByIdUrl "School"
    
	if ($Result.school -ne $null)
{
        
		$Result.school | fl *
    
	}

}






function Get-Section-ById

{
	
$Result = Get-Entity-ById $SectionByIdUrl "Section"
    
	if ($Result.section -ne $null)
{
        
		$Result.section | fl *
    
	}

}



function Get-Student-ById

{

	$Result = Get-Entity-ById $StudentByIdUrl "Student"
    
	if ($Result.student -ne $null)
{
        
		$Result.student | fl *
    
	}

}






function Get-Student-ByNumber

{
    
	$Result = Get-Entity-ById $StudentByNumUrl "Student"
    
	if ($Result.students -ne $null)
{
        
		$Result.students.student | fl *
    
	}

}







function Get-Staff-ById

{
    
	$Result = Get-Entity-ById $StaffByIdUrl "Staff"
    
	if ($Result.staff -ne $null)
{
        
		$Result.staff | fl *
       
		$Result.staff.school_affiliations.school_affiliation | fl *
    
	}

}






function Get-SectionEnrollment-ById

{
    
	$Result = Get-Entity-ById $EnrollmentByIdUrl "Section Enrollment"
    
	if ($Result.section_enrollment -ne $null)
{
        
		$Result.section_enrollment | fl *
    
	}

}




function Get-Schools($Silent)

{
    
	if ($Silent -eq $false){ 
	Write-Host "Getting Schools..." 
	}

    
	$Result = Execute-Get-Request $SchoolUrl
    
	
	if ($Result.schools -ne $null -and $Result.schools.school -ne $null)
{
        
		if ($Silent -eq $false)
{
            
		$Result.schools.school | fl *
        
		}

        
	Return $Result.schools.school
    
	}

}






function Get-Sections

{
    
	$PageNumber = "1"

    
	Write-Host "School ID: "
    
	$SchoolId = Read-Host

    
	Write-Host "Getting Sections in School $SchoolId"
    
	$RequestUrl = [System.String]::Format($SectionsUrl, $SchoolId, $PageNumber, $global:DefaultPageSize)
    
	$Result = Execute-Get-Request $RequestUrl

    
	if ($Result.sections -ne $null -and $Result.sections.section -ne $null)
{
        
	$Result.sections.section | fl *
    
	}

}






function Get-Courses

{
    
	$PageNumber = "1"

    
	Write-Host "School ID: "
    
	$SchoolId = Read-Host

    
	Write-Host "Getting Courses in School $SchoolId"
    
	$RequestUrl = [System.String]::Format($CoursesUrl, $SchoolId, $PageNumber, $global:DefaultPageSize)
    
	$Result = Execute-Get-Request $RequestUrl

    
	if ($Result.courses -ne $null -and $Result.courses.course -ne $null)
{
        
	$Result.courses.course | fl *
    
	}

}


function Get-Students

{
    
	$PageNumber = "1"

    
	Write-Host "School ID: "
    
	$SchoolId = Read-Host

    
	Write-Host "Getting Studets in School $SchoolId"
    
	$RequestUrl = [System.String]::Format($AllStudentsUrl, $SchoolId, $PageNumber, $global:DefaultPageSize)
    
	$Result = Execute-Get-Request $RequestUrl

    
	if ($Result.students -ne $null -and $Result.students.student -ne $null)
{
        
	$Result.students.student | fl *
    
	}

}






function Get-Staffs

{
    
	$PageNumber = "1"

    
	Write-Host "School ID: "
    
	$SchoolId = Read-Host

    
	Write-Host "Getting Staffs in School $SchoolId"
    
	$RequestUrl = [System.String]::Format($StaffsUrl, $SchoolId, $PageNumber, $global:DefaultPageSize)
    
	$Result = Execute-Get-Request $RequestUrl

    
	if ($Result.staffs -ne $null -and $Result.staffs.staff -ne $null)
{
        
	$Result.staffs.staff | fl *
    
	}

}






function Get-Entity-Count($EntityCountUrl)

{
    
	$Result = Execute-Get-Request $EntityCountUrl
    
	if ($Result.resource -ne $null -and $Result.resource.count -ne $null)
{
        
	Return $Result.resource.count
    
	}

}






function Get-Staff-Count-Of-School($SchoolId)

{
    
	$EntityCountUrl = [System.String]::Format($SchoolStaffCountUrl, $SchoolId)
    
	Return Get-Entity-Count $EntityCountUrl

}






function Get-Section-Count-Of-School($SchoolId)

{
    
	$EntityCountUrl = [System.String]::Format($SchoolSectionCountUrl, $SchoolId)
    
	Return Get-Entity-Count $EntityCountUrl

}






function Get-Course-Count-Of-School($SchoolId)

{
    
	$EntityCountUrl = [System.String]::Format($SchoolCourseCountUrl, $SchoolId)
    
	Return Get-Entity-Count $EntityCountUrl

}




function Get-Active-Student-Count-Of-School($SchoolId)

{
    
	$EntityCountUrl = [System.String]::Format($SchoolActiveStudentCountUrl, $SchoolId)
    
	Return Get-Entity-Count $EntityCountUrl
}



function Get-All-Student-Count-Of-School($SchoolId)

	{
    
		$EntityCountUrl = [System.String]::Format($SchoolAllStudentCountUrl, $SchoolId)
    
		Return Get-Entity-Count $EntityCountUrl
}



function Get-Overview

		{
    
			$SchoolCount = Get-Entity-Count $DistSchoolCountUrl
    
			$ActiveStudentCount = Get-Entity-Count $DistActiveStudentCountUrl

  
  
			Write-Host ""
    
			Write-Host "Number of Schools in this district: $SchoolCount"
    
			Write-Host "Number of Active Students in this district: $ActiveStudentCount"
    
			Write-Host ""
    
			Write-Host "--- School Stats ---"

    
			
			$Schools = Get-Schools $true

    
			
			Write-Host "ID `tStudent (All)`tStaff`tSection`tCourse`t`"School Name`""
    
		
		foreach ($School in $Schools)
    
		{
        
			$StaffCount = Get-Staff-Count-Of-School $($School.id)
        
			$SectionCount = Get-Section-Count-Of-School $($School.id)
        
			$CourseCount = Get-Course-Count-Of-School $($School.id)
        
			$ActiveStudentCount = Get-Active-Student-Count-Of-School $($School.id)
        
			$AllStudentCount = Get-All-Student-Count-Of-School $($School.id)

        
			Write-Host "$($School.id) `t$ActiveStudentCount `t$AllStudentCount `t$StaffCount `t$SectionCount `t$CourseCount `t`"$($School.name)`""
    		}
    
	Write-Host ""

}





# Main

&{
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
	$global:AccessToken = Get-AccessToken;

    

	do
{
        
		Write-Host ""
        
		Write-Host "    1.  Get/Refresh Access Token"
        
		Write-Host "    2.  Get District Overview"
        
		Write-Host "    3.  Get Schools"
        
		Write-Host "    4.  Get School By ID"
        
		Write-Host "    5.  Get Section By ID"
        
		Write-Host "    6.  Get Student By ID"
        
		Write-Host "    61. Get Student By Student Number"
        
		Write-Host "    7.  Get Staff By ID"
        
		Write-Host "    8.  Get Course By ID"
        
		Write-Host "    9.  Get Section Enrollment By ID"
        
		Write-Host "    10. Get Staff    [Page# 1, Count: $global:DefaultPageSize]"
        
		Write-Host "    11. Get Section  [Page# 1, Count: $global:DefaultPageSize]"
        
		Write-Host "    12. Get Students [Page# 1, Count: $global:DefaultPageSize]"
        
		Write-Host "    13. Get Courses  [Page# 1, Count: $global:DefaultPageSize]"
        
		Write-Host "    *.  Exit"
        
		Write-Host ""
        
		Write-Host "Selection: ";
        
		$Choice = Read-Host

        

		switch ($Choice)
        
		{
            
			1 { $global:AccessToken = Get-AccessToken }
            
			2 { Get-Overview }
            
			3 { Get-Schools }
            
			4 { Get-School-ById }
            
			5 { Get-Section-ById }
            
			6 { Get-Student-ById }
            
			7 { Get-Staff-ById }
            
			8 { Get-Course-ById }
            
			9 { Get-SectionEnrollment-ById }
            
			10 { Get-Staffs }
            
			11 { Get-Sections }
            
			12 { Get-Students }
            
			13 { Get-Courses }
            
			61 { Get-Student-ByNumber }
            
			default { Break }
        
		}

        
		Write-Host "----------------------------------------------------"
    
	} while ($Choice -ge 1 -and $Choice -le 9)

}


