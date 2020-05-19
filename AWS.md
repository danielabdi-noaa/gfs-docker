# How to run fv3 containers on AWS

Here we describe how to run the ufs-weather-model on AWS using ParallelCluster -- an HPC cluster management tool.
ParallelCluster needs to be installed on your local machine following [these instructions](https://docs.aws.amazon.com/parallelcluster/latest/ug/install).
It is also recommended to install and configure the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) as well
to facilitate copying data to/from s3 for your instances.

Once you install these two tools, you can modify the configuration files they produce according to your needs

Contents my `~/.aws/configure` file show I am using us east coast region 2.

    [default]
    output = json
    region = us-east-2

Contens of `~/.parallelcluster/configure`

    [aws]
    aws_region_name = us-east-2

	[global]
	update_check = true
	sanity_check = true
	cluster_template = default

	[aliases]
	ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}

	[cluster default]
	key_name = aws-noaa
	base_os = ubuntu1804
	scheduler = slurm
	max_queue_size = 50
	max_vcpus = 50
	maintain_initial_size = true
	vpc_settings = default
	master_instance_type = c5n.18xlarge
	compute_instance_type = c5n.18xlarge
	master_root_volume_size = 80
	compute_root_volume_size = 80
	placement = cluster
	placement_group = DYNAMIC
	enable_efa = compute
	#fsx_settings = myfsx
	disable_hyperthreading = true

	[vpc default]
	vpc_id = vpc-8f7b44e7
	master_subnet_id = subnet-fb270093

	#[fsx myfsx]
	#shared_dir = /scratch1
	#storage_capacity = 1200
	#import_path = s3://fv3-bucket

So I am launching the parallel cluster in the same region as aws-config with the following details: Ubuntu OS with slurm as the job scheduler, maximum of 50 virtual cpus,
c5n.18xlarge instances for both login and compute nodes. You may want to use a cheaper instance for the login node. For this run, I am using 80 GB storage for
both master and compute nodes. I am not using the Lustre file system for this run and will install what I need in my home directory that is automatically shared between compute instances. For real runs, it is probably not wise to rely on your home directory being shared -- rather setup a Luster FSX that has all your software and data
and will be automatically loaded when you startup your cluster. Hyperthreading should be disabled in the config file since vCPUs are often hyper-threaded cores.

Ok now let us create our cluster with the following command. It will take some time initialize your cluster so have patience.

    $ pcluster create mycluster
	Beginning cluster creation for cluster: mycluster
	Info: There is a newer version 2.7.0 of AWS ParallelCluster available.
	Creating stack named: parallelcluster-mycluster
	Status: parallelcluster-mycluster - CREATE_COMPLETE                             
	MasterPublicIP: 3.22.203.11
	ClusterUser: ubuntu
	MasterPrivateIP: 172.31.11.194

Then we can login to the master node via ssh

	$ ssh -i "aws-noaa.pem" ubuntu@ec2-3-22-203-11.us-east-2.compute.amazonaws.com
	Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-1060-aws x86_64)

	 * Documentation:  https://help.ubuntu.com
	 * Management:     https://landscape.canonical.com
	 * Support:        https://ubuntu.com/advantage

	  System information as of Tue May 19 00:23:35 UTC 2020

	  System load:  0.34               Processes:           527
	  Usage of /:   15.4% of 77.49GB   Users logged in:     0
	  Memory usage: 0%                 IP address for ens5: 172.31.11.194
	  Swap usage:   0%

	 * MicroK8s passes 9 million downloads. Thank you to all our contributors!

	     https://microk8s.io/

	 * Canonical Livepatch is available for installation.
	   - Reduce system reboots and improve kernel security. Activate at:
	     https://ubuntu.com/livepatch

	210 packages can be updated.
	142 updates are security updates.


	Last login: Tue Feb 25 21:05:25 2020 from 3.80.175.15

You can also use `pcluster ssh mycluster` to login to the master node. 
Lets quickly checkout what we have. 

    $ module avail
	------------------------------------------------------------------------------------- /usr/share/modules/modulefiles -------------------------------------------------------------------------------------
	dot  intelmpi/2019.6.166  libfabric-aws/1.9.0amzn1.1  module-git  module-info  modules  null  openmpi/4.0.2  use.own  
	------------------------------------------------------------------------------------- /usr/share/modules/modulefiles -------------------------------------------------------------------------------------
	dot  intelmpi/2019.6.166  libfabric-aws/1.9.0amzn1.1  module-git  module-info  modules  null  openmpi/4.0.2  use.own  

Lmod is already installed and we can see we have intelmpi pre-installed. Alos openmpi/4.0.2 is availble.
For our containers we use either intel MPI for the intel builds, and MPICH for the GNU builds. So if we use GNU built
containers we have to install MPICH ourselves.

Slurm is already on the system too

    $ sinfo
	PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
	compute*     up   infinite      0    n/a 

Then we install docker and singularity on our home directory using the following script.

	#!/bin/bash

	mkdir -p $HOME/opt
	mkdir -p $HOME/opt/bin
	mkdir -p $HOME/opt/lib
	mkdir -p $HOME/opt/include
	mkdir -p $HOME/tmp

	#singularity
	sudo apt-get update && \
	  sudo apt-get install -y build-essential \
	  libseccomp-dev pkg-config squashfs-tools cryptsetup libssl-dev uuid-dev

	export VERSION=1.13.5 OS=linux ARCH=amd64

	wget -O $HOME/tmp/go${VERSION}.${OS}-${ARCH}.tar.gz https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz && \
	  tar -C $HOME/opt -xzf $HOME/tmp/go${VERSION}.${OS}-${ARCH}.tar.gz

	echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
	  echo 'export PATH=${PATH}:${HOME}/opt/go/bin:${GOPATH}/bin:${HOME}/opt/singularity/bin:${HOME}/opt/bin' >> ~/.bashrc && \
	  source ~/.bashrc

	export GOPATH=${HOME}/go
	export PATH=${PATH}:${HOME}/opt/go/bin:${GOPATH}/bin:${HOME}/opt/singularity/bin:${HOME}/opt/bin

	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b $(go env GOPATH)/bin v1.15.0

	mkdir -p ${GOPATH}/src/github.com/sylabs && \
	  cd ${GOPATH}/src/github.com/sylabs && \
	  git clone https://github.com/sylabs/singularity.git && \
	  cd singularity

	git checkout -b v3.5.1

	cd ${GOPATH}/src/github.com/sylabs/singularity && \
	  mkdir -p $HOME/opt/singularity && \
	  ./mconfig --without-suid --prefix=$HOME/opt/singularity && \
	  cd ./builddir && \
	  make && \
	  make install

	#docker
	sudo apt-get update && \
	     apt-get install -y \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    software-properties-common

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable"

	sudo apt-get update

	sudo apt-get install -y docker-ce

	sudo groupadd docker
	sudo usermod -aG docker $USER
	newgrp docker

For running GNU containers on multiple nodes, we also need to install MPICH ourselves using something like this

	#mpich2
	IFLAGS=
    #IFLAGS="--with-device=ch3:nemesis:mxm --with-mxm=$HOME/mellanox/mxm"
	VER=3.3a2
	PP=mpich-${VER}
	DLINK="https://www.mpich.org/static/downloads/${VER}/${PP}.tar.gz"
	cd $SRC_DIR && wget ${DLINK} && \
	    tar -xzvf ${PP}.tar.gz && \
	    cd ${PP} && \
	    ./configure $IFLAGS --prefix=$HOME && \
	    make && \
	    make install && \
	    cd ..

Here is what we have in our home directory now

    $ ls
    C384.tar.gz  C96.tar.gz  bin  go  include  install_pre.sh  lib  mpich-3.3a2  mpich-3.3a2.tar.gz  opt  share  tmp
    $ ls bin
    hydra_nameserver  hydra_persist  hydra_pmi_proxy  mpic++  mpicc  mpichversion  mpicxx  mpiexec  mpiexec.hydra  mpif77  mpif90  mpifort  mpirun  mpivars  parkill

We have our test cases C96 and C384 and also mpich is installed.
Next we pull our docker and singularity image. We are not really going to use the docker image so you could do only the singulairty pull command.

    $ docker pull dshawul/fv3-gnu
	Using default tag: latest
	latest: Pulling from dshawul/fv3-gnu
	2746a4a261c9: Pull complete 
	4c1d20cdee96: Pull complete 
	0d3160e1d0de: Pull complete 
	c8e37668deea: Pull complete 
	396b858b3768: Pull complete 
	b93b8bfd7fa7: Pull complete 
	393c9ade4a02: Pull complete 
	207abff45099: Pull complete 
	154a1a15eea2: Pull complete 
	bfee0662a038: Pull complete 
	87e45c21d29a: Pull complete 
	7908dd4adf9b: Pull complete 
	d0478b3fe744: Pull complete 
	f2eb74323213: Pull complete 
	f6e24b17aa16: Pull complete 
	7ac21f411e5c: Pull complete 
	Digest: sha256:9fa463eb187e42b63def041b41b492ebd9d2b4471ef5c24c6f41de695628c320
	Status: Downloaded newer image for dshawul/fv3-gnu:latest
	docker.io/dshawul/fv3-gnu:latest
	$ singularity pull docker://dshawul/fv3-gnu
	INFO:    Converting OCI blobs to SIF format
	INFO:    Starting build...
	Getting image source signatures
	Copying blob 2746a4a261c9 done  
	Copying blob 4c1d20cdee96 done  
	Copying blob 0d3160e1d0de done  
	Copying blob c8e37668deea done  
	Copying blob 396b858b3768 done  
	Copying blob b93b8bfd7fa7 done  
	Copying blob 393c9ade4a02 done  
	Copying blob 207abff45099 done  
	Copying blob 154a1a15eea2 done  
	Copying blob bfee0662a038 done  
	Copying blob 87e45c21d29a done  
	Copying blob 7908dd4adf9b done  
	Copying blob d0478b3fe744 done  
	Copying blob f2eb74323213 done  
	Copying blob f6e24b17aa16 done  
	Copying blob 7ac21f411e5c done  
	Copying config 078cd540ec done  
	Writing manifest to image destination
	Storing signatures
	2020/05/19 01:08:39  info unpack layer: sha256:2746a4a261c9e18bfd7ff0429c18fd7522acc14fa4c7ec8ab37ba5ebaadbc584
	2020/05/19 01:08:39  info unpack layer: sha256:4c1d20cdee96111c8acf1858b62655a37ce81ae48648993542b7ac363ac5c0e5
	2020/05/19 01:08:39  info unpack layer: sha256:0d3160e1d0de4061b5b32ee09af687b898921d36ed9556df5910ddc3104449cd
	2020/05/19 01:08:39  info unpack layer: sha256:c8e37668deea784f47c8726d934adc12b8d20a2b1c50b0b0c18cb62771cd3684
	2020/05/19 01:08:39  info unpack layer: sha256:396b858b376833334338ef77c6fa9d62e40876e711ad7851b81276ac331dd605
	2020/05/19 01:08:44  info unpack layer: sha256:b93b8bfd7fa7f329a1b1b30ca9966d0ab458f2e4d032a90002381563dacb89cb
	2020/05/19 01:08:44  info unpack layer: sha256:393c9ade4a023883a0cb5568a6a6a4e51195b97495316084d1ed346590e08b26
	2020/05/19 01:08:44  info unpack layer: sha256:207abff45099ce1c992f13daada15b242d0d3f16b5edf17bfa30a602bdac0cfb
	2020/05/19 01:08:47  info unpack layer: sha256:154a1a15eea2ca7ce074cfd3854e0fbc30fd4b680834fdcebb70e3c4e1126f56
	2020/05/19 01:08:47  info unpack layer: sha256:bfee0662a038e90d22780625a536155eacfb87cf83547e45b306274820009ca2
	2020/05/19 01:08:47  info unpack layer: sha256:87e45c21d29aed13f1e6f31b3e698b8fa25cbe51e198169b6404d3fcb3839c82
	2020/05/19 01:08:47  info unpack layer: sha256:7908dd4adf9b136b6918500da142bbb2f50c3636fa497122382537f0daf2f470
	2020/05/19 01:08:47  info unpack layer: sha256:d0478b3fe744eacfec28c645b0547d83dd120b6bdc39f71344c85ee95bfb2c65
	2020/05/19 01:08:48  info unpack layer: sha256:f2eb74323213fea2103118a6c54554413b213b197dc4adabf2b83aa82a9bd56b
	2020/05/19 01:08:52  info unpack layer: sha256:f6e24b17aa16ef08ccc74563b2381e27af6cc52e8d87102fd751e9dddc377b4c
	2020/05/19 01:08:52  info unpack layer: sha256:7ac21f411e5cf1d569fbd14021938c836588d71cfd2091e12af4041911767f3b
	INFO:    Creating SIF file...

You will find a singularity image in the current directory. Then we extract our test cases

    $ ls
    C384  C384.tar.gz  C96  C96.tar.gz  bin  fv3-gnu_latest.sif  go  include  install_pre.sh  lib  mpich-3.3a2  mpich-3.3a2.tar.gz  opt  share  tmp

The C384 container needs by default 22 compute nodes ( 216 compute + 48 IO ranks), with 2 threads per task.
So we will write a script like below to run the case on multiple nodes using singularity

    #!/bin/bash
    export OMP_NUM_THREADS=2
    $HOME/bin/mpirun -np 264 singularity exec ../fv3-gnu_latest.sif /opt/NEMSfv3gfs/tests/fv3_1.exe

On each node we use only 24 of the cores ( 12 mpi ranks with 2 threads each ), hence, 22 * 12 = 264 mpi ranks total

So this will launch 264 copies of the singularity image using the MPICH we just installed in our home directory, and then executes
the fv3 executable to run the forecast. Next we request the required number of nodes with an interactive srun ( should be possible to use sbatch too)

	$ srun -N 22 --cpus-per-task 2 --pty bash
	srun: Required node not available (down, drained or reserved)
	srun: job 2 queued and waiting for resources
	srun: job 2 has been allocated resources
	srun: error: fwd_tree_thread: can't find address for host ip-172-31-0-99, check slurm.conf
    ....
	srun: error: Application launch failed: Can't find an address, check slurm.conf
	srun: Job step aborted: Waiting up to 32 seconds for job step to finish.
	srun: error: Timed out waiting for job step to complete

This will take some time to initialize all the compute nodes, and often it fails on the first request as shown above.
Just run the srun command again and you will be on one of the compute nodes.

    ubuntu@ip-172-31-11-194:~/C384$ srun -N 22 --cpus-per-task 2 --pty bash
    ubuntu@ip-172-31-0-99:~/C384$ 

Also, if you go to your EC2 console, you will see 22 compute nodes runnning. 

	~/C384$ ls
	INPUT                       co2historicaldata_2014.txt  co2monthlycyc.txt     ncepdate                   volcanic_aerosols_1850-1859.txt  volcanic_aerosols_1930-1939.txt
	RESTART                     co2historicaldata_2015.txt  data_table            nems.configure             volcanic_aerosols_1860-1869.txt  volcanic_aerosols_1940-1949.txt
	aerosol.dat                 co2historicaldata_2016.txt  diag_table            nemsusage.xml              volcanic_aerosols_1870-1879.txt  volcanic_aerosols_1950-1959.txt
	co2historicaldata_2009.txt  co2historicaldata_2017.txt  field_table           other                      volcanic_aerosols_1880-1889.txt  volcanic_aerosols_1960-1969.txt
	co2historicaldata_2010.txt  co2historicaldata_2018.txt  global_h2oprdlos.f77  run-cont.sh                volcanic_aerosols_1890-1899.txt  volcanic_aerosols_1970-1979.txt
	co2historicaldata_2011.txt  co2historicaldata_2019.txt  global_o3prdlos.f77   sfc_emissivity_idx.txt     volcanic_aerosols_1900-1909.txt  volcanic_aerosols_1980-1989.txt
	co2historicaldata_2012.txt  co2historicaldata_2020.txt  input.nml             solarconstant_noaa_an.txt  volcanic_aerosols_1910-1919.txt  volcanic_aerosols_1990-1999.txt
	co2historicaldata_2013.txt  co2historicaldata_glob.txt  model_configure       time_stamp.out             volcanic_aerosols_1920-1929.txt

Then run the forecast using the script we wrote before.

    ~/C384$ ./run-cont.sh 
	INFO:    Convert SIF file to sandbox...
	INFO:    Convert SIF file to sandbox...
	INFO:    Convert SIF file to sandbox...
	INFO:    Convert SIF file to sandbox...
	INFO:    Convert SIF file to sandbox...
	INFO:    Convert SIF file to sandbox...
	.....

You will see a long message that shows that it is insitantiating 264 copies of the singularity image. Then once it is ready it will start the forecast
    
    * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . 
     PROGRAM NEMS (root) Tue May  5 06:49:48 UTC 2020 re05bf2a55454 https://github.com/NOAA-EMC/NEMS HAS BEGUN. COMPILED 2020126.00     ORG: NEMS
     STARTING DATE-TIME  MAY 19,2020  01:33:25.490  140  TUE   2458989

I only did a 6 hours forecast to save money this time. Here is how it ended up

     0 FORECAST DATE          27 AUG.  2018 AT  5 HRS  0.00 MINS
	  JULIAN DAY             2458357  PLUS   0.708333
	  RADIUS VECTOR          1.0104239
	  RIGHT ASCENSION OF SUN  10.3870934 HRS, OR  10 HRS  23 MINS  13.5 SECS
	  DECLINATION OF THE SUN  10.0739719 DEGS, OR   10 DEGS   4 MINS  26.3 SECS
	  EQUATION OF TIME        -1.6468281 MINS, OR    -98.81 SECS, OR-0.007205 RADIANS
	  SOLAR CONSTANT        1333.3145222 (DISTANCE AJUSTED)


	    for cosz calculations: nswr,deltim,deltsw,dtswh =          15   240.00000000000000        3600.0000000000000        1.0000000000000000        anginc,nstp =   1.7453292519943295E-002          15
	 PASS: fcstRUN phase 1, na =           75  time is    3.3909039497375488     
	 in fcst run phase 2, na=          75
	 PASS: fcstRUN phase 2, na =           75  time is   0.48026895523071289     
	 PASS: fcstRUN phase 1, na =           76  time is    4.8199639320373535     
	 in fcst run phase 2, na=          76
	 PASS: fcstRUN phase 2, na =           76  time is    7.6122045516967773E-002
	 PASS: fcstRUN phase 1, na =           77  time is    2.6472156047821045     
	 in fcst run phase 2, na=          77
	 PASS: fcstRUN phase 2, na =           77  time is    7.4005365371704102E-002
	 PASS: fcstRUN phase 1, na =           78  time is    2.6400632858276367     
	 in fcst run phase 2, na=          78
	 PASS: fcstRUN phase 2, na =           78  time is    5.6270122528076172E-002
	 PASS: fcstRUN phase 1, na =           79  time is    2.6194210052490234     
	 in fcst run phase 2, na=          79
	 PASS: fcstRUN phase 2, na =           79  time is    7.4930429458618164E-002
	 PASS: fcstRUN phase 1, na =           80  time is    2.6219127178192139     
	 in fcst run phase 2, na=          80
	 PASS: fcstRUN phase 2, na =           80  time is    6.2909841537475586E-002
	 PASS: fcstRUN phase 1, na =           81  time is    2.6109020709991455     
	 in fcst run phase 2, na=          81
	 PASS: fcstRUN phase 2, na =           81  time is    6.5129995346069336E-002
	 PASS: fcstRUN phase 1, na =           82  time is    2.6240987777709961     
	 in fcst run phase 2, na=          82
	 PASS: fcstRUN phase 2, na =           82  time is    7.4203968048095703E-002
	 PASS: fcstRUN phase 1, na =           83  time is    2.6116805076599121     
	 in fcst run phase 2, na=          83
	 PASS: fcstRUN phase 2, na =           83  time is    6.3020467758178711E-002
	 PASS: fcstRUN phase 1, na =           84  time is    2.6157760620117188     
	 in fcst run phase 2, na=          84
	 PASS: fcstRUN phase 2, na =           84  time is    6.2484025955200195E-002
	 PASS: fcstRUN phase 1, na =           85  time is    2.6202783584594727     
	 in fcst run phase 2, na=          85
	 PASS: fcstRUN phase 2, na =           85  time is    8.8602542877197266E-002
	 PASS: fcstRUN phase 1, na =           86  time is    2.5967001914978027     
	 in fcst run phase 2, na=          86
	 PASS: fcstRUN phase 2, na =           86  time is    7.4014902114868164E-002
	 PASS: fcstRUN phase 1, na =           87  time is    2.6023876667022705     
	 in fcst run phase 2, na=          87
	 PASS: fcstRUN phase 2, na =           87  time is    7.2835445404052734E-002
	 PASS: fcstRUN phase 1, na =           88  time is    2.6291158199310303     
	 in fcst run phase 2, na=          88
	 PASS: fcstRUN phase 2, na =           88  time is    7.5535058975219727E-002
	 PASS: fcstRUN phase 1, na =           89  time is    2.6257939338684082     
	 in fcst run phase 2, na=          89
	        2018           8          27           6           0           0
	 ZS      5863.89648      -306.433685       232.022308    
	 PS max =    1042.91492      min =    497.282227    
	 Mean specific humidity (mg/kg) above 75 mb=   3.70650220    
	 Total surface pressure (mb) =    985.771484    
	 mean dry surface pressure =    983.173584    
	 Total Water Vapor (kg/m**2) =   26.3792877    
	 --- Micro Phys water substances (kg/m**2) ---
	 Total cloud water=   4.48619835E-02
	 Total rain  water=   9.39266942E-03
	 Total cloud ice  =   3.79487053E-02
	 Total snow       =   1.82498973E-02
	 Total graupel    =   1.23691699E-03
	 ---------------------------------------------
	 ENG Deficit (W/m**2)=  0.292834699    
	 TE ( Joule/m^2 * E9) =   2.64447808    
	 UA_top max =    124.198547      min =   -40.6176796    
	 UA max =    140.454025      min =   -48.8951187    
	 VA max =    77.3696518      min =   -84.9830475    
	 W  max =    4.28558826      min =   -3.08095407    
	 Bottom w max =   0.378120184      min =  -0.523196757    
	 Bottom: w/dz max =    8.33963789E-03  min =   -1.18612684E-02
	 DZ (m) max =   -31.7237835      min =   -9397.45605    
	 Bottom DZ (m) max =   -31.7237835      min =   -49.5901604    
	 TA max =    315.790436      min =    181.124817    
	 OM max =    5.72578239      min =   -11.9949675    
	 sphum max =    2.50561405E-02  min =    1.72704784E-08
	 liq_wat max =    1.76854280E-03  min =   -1.08388946E-19
	 rainwat max =    2.79190158E-03  min =   -1.08179126E-19
	 ice_wat max =    1.03479740E-03  min =   -6.77574538E-21
	 snowwat max =    1.61043950E-03  min =   -1.08346275E-19
	 graupel max =    3.38516757E-03  min =   -2.70958632E-20
	 o3mr max =    1.76025660E-05  min =   -4.31601102E-08
	 sgs_tke max =    49.2299080      min =   -4.47795010    
	 cld_amt max =    1.00000000      min =    0.00000000    
	 Max_cld GB_NH_SH_EQ  0.620633543      0.523575902      0.635557950      0.693364441    
	 ---isec,seconds       21600       21600
	  gfs diags time since last bucket empty:    6.0000000000000000      hrs
	 PASS: fcstRUN phase 2, na =           89  time is   0.17685484886169434     
	 fv3_cap,end integrate,na=          90  time=   281.81887292861938     
	 in wrt run, nf_hours=           6           0           0 nseconds_num=           0           1  FBCount=           3  cfhour=006

	   -----------------------------------------------------
	      Block                    User time  System Time   Total Time   GID 
	   -----------------------------------------------------
	   ATMOS_INIT                  12.4023       0.0000      12.4023       0
	   TOTAL                      313.0038       0.0000     313.0038       0
	   NGGPS_IC                    10.7203       0.0000      10.7203       0
	   COMM_TOTAL                  70.6278       0.0000      70.6278       0
	   ADIABATIC_INIT               7.6751       0.0000       7.6751       0
	   FV_DYN_LOOP                212.8018       0.0000     212.8018       0
	   DYN_CORE                   149.9812       0.0000     149.9812       0
	   COMM_TRACER                  0.5819       0.0000       0.5819       0
	   C_SW                         7.1468       0.0000       7.1468       0
	   UPDATE_DZ_C                  1.6165       0.0000       1.6165       0
	   RIEM_SOLVER                 21.4681       0.0000      21.4681       0
	   D_SW                        82.3805       0.0000      82.3805       0
	   UPDATE_DZ                   11.0519       0.0000      11.0519       0
	   PG_D                         8.2428       0.0000       8.2428       0
	   TRACER_2D                   34.8983       0.0000      34.8983       0
	   REMAPPING                   26.5114       0.0000      26.5114       0
	   SAT_ADJ2                     3.2535       0.0000       3.2535       0
	   FV_DYNAMICS                213.6165       0.0000     213.6165       0
	   GFS_TENDENCIES               1.0326       0.0000       1.0326       0
	   FV_UPDATE_PHYS              19.0186       0.0000      19.0186       0
	    UPDATE_DWINDS              13.6738       0.0000      13.6738       0
	   FV_DIAG                      0.1020       0.0000       0.1020       0


When it finishes, you will see a long list of clean up messages again.

    ENDING DATE-TIME    MAY 19,2020  01:39:44.428  140  TUE   2458989
     PROGRAM nems      HAS ENDED.
	* . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . * . 
	*****************RESOURCE STATISTICS*******************************
	The total amount of wall time                        = 378.937538
	The total amount of time in user mode                = 474.464301
	The total amount of time in sys mode                 = 120.047071
	The maximum resident set size (KB)                   = 651228
	Number of page faults without I/O activity           = 1166108
	Number of page faults with I/O activity              = 0
	Number of times filesystem performed INPUT           = 331176
	Number of times filesystem performed OUTPUT          = 741168
	Number of Voluntary Context Switches                 = 10173
	Number of InVoluntary Context Switches               = 4685
	*****************END OF RESOURCE STATISTICS*************************

	INFO:    Cleaning up image...
	INFO:    Cleaning up image...
	INFO:    Cleaning up image...
	INFO:    Cleaning up image...
	INFO:    Cleaning up image...
	INFO:    Cleaning up image...
	INFO:    Cleaning up image...
	...

Then immediately afterwards we stop our compute fleet using pcluster
    
    $ pcluster stop mycluster
     Stopping compute fleet : mycluster

