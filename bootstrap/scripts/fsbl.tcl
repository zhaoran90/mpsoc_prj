#========================================================
# FSBL auto generation and compiling script running in 
# the Vivado 2016.4 SDK HSI environment
# Author: Yisong Chang (changyisong@ict.ac.cn)
# Date: 13/11/2017
#========================================================

set hdf_file [lindex $argv 0]

set prj_dir [lindex $argv 1]

# Step 1: open hardware description file
set hw_design [ open_hw_design ${hdf_file} ]

# Step 2: automatic generation of FSBL project
generate_app -hw $hw_design -os standalone -proc psu_cortexa53_0 -app zynqmp_fsbl -sw fsbl -dir ${prj_dir} 

