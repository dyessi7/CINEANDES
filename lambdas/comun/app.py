import json
import os


def handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({
            "funcion": os.environ.get("NOMBRE_FUNCION", "desconocida"),
            "estado": "ok",
        }),
    }