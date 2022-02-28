# Slurm-Usage-Report-Generator
Generates usage reports for CPU, RAM, and GPU with CSV output for easy chart creation

### Description 
Analyze slurm compute data and generate aggregate values for each slurm Account that was active within the selected time period. 


### Usage
No prerequisites needed - written in bash. Define start and end dates through -S and -E respectively.

`./slurm_usage_report.sh -S 01/01/22 -E 02/01/22`


### Sample Output

```
abc Lab:
Total CPU Hours:137694
Total RAM hours for accardilab lab: 301084
CPU Share: 32.5300%
RAM Share: 16.4500%
GPU Share: 57.9400%

xyz Lab:
Total CPU Hours:37591
Total RAM hours for boudkerlab lab: 138018
CPU Share: 8.8800%
RAM Share: 7.5400%
GPU Share: 3.9200%

example Lab:
Total CPU Hours:175474
Total RAM hours for listonlab lab: 800393
CPU Share: 41.4500%
RAM Share: 43.7400%
GPU Share: 0%

Total CPUHours: 423258
Total MemHours: 1829877
Total GPUHours: 8731

---CSV BEGIN---
Lab,RAM Hours,CPU Hours,GPU Hours,CPU Share,RAM Share,GPU Share
abc,301084,137694,5059,.3253,.1645,.5794
xyz,138018,37591,343,.0888,.0754,.0392
example,800393,175474,0,.4145,.4374,0
Total,1829877,423258,8731,1,1,1
---CSV END---
```

To visualize data: 
1. Import the CSV portion to excel
2. Format "Share" columns as percentages
3. Select Lab column, share columns, and create charts. Pie charts are usually most appropriate.



Once imported to excel, create charts as needed, selecting CPU, RAM, or GPU columns for values.

![exmaple_chart](https://user-images.githubusercontent.com/19819320/155907483-71cadc15-1dbe-4c46-8891-85d209a0598e.PNG)
