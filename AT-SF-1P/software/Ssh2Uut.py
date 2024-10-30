import paramiko, time
import re
import sys


def open_client(srvr_ip):
    username = 'su'
    password = '1234'
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(srvr_ip, username=username, password=password, port=22, look_for_keys=False, allow_agent=False)
    new_connection = client.invoke_shell()
    return client
    
    
def close_client(client):
    client.close()
    
def ssh_login(srvr_ip):
    client = open_client(srvr_ip)
    print(f'ssh_login srvr_ip:{srvr_ip}')
    ret1 = True
    cmd = f'\n\r'
    stdin, stdout, stderr = client.exec_command(cmd)
    ret1 = stdout.readlines()
    ret2 = stdout.read()
    print(f'ret1:{ret1} ret2:{ret2}')
    close_client(client)
    
    return True
    
if __name__ == '__main__':
    print(f'main:{sys.argv}')
    func     = sys.argv[1]
    srvr_ip  = sys.argv[2]
    
    result = eval(func + "(srvr_ip)")
    print(f'result:{result}')