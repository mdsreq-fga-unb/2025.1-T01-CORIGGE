



class WebsocketMessageCommand:
    READ_TO_IMAGES = "readToImages"
    IDENTIFY_CIRCLES = "identifyCircles"
    GET_CALIBRATION = "getCalibration"
    FIND_CIRCLES = "findCircles"
    PING = "ping"





class WebsocketMessageStatus:
    COMPLETED_TASK = "completedTask"
    ERROR = "error"
    PONG = "pong"
    PROGRESS = "progress"
    SENDING_CHUNK = "sendingChunk"
    FINAL_CHUNK = "finalChunk"
    INTERNAL_CLIENT_REPORT = "internalClientReport"

class BoxRectangleType:
    TYPE_B = "Tipo B"
    COLUMN_QUESTIONS = "Coluna de Questões (A e C PAS ou Enem)"
    MATRICULA = "Matricula"
    OUTRO = "Outro"
    TEMP = "Temp"
    EXEMPLO_CIRCULO = "Exemplo de Circulo"