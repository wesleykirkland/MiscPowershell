#Working Sample
function New-EC2InstanceProgramattic {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)] 
        [string]$Name, 
        [Parameter(Mandatory=$true)] 
        [int]$Number
    )

    DynamicParam
        {
            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            
            #Key
            if ($True) {
                $attributes = New-Object System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "__AllParameterSets"
                $attributes.Mandatory = $true

                $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList (Get-EC2KeyPair).KeyName

                $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
                $attributeCollection.Add($ParamOptions)
                
                $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Key", [String], $attributeCollection)

                $paramDictionary.Add("Key", $dynParam1)
            }

            #Region
            if ($true) {
                $attributes3 = New-Object System.Management.Automation.ParameterAttribute
                $attributes3.ParameterSetName = "__AllParameterSets"
                $attributes3.Mandatory = $true

                $ParamOptions3 = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList (Get-EC2Region).RegionName

                $attributeCollection3 = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection3.Add($attributes3)
                $attributeCollection3.Add($ParamOptions3)

                $dynParam3 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Region", [String], $attributeCollection3)

                $paramDictionary.Add("Region", $dynParam3)
            }

            #SubnetID
            if ($Region -like "*") {
                $attributes2 = New-Object System.Management.Automation.ParameterAttribute
                $attributes2.ParameterSetName = "__AllParameterSets"
                $attributes2.Mandatory = $true

                $ParamOptions2 = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList (Get-EC2Subnet | Where-Object {($PSItem.State -eq 'available') -and ($PSItem.AvailabilityZone -like "$Region*")}).CidrBlock

                $attributeCollection2 = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection2.Add($attributes2)
                $attributeCollection2.Add($ParamOptions2)

                $dynParam2 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("SubnetID", [String], $attributeCollection2)

                $paramDictionary.Add("SubnetID", $dynParam2)
            }

            #InstanceType
            if ($true) {
                $attributes4 = New-Object System.Management.Automation.ParameterAttribute
                $attributes4.ParameterSetName = "__AllParameterSets"
                $attributes4.Mandatory = $true

                $ParamOptions4 = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList ((Invoke-RestMethod http://www.ec2instances.info/instances.json).instance_type)

                $attributeCollection4 = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection4.Add($attributes4)
                $attributeCollection4.Add($ParamOptions4)

                $dynParam4 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("InstanceType", [String], $attributeCollection4)

                $paramDictionary.Add("InstanceType", $dynParam4)
            }

            #SecurityGroup
            if ($true) {
                $attributes5 = New-Object System.Management.Automation.ParameterAttribute
                $attributes5.ParameterSetName = "__AllParameterSets"
                $attributes5.Mandatory = $false

                $ParamOptions5 = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList (Get-EC2SecurityGroup).GroupName

                $attributeCollection5 = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection5.Add($attributes5)
                $attributeCollection5.Add($ParamOptions5)

                $dynParam5 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("SecurityGroup", [String], $attributeCollection5)

                $paramDictionary.Add("SecurityGroup", $dynParam5)
            }

            #ImageID
            if ($true) {
                $attributes6 = New-Object System.Management.Automation.ParameterAttribute
                $attributes6.ParameterSetName = "__AllParameterSets"
                $attributes6.Mandatory = $true

                $ParamOptions6 = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList (Get-EC2ImageByName)

                $attributeCollection6 = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection6.Add($attributes6)
                $attributeCollection6.Add($ParamOptions6)

                $dynParam6 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("ImageID", [String], $attributeCollection6)

                $paramDictionary.Add("ImageID", $dynParam6)
            }

            return $paramDictionary
        }

    Begin {}
    Process {
        #Build session vars to find ids from above provided input
        $SubnetFilter = New-Object Amazon.EC2.Model.Filter
        $SubnetFilter.Name = 'cidr'
        $SubnetFilter.Value = $PSBoundParameters.SubnetID

        $SecurityGroupFilter = New-Object Amazon.EC2.Model.Filter
        $SecurityGroupFilter.Name = 'group-name'
        $SecurityGroupFilter.Value = $PSBoundParameters.SecurityGroup

        #Create new EC2 Instance
        $EC2Instance = New-EC2Instance -ImageId ((Get-EC2ImageByName -Name $PSBoundParameters.ImageID).ImageId) -InstanceType $PSBoundParameters.InstanceType -MinCount $PSBoundParameters.Number -MaxCount $PSBoundParameters.Number -KeyName $PSBoundParameters.Key -SubnetId ((Get-EC2Subnet -Filter $SubnetFilter).SubnetId) -Region $PSBoundParameters.Region #-SecurityGroupId ((Get-EC2SecurityGroup -Filter $PSBoundParameters.SecurityGroupFilter).GroupId)
        
        #Name EC2 Instance
        New-EC2Tag -Resource $EC2Instance.Instances.InstanceId -Tag @{Key="Name"; Value=$PSBoundParameters.Name}
    }

    End {}
}
