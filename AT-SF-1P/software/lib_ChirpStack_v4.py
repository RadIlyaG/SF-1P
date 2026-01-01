import time
import sys
from datetime import datetime
import grpc
from chirpstack_api import api
from google.protobuf.timestamp_pb2 import Timestamp

class ChirpStack_v4:
    def __init__(self):
        SERVER = "172.18.94.105:8070"
        API_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjaGlycHN0YWNrIiwiaXNzIjoiY2hpcnBzdGFjayIsInN1YiI6IjgyN2E3OGJkLTQzYzktNDViMy1iZWViLWE2NGJjMjIxODY2OSIsInR5cCI6ImtleSJ9.Omu56UMmho1IbHutE3vNVmLHiiAqgMKc3HzX-HE5NCY"
        self.TENANT_ID = "320573d9-9d7e-4a1a-b20a-5c71105ba9ca"  # required when creating gateways
        self.auth_md = [("authorization", f"Bearer {API_TOKEN}")]
        self.channel = grpc.insecure_channel(SERVER)

    def gw_list(self):
        client = api.GatewayServiceStub(self.channel)
        request = api.ListGatewaysRequest(
            limit=10,
            offset=0,
            tenant_id=self.TENANT_ID
        )

        try:
            response = client.List(request, metadata=self.auth_md)
            print("Gateways found:")
            gws_list = []
            for gateway in response.result:
                print(f"- Name: {gateway.name}, ID: {gateway.gateway_id}, Organization: {gateway.tenant_id}")
                # You can access other fields like location, description, etc.
                gws_list += [gateway.gateway_id]
            return [0, gws_list]
        except grpc.RpcError as e:
            err_txt = (f"Error listing gateways: {e.details()}")
            return [-1, err_txt]

    def gw_create(self, gw_id):
        client = api.GatewayServiceStub(self.channel)
        # --- Build the Gateway and Create request ---
        gw = api.Gateway(
            gateway_id=gw_id,
            tenant_id=self.TENANT_ID,
            name=gw_id,
            description="Gateway for testing",
            # Optional: set location if you want
            # location=common.Location(latitude=31.78, longitude=35.22, altitude=800),
            # tags={"env": "lab", "owner": "Ilya"},
        )
        print(f'gw_create gw_id:<{gw_id}> len_gw_id:<{len(gw_id)}>')
        create_req = api.CreateGatewayRequest(gateway=gw)

        err_txt = ''
        try:
            client.Create(create_req, metadata=self.auth_md)  # returns google.protobuf.Empty
            print(f"Gateway {gw_id} created")  # '{GW_NAME}'
            return [0, err_txt]
        except grpc.RpcError as e:
            err_txt = (f"Create  {gw_id} failed: {e.code().name} - {e.details()}")
            print(err_txt)
            # raise
            return [-1, err_txt]

    def gw_last_seen(self, gw_id):
        try:
            client = api.GatewayServiceStub(self.channel)
            resp = client.Get(api.GetGatewayRequest(gateway_id=gw_id), metadata=self.auth_md)
            ts = resp.last_seen_at  # google.protobuf.timestamp_pb2.Timestamp or None
            if ts is None or ts.ByteSize() == 0:
                print(f"{gw_id} wasn't seen never")
                return [1, 'Was seen never']
            dt = ts.ToDatetime()
            dt_local = dt.astimezone()
            dt_local_frm = dt_local.strftime('%Y-%m-%d %H:%M:%S')
            # print("last_seen_at (raw Timestamp):", dt_local_frm)
            print(f'{gw_id} was seen at {dt_local_frm}')
            return [0, f'Was seen at {dt_local_frm}']
        except grpc.RpcError as e:
            err_txt = (f"Check last seen failed: {e.code().name} - {e.details()}")
            print(err_txt)
            return [-1, err_txt]

    def gw_delete(self, gw_id): # , GW_NAME
        client = api.GatewayServiceStub(self.channel)
        err_txt = ''
        try:
            client.Delete(api.DeleteGatewayRequest(gateway_id=gw_id), metadata=self.auth_md)
            print(f"Gateway {gw_id} deleted")  # '{GW_NAME}'
            return [0, err_txt]
        except grpc.RpcError as e:
            # If it was already deleted, you'll see NOT_FOUND here
            err_txt = (f"Delete {gw_id} failed: {e.code().name}: {e.details()}")
            return [-1, err_txt]
            
if __name__ == '__main__':
    print(f'sys.argv:{sys.argv}')
    func =  sys.argv[1]
    par =  sys.argv[2]
    import lib_ChirpStack_v4 as cs4
    cs = cs4.ChirpStack_v4()
    #func = cs.func
    #ret, resTxt = cs.gw_last_seen('0016c001f1105552')
    #ret, resTxt =    cs.gw_create('0016c001f1105555')
    result = eval(func + "(par)")
    
