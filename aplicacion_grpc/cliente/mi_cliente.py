import grpc
from proto.mi_servicio_pb2 import SaludoRequest, SaludoResponse
from proto.mi_servicio_pb2_grpc import MiServicioStub

def run():
    channel = grpc.insecure_channel('localhost:50051')
    stub = MiServicioStub(channel)
    request = SaludoRequest(nombre="Tu Nombre")
    response = stub.Saludar(request)
    print("Respuesta del servidor: " + response.saludo)

if __name__ == '__main__':
    run()
