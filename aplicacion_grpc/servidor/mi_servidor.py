import grpc
from concurrent.futures import ThreadPoolExecutor
from proto.mi_servicio_pb2 import SaludoRequest, SaludoResponse
from proto.mi_servicio_pb2_grpc import MiServicioServicer, add_MiServicioServicer_to_server


class MiServicio(MiServicioServicer):
    def Saludar(self, request, context):
        response = SaludoResponse()
        response.saludo = "¡Hola, " + request.nombre + "! Este es un saludo desde el servidor gRPC."
        return response

def serve():
    server = grpc.server(ThreadPoolExecutor(max_workers=10))
    add_MiServicioServicer_to_server(MiServicio(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    print("Servidor gRPC en ejecución en el puerto 50051...")
    server.wait_for_termination()

if __name__ == '__main__':
    serve()
