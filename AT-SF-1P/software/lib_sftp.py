import sys
import time
from RL import Lib_RadApps

def FtpDeleteFile(*files):
    for fil in files:
        print(f'fil<{fil}>')
        if sftp.FileExists(fil.lower()) == 1:
            fil = fil.lower()
            sftp.DeleteFile(fil)
        
def FtpFileExist(fil):
    fil = fil.lower()
    return sftp.FileExists(fil)
    
def FtpUploadFile(fil):
    ret = sftp.UploadFile(fil)
    if 'A connection attempt failed' in str(ret):
        time.sleep(5)
        ret = sftp.UploadFile(fil)
    return ret
    
    
def FtpGetFile(remFil, locFil):
    ret = sftp.GetFile(remFil, locFil)
    if 'A connection attempt failed' in str(ret):
        time.sleep(5)
        ret = sftp.GetFile(remFil, locFil)
    return ret
    
if __name__ == '__main__':
    print(sys.argv)
    func =  sys.argv[1]
    fil =  sys.argv[2]
    
    result = 'ok'
    try:
        sftp = Lib_RadApps.Sftp('ftp.rad.co.il', 'ate', 'ate2009')
    except Exception as exp:
        time.sleep(10)
        result = 'ok'
        try:
            sftp = Lib_RadApps.Sftp('ftp.rad.co.il', 'ate', 'ate2009')
        except Exception as exp:
            result = exp
        
    if result == 'ok':
        if func == 'FtpDeleteFile':
            print(f'list_files:{sftp.ListOfFiles()}')
        
        if func == 'FtpGetFile' or func == 'FtpDeleteFile':
            fil2 =  sys.argv[3]
            result = eval(func + "(fil, fil2)")
        else:
            result = eval(func + "(fil)")
        
        print(f'result: {result} , list_files:{sftp.ListOfFiles()}')
    else:
        print(f'bad result: {result}')
    
