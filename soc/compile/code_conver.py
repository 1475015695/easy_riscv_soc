code_line=[]
with open("main.bin","rb") as source_file:
    temp_lines=source_file.read()
    ttmep_line=temp_lines.hex('\n',-4)   
    line_list=ttmep_line.split('\n')
    for line in line_list:
        code_line.append(line)

        
with open("initrom.txt","w") as dist_file:
    for line in code_line: 
        # print(line)
        # dist_file.write(line[0:2]+"\n"+line[2:4]+"\n"+line[4:6]+"\n"+line[6:8]+"\n")
        dist_file.write(line[6:8]+line[4:6]+line[2:4]+line[0:2]+"\n")
with open("initrom.coe","w") as dist_file:
    dist_file.write("memory_initialization_radix=16;\n")
    dist_file.write("memory_initialization_vector=\n")
    for line in code_line: 
        # print(line)
        # dist_file.write(line[0:2]+"\n"+line[2:4]+"\n"+line[4:6]+"\n"+line[6:8]+"\n")
        dist_file.write(line[6:8]+line[4:6]+line[2:4]+line[0:2]+"\n")
# make ;python code_conver.py;iverilog -o wave -y ..\ ..\tb_instruction_top.v ;  vvp wave ; C:\modeltech64_2020.4\win64\vcd2wlf.exe wave.vcd wave.wlf
#make ;python code_conver.py;iverilog -o wave -y ..\ ..\tb_soc.v ;  vvp wave ; C:\modeltech64_2020.4\win64\vcd2wlf.exe wave.vcd wave.wlf
#make ;python code_conver.py