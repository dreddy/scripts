#!/bin/sh


cat /proc/cpuinfo | awk '

BEGIN {
    FS=":";
    cpu_count=0;
    cpupath="/sys/devices/system/cpu/cpu";
}

/^processor/ {
    ## Stupid awk string to num conversion
    curr_cpu = $2+0;
    cpu_number[cpu_count] = curr_cpu;
    cpu_count++;
}
/^apicid/ {
    apicid[curr_cpu]= $2;
}
/^initial apicid/ {
	ini_apicid[curr_cpu]=$2;
}

END {
    printf("CPU\tPkg\tCore\tAPICi\tAPIC\tCache0(sharing)\tCache1(sharing)\tCache2(sharing)\tCache3(sharing)\n");
    for (i=0; i<cpu_count; i++) {
	cpuidx=cpu_number[i]

	fname = cpupath cpuidx "/cache/index0/size"
	getline c0size < fname
	close(fname)
        fname = cpupath cpuidx "/cache/index0/shared_cpu_list"
        getline c0share < fname
	close(fname)

	fname = cpupath cpuidx "/cache/index1/size"
	getline c1size < fname
	close(fname)
        fname = cpupath cpuidx "/cache/index1/shared_cpu_list"
        getline c1share < fname
	close(fname)

	fname = cpupath cpuidx "/cache/index2/size"
	getline c2size < fname
	close(fname)
        fname = cpupath cpuidx "/cache/index2/shared_cpu_list"
        getline c2share < fname
	close(fname)

	fname = cpupath cpuidx "/cache/index3/size"
	getline c3size < fname
	close(fname)
	fname = cpupath cpuidx "/cache/index3/shared_cpu_list"
	getline c3share < fname
	close(fname)
	
	fname = cpupath cpuidx "/topology/physical_package_id"
	getline pkgid < fname
	close(fname)

	fname = cpupath cpuidx "/topology/core_id"
	getline coreid < fname
	close(fname)


	printf("%d\t%s\t%s\t%s\t%s\t%6s(%s)\t%6s(%s)\t%6s(%s)\t%6s(%s)\n", cpuidx, pkgid, coreid,
		ini_apicid[cpuidx], apicid[cpuidx], c0size, c0share, c1size, c1share, c2size, c2share,
		c3size, c3share);
    }
}
'
