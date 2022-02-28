#!/bin/bash

#Start and Endtime, can also define at run time.
export StartTime='01/01/22'
export EndTime='01/07/22'

#Help; command line options
while getopts 'S:s:E:e:h' arg
do
        case "${arg}" in
                S) unset StartTime && StartTime=${OPTARG};;
                s) unset StartTime && StartTime=${OPTARG};;
                E) unset EndTime && EndTime=${OPTARG};;
                e) unset EndTime && EndTime=${OPTARG};;
                h) echo "  Script to produce slurm CPU and Memory statistics in human-readable and csv formats"
                   echo
                   echo "   Ex: ./slurm_usage_report.sh -S MM/DD/YY -E MM/DD/YY"
                   echo 
                   echo "   Output is saved to ~/slurm-report-\$StartDate--\$Enddate" 
                   echo "   Default options can be modified in the beginning variable definitions within this script"
                   echo 
                   echo "   Options: See example above for usage"
                   echo "        -S                Specify the start time in slurm readable time format."
                   echo "        -E                Specify the end time in slurm readable time format."
                   echo "        -h                Display this help message"
                   exit 1
        esac
done

#More variable definitions
export ReportDir=~/slurm_report-$(echo $StartTime--$EndTime|tr '/' '-')
export ReportFile=$ReportDir/results.txt
export RawLoc=$ReportDir/Raw.txt
export ParsedLoc=$ReportDir/Parsed.txt

mkdir -p $ReportDir

#Collect Data
sacct -a -S $StartTime -E $EndTime -P --noconvert --noheader -o 'user,JobID,Account,NCPUs,ReqMem,elapsedraw,cputimeraw,allocgres' > $RawLoc

#Comments are respective to to line in awk function
# 1. Only show jobs with less than 30 days elapsed; orphaned jobs could have unset enddate.
# 2. Delineate MemPerNode jobs 
# 3. Remove "Mn" suffix and convert from MB to GB 
# 4. Calculate 'MemTime': Multiply requested GB of RAM * elapsed time in seconds
# 5. Remove root jobs
# 6. Remove batch, external subjobs
# 7. Remove "gpu" and "GPU" from gres column to keep only # of GRES
# 8. Multiply # of GPU's in GRES by elapsed time to calculate GPUTime""

awk '$6 < 2592000' OFS="|" FS="|" $RawLoc |
	awk '$5~/Mn/' OFS="|" FS="|" | 
	awk '$5 ~ /[0-9\.]+Mn/ { $5 = ($5 / 1024) } 1' OFS="|" FS="|" |
	awk '{ $9 = int($5 * $6) } 1' OFS="|" FS="|" |
	sed '/^root/d' |
	sed '/^|/d' |
	sed 's/\(gpu:\|GPU:\)//g' |
	awk '$8 ~ /[0-9]/ { $10 = int($8 * $6) } 1' OFS="|" FS="|" \
	> $ParsedLoc

# 1. Only show jobs with less than 30 days elapsed
# 2. Delineate MemPerCore jobs 
# 3. Remove "Mc" suffix and convert to MemPerNode
# 4. Convert from MB to GB 
# 5. Calculate 'MemTime': Multiply requested GB of RAM * elapsed time in seconds
# 6. Remove root jobs
# 7. Remove batch, external subjobs
# 8. Remove "GPU" and "7696487" from gres column to keep only # of GRES
# 9. Multiply # of GPU's in GRES by elapsed time to calculate GPUTime""

awk '$6 < 2592000' OFS="|" FS="|" $RawLoc |
	awk '$5~/Mc/' OFS="|" FS="|" | 
	awk '$5 ~ /[0-9\.]+Mc/ { $5 = int($5 * $4) } 1' OFS="|" FS="|"  |
        awk '{ $5 = ($5 / 1024) } 1' OFS="|" FS="|" |
	awk '{ $9 = int($5 * $6) } 1' OFS="|" FS="|" |
	sed '/^root/d' |
	sed '/^|/d' |
	sed 's/\(gpu:\|7696487:\)//g' |
	awk '$8 ~ /[0-9]/ { $10 = int($8 * $6) } 1' OFS="|" FS="|" \
	>> $ParsedLoc

#Count CPUTime and 'MemTime' and convert to hours
export TotalCPUHours=$(awk '{sum+=$7;} END{print int(sum / 3600);}' OFS="|" FS="|" $ParsedLoc)
export TotalMemHours=$(awk '{sum+=$9;} END{print int(sum / 3600);}' OFS="|" FS="|" $ParsedLoc)

#Count GPU's and multiply by elapsed time
#sed -i -e 's/\(gpu:\|7696487:\)//g' $ParsedLoc |

export TotalGPUHours=$(awk '{sum+=$10;} END{print int(sum / 3600);}' OFS="|" FS="|" $ParsedLoc)

#Identify Slurm accounts
export SlurmAccounts="$(sed '/^|/d' $ParsedLoc | sort -t '|' -k 3 | awk '{print $3}' OFS="|" FS="|" | uniq | grep -v root)"

#Gather list of labs that ran jobs
QueryLab () {
	grep "^[^|]*|[^|]*|$1|" $ParsedLoc
}

#Sum up total "RAMHours" per lab
LabMem () {
	awk '{sum+=$9;} END{print int(sum / 3600);}' OFS="|" FS="|"
}

#Sum up total CPUHours per lab
LabCPU () {
	awk '{sum+=$7;} END{print int(sum / 3600);}' OFS="|" FS="|"
}

LabGPU () {
        awk '{sum+=$10;} END{print int(sum / 3600);}' OFS="|" FS="|"
}

#Calculate RAM & CPU per lab
output_lab_stats() { 
for i in $(echo "$SlurmAccounts") ;do
	echo $i Lab:
	echo -n Total CPU Hours: 
	grep "^[^|]*|[^|]*|$i|" $ParsedLoc |
	awk '{sum+=$7;} END{print int(sum / 3600);}' OFS="|" FS="|" 
	echo -n "Total RAM hours for $i lab: "
	grep "^[^|]*|[^|]*|$i|" $ParsedLoc |
	awk '{sum+=$9;} END{print int(sum / 3600);}' OFS="|" FS="|"
        echo "CPU Share: $(echo "scale=4;$(QueryLab $i| LabCPU)/$TotalCPUHours*100" | bc)%"
        echo "RAM Share: $(echo "scale=4;$(QueryLab $i| LabMem)/$TotalMemHours*100" | bc)%"
        echo "GPU Share: $(echo "scale=4;$(QueryLab $i| LabGPU)/$TotalGPUHours*100" | bc)%"

	echo
	echo
done

echo Total CPUHours: $TotalCPUHours
echo Total MemHours: $TotalMemHours
echo Total GPUHours: $TotalGPUHours
echo ; echo
}


#Output CSV
output_csv () {
        echo "---CSV BEGIN---"
        echo -n "Lab,RAM Hours,CPU Hours,GPU Hours,CPU Share,RAM Share,GPU Share"

        for i in $(echo "$SlurmAccounts") ;do
		echo
		echo -n $i,$(QueryLab $i| LabMem),$(QueryLab $i| LabCPU),$(QueryLab $i| LabGPU),$(echo "scale=4;$(QueryLab $i| LabCPU)/$TotalCPUHours" | bc),$(echo "scale=4;$(QueryLab $i| LabMem)/$TotalMemHours" | bc),$(echo "scale=4;$(QueryLab $i| LabGPU)/$TotalGPUHours" | bc)
        done
	echo
	echo Total,$TotalMemHours,$TotalCPUHours,$TotalGPUHours,1,1,1
	echo "---CSV END---"
}


output_lab_stats 2>&1 | tee $ReportFile
output_csv 2>&1 | tee -a $ReportFile


echo ; echo ; echo "Output logged in $ReportFile"
