from flask import Flask
from flask import request
import struct
import base64
import os
import re
from RL import rl_com
from serial import Serial
import time


app = Flask(__name__)

@app.route("/")
def hello_world():
    print('totalCount')
    data = request.form.keys()
    print(data)
    return "<p>Hello, World!</p>"
    
@app.get('/gep')
def login_get():
    print('get')
    return "<p>show_the_login_form</p>"

@app.post('/up')
def login_post():
    print('post')
    data = request.form.keys()
    print(data)
    return "<p>do_the_login</p>"
    
@app.post('/sendToLora')
def sendToLora():
    print(f'\n{my_time()} sendToLora')
    di = request.form
    data = request.form.keys()
    #print(data)
    # r1 = procName()
    # print(r1)
    # print(type(di), type(data))
    # print(di.items())
    # di['procName'] = "sss"
    for i, k in enumerate(di):
        #print(i,k)
        x = di.get(k)
        # x_r = getattr(x, "xx")
        # x_res = x_r()
        print("enumloop: ", k,x)
        ret = "no_ret"
        if k == "SendDataToLoraDev":
            ret = send_data_to_lora_dev(x)
        elif k == "JoinLoraDev":
            ret = join_lora_dev(x)
        elif k == "ConfigLoraDev":
            ret = config_lora_dev(x)
        print(f'{k} result:{ret}')
        flag = "NA"
        if ret == 0:
            flag = "OK"
        else:
            flag = "FAIL"
        ret_file = f'c:/LoraDirs/ChirpStackLogs/{flag}'
        try:
            fp = open(ret_file, "w+")
            fp.close()
        except:
            print(f'Fail to create {ret_file}')
    return "<p>do_the_login</p>"
    
    
def send_data_to_lora_dev(data="aabbccdd"):
    print(f'\n{my_time()} send_data_to_lora_dev {data}')
    try:
        with rl_com.open_com("COM3", 115200) as ser:
            ret = rl_com.send(ser, f"at+send=lora:1:{data}\r\n", "recv", 14)
            print(f'send_data buffer:<{rl_com.buffer}>')
            rl_com.close_com(ser)
    except Exception as exp:
        print(f'Open com fail: {exp}')
        ret = "-1"
   
    return ret
    
    
def join_lora_dev(x):
    print(f'\n{my_time()} join_lora_dev {x}')
    try:
        with rl_com.open_com("COM3", 115200) as ser:
            ret = rl_com.send(ser, "at+join\r\n", "OK", 60)
            print(f'join_lora buffer:<{rl_com.buffer}>')
            rl_com.close_com(ser)
    except Exception as exp:
        print(f'Open com fail: {exp}')
        ret = "-1"
    return ret
    
def get_config_lora_dev(x):
    print(f'\n{my_time()} get_config_lora_dev {x}')
    try:
        with rl_com.open_com("COM3", 115200) as ser:
            ret = rl_com.send(ser, "at+get_config=lora:status\r\n", "End=", 12)
            print(f'get_config_lora_dev buffer:<{rl_com.buffer}>')
            rl_com.close_com(ser)
            m = re.search("Region:\s+([\d\w\-]+)",rl_com.buffer)
            if m is not None:
                return(m.group(1))
    except Exception as exp:
        print(f'Open com fail: {exp}')
        ret = "-1"
    return ret    

def config_lora_dev(x):
    print(f'\n{my_time()} config_lora_dev {x}')
    try:
        with rl_com.open_com("COM3", 115200) as ser:
            ret = rl_com.send(ser, "at+set_config=lora:join_mode:0\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, "at+set_config=lora:class:0\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, f"at+set_config=lora:region:{x}\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, "at+set_config=lora:confirm:1\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, "at+set_config=lora:dev_eui:60C5A8FFFE7841A6\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, "at+set_config=lora:app_eui:60C5A8FFF8680833\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, "at+set_config=lora:app_key:60C5A8FFF868083360C5A8FFF8680833\r\n", "OK", 8)
            print(rl_com.buffer)
            ret = rl_com.send(ser, "at+set_config=lora:work_mode:0\r\n", "OK", 8)
            print(rl_com.buffer)
            rl_com.close_com(ser)
    except Exception as exp:
        print(f'Open com fail: {exp}')
        ret = "-1"
    return ret

@app.route('/LoraDirs/flaskServer/SfEndPoint.py', methods=['POST'])
def login_flaskt():
    print('\nlogin_flaskt')
    try:
        data = request.json['data']
    except:
        data = "qrvM3Q=="
    
    data_s = base64_to_string(data)
    
    try:
        rxInfo = request.json['rxInfo']
        #print(rxInfo)
        rxInfoDict = rxInfo[0]
        gatewayID = rxInfoDict['gatewayID']
    except:
        gatewayID = 'GAb1//64Jyw='
    
    gatewayID_s = base64_to_string(gatewayID)
    print(f'data:<{data}>, data_s:<{data_s}>')
    #print(data_s)
    #print(rxInfo)
    print(f'gatewayID:<{gatewayID}>, gatewayID_s:<{gatewayID_s}>')
    #return "<p>do_the_loginflask</p>"
    
    if os.path.exists("c:/LoraDirs") is False:
        os.mkdir("c:/LoraDirs")
    if os.path.exists("c:/LoraDirs/ChirpStackLogs") is False:
        os.mkdir("c:/LoraDirs/ChirpStackLogs")
    
    flag_file = f'c:/LoraDirs/ChirpStackLogs/{gatewayID_s}.{data_s}.txt'
    if os.path.exists(flag_file):
        try:
            os.remove(flag_file)
            print(f'{flag_file} was exists')
        except Exception as exp:
            print(f'Fail to delete {flag_file}, exceptoin:{exp}')
    
    try:
        fp = open(flag_file, "w+")
        #fp.write(gatewayID_s)
        fp.close()
    except Exception as exp:
        print(f'Fail to create {flag_file}, exceptoin:{exp}')
        
    return ""
    
def base64_to_string(data64):
    len_data64 = len(data64)
    #print(f'base64_to_string:{data64}, len:{len_data64}')
    data = base64.b64decode(data64)
    if len_data64 == 8:
        y = struct.unpack('>I', data)[0]    
    else:
        y = struct.unpack('>Q', data)[0]    
    # i = y[0]
    # a = f'{i:X}'
    # data_s = a[::-1]
    data_s = f'{y:X}'
    return(data_s)
    
def my_time():
    return time.strftime("%d/%m/%Y %H:%M:%S")
    
if __name__ ==  '__main__':
    ## 172.18.93.32   127.0.0.1
    app.run(host = '172.18.94.79', debug=False, port=5000) 
else:
    print(__name__)


try:
    with rl_com.open_com("COM3", 115200) as ser:
        ret = rl_com.send(ser, "at+get_config=lora:status\r\n", "End=", 12)
        print(f'get_config_lora_dev buffer:<{rl_com.buffer}>')
        rl_com.close_com(ser)
except Exception as exp:
    print(f'Open com fail: {exp}')
    ret = "-1"
    
